//
//  AlarmManager.swift
//  Muhurta
//
//  Sacred Solar Alarm Engine dynamically synced to astronomical sunrise and Brahma Muhurta
//  with customizable lead time, authentic Vedic mantra soundtrack support, and weekday repeat rules.
//

import Foundation
@preconcurrency import UserNotifications
import CoreLocation
import Observation
import AlarmKit
import ActivityKit
import SwiftUI

public struct SacredAlarmMetadata: AlarmMetadata {
    public var targetName: String
    
    public init(targetName: String) {
        self.targetName = targetName
    }
}

public enum AlarmTarget: String, CaseIterable, Identifiable, Sendable {
    case brahmaStart = "Brahma Muhurta (Start)"
    case brahmaMiddle = "Brahma Muhurta (Midpoint)"
    case pratahSandhya = "Pratah Sandhya (Dawn Twilight)"
    case sunrise = "Surya Udaya (Exact Sunrise)"
    
    public var id: String { rawValue }
    
    public var subtitle: String {
        switch self {
        case .brahmaStart: return "96 min before sunrise • Peak spiritual stillness"
        case .brahmaMiddle: return "72 min before sunrise • Deep meditative balance"
        case .pratahSandhya: return "48 min before sunrise • Gayatri & Pranayama window"
        case .sunrise: return "Horizon crossing • Surya Namaskar & Solar light"
        }
    }
}

public struct MuhurtaWindowTimes: Sendable {
    public let start: Date
    public let end: Date
    public let triggerTime: Date
    
    public var durationMinutes: Int {
        max(1, Int(end.timeIntervalSince(start) / 60.0))
    }
}

@Observable
public final class AlarmManager: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    public static let shared = AlarmManager()
    
    public var scheduledAlarmKitId: UUID?
    public var testAlarmKitId: UUID?
    public var isAlarmRinging: Bool = false
    
    public func stopRingingAlarm() {
        isAlarmRinging = false
        SoundEngine.shared.stop()
    }
    
    public func snoozeRingingAlarm() {
        isAlarmRinging = false
        SoundEngine.shared.stop()
        scheduleTestAlarm(delaySeconds: Double(snoozeMinutes * 60))
    }
    
    public var isAlarmEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isAlarmEnabled, forKey: "isAlarmEnabled")
            if isAlarmEnabled {
                scheduleSolarAlarm()
            } else {
                cancelScheduledAlarm()
            }
        }
    }
    
    public var selectedTarget: AlarmTarget = .brahmaStart {
        didSet {
            UserDefaults.standard.set(selectedTarget.rawValue, forKey: "selectedAlarmTarget")
            if isAlarmEnabled { scheduleSolarAlarm() }
        }
    }
    
    public var leadTimeMinutes: Int = 0 {
        didSet {
            UserDefaults.standard.set(leadTimeMinutes, forKey: "leadTimeMinutes")
            if isAlarmEnabled { scheduleSolarAlarm() }
        }
    }
    
    // Repeat days: 1 = Sunday, 2 = Monday ... 7 = Saturday
    public var repeatDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7] {
        didSet {
            let array = Array(repeatDays)
            UserDefaults.standard.set(array, forKey: "alarmRepeatDays")
            if isAlarmEnabled { scheduleSolarAlarm() }
        }
    }
    
    public var selectedSoundtrack: SacredSoundtrack = .gayatriMantra {
        didSet {
            UserDefaults.standard.set(selectedSoundtrack.rawValue, forKey: "selectedAlarmSoundtrack")
        }
    }
    
    public var isProgressiveAwakeningEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isProgressiveAwakeningEnabled, forKey: "isProgressiveAwakeningEnabled")
        }
    }
    
    public var progressiveDurationMinutes: Int = 15 {
        didSet {
            UserDefaults.standard.set(progressiveDurationMinutes, forKey: "progressiveDurationMinutes")
        }
    }
    
    public var isSnoozeEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isSnoozeEnabled, forKey: "isSnoozeEnabled")
        }
    }
    
    public var snoozeMinutes: Int = 9 {
        didSet {
            UserDefaults.standard.set(snoozeMinutes, forKey: "snoozeMinutes")
        }
    }
    
    public var calculationMethod: MuhurtaCalculationMethod = .astronomical {
        didSet {
            UserDefaults.standard.set(calculationMethod.rawValue, forKey: "muhurtaCalculationMethod")
            if isAlarmEnabled { scheduleSolarAlarm() }
        }
    }
    
    public var nextAlarmDate: Date?
    public var currentWindowTimes: MuhurtaWindowTimes?
    
    public override init() {
        super.init()
        self.isAlarmEnabled = UserDefaults.standard.bool(forKey: "isAlarmEnabled")
        if let targetRaw = UserDefaults.standard.string(forKey: "selectedAlarmTarget"),
           let target = AlarmTarget(rawValue: targetRaw) {
            self.selectedTarget = target
        }
        self.leadTimeMinutes = UserDefaults.standard.integer(forKey: "leadTimeMinutes")
        
        if let daysArray = UserDefaults.standard.array(forKey: "alarmRepeatDays") as? [Int] {
            self.repeatDays = Set(daysArray)
        }
        
        if let soundRaw = UserDefaults.standard.string(forKey: "selectedAlarmSoundtrack"),
           let sound = SacredSoundtrack(rawValue: soundRaw) {
            self.selectedSoundtrack = sound
        }
        if UserDefaults.standard.object(forKey: "isProgressiveAwakeningEnabled") != nil {
            self.isProgressiveAwakeningEnabled = UserDefaults.standard.bool(forKey: "isProgressiveAwakeningEnabled")
        }
        let dur = UserDefaults.standard.integer(forKey: "progressiveDurationMinutes")
        if dur > 0 {
            self.progressiveDurationMinutes = dur
        }
        if UserDefaults.standard.object(forKey: "isSnoozeEnabled") != nil {
            self.isSnoozeEnabled = UserDefaults.standard.bool(forKey: "isSnoozeEnabled")
        }
        let snz = UserDefaults.standard.integer(forKey: "snoozeMinutes")
        if snz > 0 {
            self.snoozeMinutes = snz
        }
        if let methodRaw = UserDefaults.standard.string(forKey: "muhurtaCalculationMethod"),
           let method = MuhurtaCalculationMethod(rawValue: methodRaw) {
            self.calculationMethod = method
        }
        
        checkNotificationSettings()
        UNUserNotificationCenter.current().delegate = self
    }
    
    public var authorizationStatus: UNAuthorizationStatus = .notDetermined
    public var isTimeSensitiveEnabled: Bool = false
    public var isAlarmKitAuthorized: Bool = false
    
    public var isAlarmKitDenied: Bool {
        if #available(iOS 26.0, *) {
            return AlarmKit.AlarmManager.shared.authorizationState == .denied || authorizationStatus == .denied
        }
        return authorizationStatus == .denied
    }
    
    @MainActor
    public func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    @MainActor
    public func handleAlarmPermissionRequest() async {
        await requestPermissionAndEnable()
    }
    
    @MainActor
    @discardableResult
    public func requestPermissionAndEnable() async -> Bool {
        // If already denied, redirect to Settings
        if isAlarmKitDenied {
            openSettings()
            self.isAlarmEnabled = false
            return false
        }
        
        // 1. Request UNUserNotificationCenter authorization if not determined
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let notificationGranted: Bool
        
        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                let updated = await center.notificationSettings()
                self.authorizationStatus = updated.authorizationStatus
                self.isTimeSensitiveEnabled = (updated.timeSensitiveSetting == .enabled)
                notificationGranted = granted
            } catch {
                notificationGranted = false
            }
        case .authorized, .provisional, .ephemeral:
            self.authorizationStatus = settings.authorizationStatus
            self.isTimeSensitiveEnabled = (settings.timeSensitiveSetting == .enabled)
            notificationGranted = true
        case .denied:
            self.authorizationStatus = settings.authorizationStatus
            notificationGranted = false
        @unknown default:
            notificationGranted = false
        }
        
        // 2. Request native AlarmKit authorization on iOS 26+ if not determined
        var alarmKitGranted = true
        if #available(iOS 26.0, *) {
            let state = AlarmKit.AlarmManager.shared.authorizationState
            if state == .notDetermined {
                alarmKitGranted = await requestAlarmKitAuthorization()
            } else if state == .authorized {
                self.isAlarmKitAuthorized = true
                alarmKitGranted = true
            } else {
                self.isAlarmKitAuthorized = false
                alarmKitGranted = false
            }
        }
        
        checkNotificationSettings()
        
        if notificationGranted && alarmKitGranted {
            self.isAlarmEnabled = true
            return true
        } else {
            self.isAlarmEnabled = false
            if isAlarmKitDenied {
                openSettings()
            }
            return false
        }
    }
    
    @discardableResult
    public func requestAlarmKitAuthorization() async -> Bool {
        if #available(iOS 26.0, *) {
            do {
                let state = try await AlarmKit.AlarmManager.shared.requestAuthorization()
                print("AlarmKit authorization state: \(state)")
                let authorized = (state == .authorized)
                await MainActor.run {
                    self.isAlarmKitAuthorized = authorized
                }
                return authorized
            } catch {
                print("AlarmKit requestAuthorization error: \(error)")
                return false
            }
        }
        return false
    }
    
    public func requestNotificationPermission(completion: (@Sendable (Bool) -> Void)? = nil) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    self.authorizationStatus = settings.authorizationStatus
                    self.isTimeSensitiveEnabled = settings.timeSensitiveSetting == .enabled
                    completion?(granted)
                }
            }
        }
        
        // Also request native iOS AlarmKit authorization if not determined
        if #available(iOS 26.0, *) {
            if AlarmKit.AlarmManager.shared.authorizationState == .notDetermined {
                Task {
                    await self.requestAlarmKitAuthorization()
                }
            }
        }
    }
    
    public func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isTimeSensitiveEnabled = settings.timeSensitiveSetting == .enabled
            }
        }
        if #available(iOS 26.0, *) {
            DispatchQueue.main.async {
                self.isAlarmKitAuthorized = (AlarmKit.AlarmManager.shared.authorizationState == .authorized)
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Sync soundtrack and start high-res continuous playback
        await MainActor.run {
            SoundEngine.shared.currentSoundtrack = self.selectedSoundtrack
            SoundEngine.shared.start()
            self.isAlarmRinging = true
        }
        return [.banner, .sound, .badge, .list]
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Tapping or opening the notification activates the continuous mantra playback and ringing UI
        await MainActor.run {
            SoundEngine.shared.currentSoundtrack = self.selectedSoundtrack
            SoundEngine.shared.start()
            self.isAlarmRinging = true
        }
    }
    
    /// Schedules an immediate test alarm firing in a few seconds using AlarmKit system alarm and custom sound
    public func scheduleTestAlarm(delaySeconds: TimeInterval = 5, completion: (@Sendable (Bool) -> Void)? = nil) {
        let soundFilename = "\(selectedSoundtrack.resourceFilename).caf"
        let fireDate = Date().addingTimeInterval(delaySeconds)
        let testTitle = "ब्रह्म मुहूर्त • Brahma Muhurta (Awakening)"
        
        // 1. Native System-Level Alarm via Apple's AlarmKit with custom audio
        if #available(iOS 26.0, *) {
            Task {
                do {
                    if AlarmKit.AlarmManager.shared.authorizationState != .authorized {
                        let state = try await AlarmKit.AlarmManager.shared.requestAuthorization()
                        print("AlarmKit test authorization state: \(state)")
                    }
                    
                    let alertPresentation: AlarmPresentation.Alert
                    if #available(iOS 26.1, *) {
                        let snoozeButton: AlarmKit.AlarmButton? = self.isSnoozeEnabled ? AlarmButton(
                            text: LocalizedStringResource("Snooze (\(self.snoozeMinutes)m)"),
                            textColor: Color(red: 0.94, green: 0.76, blue: 0.42),
                            systemImageName: "moon.zzz.fill"
                        ) : nil
                        alertPresentation = AlarmPresentation.Alert(
                            title: LocalizedStringResource(stringLiteral: testTitle),
                            secondaryButton: snoozeButton,
                            secondaryButtonBehavior: self.isSnoozeEnabled ? .countdown : nil
                        )
                    } else {
                        alertPresentation = AlarmPresentation.Alert(
                            title: LocalizedStringResource(stringLiteral: testTitle)
                        )
                    }
                    let presentation = AlarmPresentation(alert: alertPresentation)
                    let attributes = AlarmAttributes(
                        presentation: presentation,
                        metadata: SacredAlarmMetadata(targetName: testTitle),
                        tintColor: Color(red: 0.94, green: 0.76, blue: 0.42)
                    )
                    let config = AlarmKit.AlarmManager.AlarmConfiguration.alarm(
                        schedule: .fixed(fireDate),
                        attributes: attributes,
                        sound: .named(soundFilename)
                    )
                    
                    if let oldId = self.testAlarmKitId {
                        try? AlarmKit.AlarmManager.shared.cancel(id: oldId)
                    }
                    let newId = UUID()
                    self.testAlarmKitId = newId
                    let scheduled = try await AlarmKit.AlarmManager.shared.schedule(id: newId, configuration: config)
                    print("Successfully scheduled native AlarmKit test alarm: \(scheduled)")
                } catch {
                    print("Failed to schedule AlarmKit test alarm: \(error)")
                }
            }
        }
        
        // 2. Trigger in-app awakening screen when timer completes
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            await MainActor.run {
                SoundEngine.shared.currentSoundtrack = self.selectedSoundtrack
                SoundEngine.shared.start()
                self.isAlarmRinging = true
            }
        }
        
        // 3. Standard Time-Sensitive notification as visual banner fallback
        let content = UNMutableNotificationContent()
        content.title = "ब्रह्म मुहूर्त • Brahma Muhurta"
        content.subtitle = "Sacred Solar Awakening"
        content.body = "Awakening with \(selectedSoundtrack.shortName). Rise into sacred prana and spiritual stillness."
        
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        content.sound = UNNotificationSound(named: UNNotificationSoundName(soundFilename))
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delaySeconds, repeats: false)
        let request = UNNotificationRequest(identifier: "muhurta_test_alarm_\(UUID().uuidString)", content: content, trigger: trigger)
        
        safelyScheduleNotification(request: request, completion: completion)
    }
    
    private func safelyScheduleNotification(request: UNNotificationRequest, completion: (@Sendable (Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted {
                        UNUserNotificationCenter.current().add(request) { error in
                            if let error = error {
                                print("Failed to schedule notification: \(error.localizedDescription)")
                                completion?(false)
                            } else {
                                completion?(true)
                            }
                        }
                    } else {
                        print("Notification authorization denied by user.")
                        completion?(false)
                    }
                }
            case .authorized, .provisional, .ephemeral:
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Failed to schedule notification: \(error.localizedDescription)")
                        completion?(false)
                    } else {
                        completion?(true)
                    }
                }
            case .denied:
                print("Notification permission is disabled in iOS Settings.")
                completion?(false)
            @unknown default:
                break
            }
        }
    }
    
    public var repeatSummary: String {
        if repeatDays.count == 7 {
            return "Every Day"
        } else if repeatDays == Set([2, 3, 4, 5, 6]) {
            return "Weekdays"
        } else if repeatDays == Set([1, 7]) {
            return "Weekends"
        } else if repeatDays.isEmpty {
            return "Never (Once)"
        } else {
            let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let sortedDays = repeatDays.sorted()
            return sortedDays.compactMap { day in
                (day >= 1 && day <= 7) ? names[day - 1] : nil
            }.joined(separator: ", ")
        }
    }
    
    public func toggleDay(_ day: Int) {
        if repeatDays.contains(day) {
            repeatDays.remove(day)
        } else {
            repeatDays.insert(day)
        }
    }
    
    public struct WeeklyDayAlarm: Identifiable, Sendable {
        public let id: Int // 1 = Sunday ... 7 = Saturday
        public let daySymbol: String
        public let dayShortName: String
        public let date: Date
        public let triggerTime: Date?
        public let isToday: Bool
        public let isRepeatActive: Bool
        
        public init(id: Int, daySymbol: String, dayShortName: String, date: Date, triggerTime: Date?, isToday: Bool, isRepeatActive: Bool) {
            self.id = id
            self.daySymbol = daySymbol
            self.dayShortName = dayShortName
            self.date = date
            self.triggerTime = triggerTime
            self.isToday = isToday
            self.isRepeatActive = isRepeatActive
        }
    }
    
    /// Calculates the full start, end, and trigger time for the chosen target on a specific night
    public func calculateWindowTimes(for date: Date, coordinate: CLLocationCoordinate2D) -> MuhurtaWindowTimes? {
        let calendar = Calendar.current
        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date),
              let solarTimes = SolarCalculator.calculateSolarTimes(for: date, coordinate: coordinate),
              let nextSolarTimes = SolarCalculator.calculateSolarTimes(for: nextDate, coordinate: coordinate) else { return nil }
        
        let nightDuration = nextSolarTimes.sunrise.timeIntervalSince(solarTimes.sunset)
        let nightMuhurta: TimeInterval
        switch calculationMethod {
        case .astronomical:
            nightMuhurta = nightDuration / 15.0
        case .fixedStandard:
            nightMuhurta = 48.0 * 60.0
        }
        
        var start: Date
        var end: Date
        
        switch selectedTarget {
        case .brahmaStart:
            start = nextSolarTimes.sunrise.addingTimeInterval(-2.0 * nightMuhurta)
            end = nextSolarTimes.sunrise.addingTimeInterval(-1.0 * nightMuhurta)
        case .brahmaMiddle:
            start = nextSolarTimes.sunrise.addingTimeInterval(-2.0 * nightMuhurta)
            end = nextSolarTimes.sunrise.addingTimeInterval(-1.0 * nightMuhurta)
        case .pratahSandhya:
            start = nextSolarTimes.sunrise.addingTimeInterval(-1.0 * nightMuhurta)
            end = nextSolarTimes.sunrise
        case .sunrise:
            start = nextSolarTimes.sunrise
            end = nextSolarTimes.sunrise.addingTimeInterval(nightMuhurta)
        }
        
        let triggerBase = (selectedTarget == .brahmaMiddle) ? start.addingTimeInterval(nightMuhurta * 0.5) : start
        let triggerTime = triggerBase.addingTimeInterval(TimeInterval(leadTimeMinutes * 60))
        
        return MuhurtaWindowTimes(start: start, end: end, triggerTime: triggerTime)
    }
    
    /// Computes weekly alarm schedule across 7 days
    public func weeklyAlarmSchedule(coordinate: CLLocationCoordinate2D) -> [WeeklyDayAlarm] {
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        let startOfWeek = calendar.date(byAdding: .day, value: -(currentWeekday - 1), to: now) ?? now
        
        return (1...7).map { day in
            let date = calendar.date(byAdding: .day, value: day - 1, to: startOfWeek) ?? now
            let previousDay = calendar.date(byAdding: .day, value: -1, to: date) ?? date
            let window = calculateWindowTimes(for: previousDay, coordinate: coordinate)
            return WeeklyDayAlarm(
                id: day,
                daySymbol: String(calendar.shortWeekdaySymbols[day - 1].prefix(1)),
                dayShortName: calendar.shortWeekdaySymbols[day - 1],
                date: date,
                triggerTime: window?.triggerTime,
                isToday: day == currentWeekday,
                isRepeatActive: repeatDays.contains(day)
            )
        }
    }
    
    /// Calculates the full start, end, and trigger time for the chosen target
    public func calculateWindowTimes(coordinate: CLLocationCoordinate2D) -> MuhurtaWindowTimes? {
        let calendar = Calendar.current
        let now = Date()
        
        // Check days from yesterday's night (which concludes at today's sunrise) up to 8 days ahead
        for dayOffset in -1..<8 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now),
                  let nextDate = calendar.date(byAdding: .day, value: dayOffset + 1, to: now) else { continue }
            
            guard let solarTimes = SolarCalculator.calculateSolarTimes(for: targetDate, coordinate: coordinate),
                  let nextSolarTimes = SolarCalculator.calculateSolarTimes(for: nextDate, coordinate: coordinate) else { continue }
            
            let nightDuration = nextSolarTimes.sunrise.timeIntervalSince(solarTimes.sunset)
            let nightMuhurta: TimeInterval
            switch calculationMethod {
            case .astronomical:
                nightMuhurta = nightDuration / 15.0
            case .fixedStandard:
                nightMuhurta = 48.0 * 60.0
            }
            
            var start: Date
            var end: Date
            
            switch selectedTarget {
            case .brahmaStart:
                start = nextSolarTimes.sunrise.addingTimeInterval(-2.0 * nightMuhurta)
                end = nextSolarTimes.sunrise.addingTimeInterval(-1.0 * nightMuhurta)
            case .brahmaMiddle:
                start = nextSolarTimes.sunrise.addingTimeInterval(-2.0 * nightMuhurta)
                end = nextSolarTimes.sunrise.addingTimeInterval(-1.0 * nightMuhurta)
            case .pratahSandhya:
                start = nextSolarTimes.sunrise.addingTimeInterval(-1.0 * nightMuhurta)
                end = nextSolarTimes.sunrise
            case .sunrise:
                start = nextSolarTimes.sunrise
                end = nextSolarTimes.sunrise.addingTimeInterval(nightMuhurta)
            }
            
            let triggerBase = (selectedTarget == .brahmaMiddle) ? start.addingTimeInterval(nightMuhurta * 0.5) : start
            let triggerTime = triggerBase.addingTimeInterval(TimeInterval(leadTimeMinutes * 60))
            
            // Check the weekday of the actual wake-up morning (triggerTime)
            let wakeWeekday = calendar.component(.weekday, from: triggerTime)
            if !repeatDays.isEmpty && !repeatDays.contains(wakeWeekday) {
                continue
            }
            
            if triggerTime > now {
                let window = MuhurtaWindowTimes(start: start, end: end, triggerTime: triggerTime)
                self.currentWindowTimes = window
                return window
            }
        }
        
        return nil
    }
    
    /// Returns unambiguous relative wake-up description e.g. "Next Dawn Awakening • in 4h 25m"
    public func formattedTargetDateDescription(for triggerTime: Date) -> String {
        let now = Date()
        let diff = max(0, triggerTime.timeIntervalSince(now))
        let hours = Int(diff / 3600)
        let mins = Int((diff.truncatingRemainder(dividingBy: 3600)) / 60)
        let timeRemaining = hours > 0 ? "\(hours)h \(mins)m" : "\(max(1, mins))m"
        return "Next Awakening • in \(timeRemaining)"
    }
    
    public func calculateNextAlarmTime(coordinate: CLLocationCoordinate2D) -> Date? {
        let window = calculateWindowTimes(coordinate: coordinate)
        return window?.triggerTime
    }
    
    public func scheduleSolarAlarm() {
        let coord = LocationService.shared.currentCoordinate
        guard let window = calculateWindowTimes(coordinate: coord) else { return }
        self.nextAlarmDate = window.triggerTime
        
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Sacred Awakening • \(selectedTarget.rawValue)"
        content.body = "The cosmos is still. Awakening with \(selectedSoundtrack.shortName)."
        
        // Time-Sensitive notification with bundled 29s high-res sacred audio chant
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        
        let soundFilename = "\(selectedSoundtrack.resourceFilename).caf"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(soundFilename))
        
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: window.triggerTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        
        let request = UNNotificationRequest(identifier: "muhurta_sacred_alarm", content: content, trigger: trigger)
        safelyScheduleNotification(request: request)
        
        // Native System-Level Alarm via Apple's AlarmKit
        if #available(iOS 26.0, *) {
            let targetTitle = selectedTarget.rawValue
            let triggerTime = window.triggerTime
            let soundFilename = "\(selectedSoundtrack.resourceFilename).caf"
            Task {
                do {
                    if AlarmKit.AlarmManager.shared.authorizationState != .authorized {
                        let state = try await AlarmKit.AlarmManager.shared.requestAuthorization()
                        print("AlarmKit solar authorization state: \(state)")
                    }
                    
                    let alertPresentation: AlarmPresentation.Alert
                    if #available(iOS 26.1, *) {
                        let snoozeButton: AlarmKit.AlarmButton? = self.isSnoozeEnabled ? AlarmButton(
                            text: LocalizedStringResource("Snooze (\(self.snoozeMinutes)m)"),
                            textColor: Color(red: 0.94, green: 0.76, blue: 0.42),
                            systemImageName: "moon.zzz.fill"
                        ) : nil
                        alertPresentation = AlarmPresentation.Alert(
                            title: LocalizedStringResource(stringLiteral: "Sacred Awakening • \(targetTitle)"),
                            secondaryButton: snoozeButton,
                            secondaryButtonBehavior: self.isSnoozeEnabled ? .countdown : nil
                        )
                    } else {
                        alertPresentation = AlarmPresentation.Alert(
                            title: LocalizedStringResource(stringLiteral: "Sacred Awakening • \(targetTitle)")
                        )
                    }
                    let presentation = AlarmPresentation(alert: alertPresentation)
                    let attributes = AlarmAttributes(
                        presentation: presentation,
                        metadata: SacredAlarmMetadata(targetName: targetTitle),
                        tintColor: Color(red: 0.94, green: 0.76, blue: 0.42)
                    )
                    let config = AlarmKit.AlarmManager.AlarmConfiguration.alarm(
                        schedule: .fixed(triggerTime),
                        attributes: attributes,
                        sound: .named(soundFilename)
                    )
                    
                    if let oldId = self.scheduledAlarmKitId {
                        try? AlarmKit.AlarmManager.shared.cancel(id: oldId)
                    }
                    let newId = UUID()
                    self.scheduledAlarmKitId = newId
                    let scheduled = try await AlarmKit.AlarmManager.shared.schedule(id: newId, configuration: config)
                    print("Successfully scheduled AlarmKit solar alarm: \(scheduled)")
                } catch {
                    print("Failed to schedule AlarmKit solar alarm: \(error)")
                }
            }
        }
    }
    
    public func cancelScheduledAlarm() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        if #available(iOS 26.0, *) {
            if let oldId = scheduledAlarmKitId {
                try? AlarmKit.AlarmManager.shared.cancel(id: oldId)
                scheduledAlarmKitId = nil
            }
            if let testId = testAlarmKitId {
                try? AlarmKit.AlarmManager.shared.cancel(id: testId)
                testAlarmKitId = nil
            }
        }
        self.nextAlarmDate = nil
        self.currentWindowTimes = nil
    }
}
