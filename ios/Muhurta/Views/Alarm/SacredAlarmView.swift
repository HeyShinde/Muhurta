//
//  SacredAlarmView.swift
//  Muhurta
//
//  Refined Sacred Solar Alarm with GPS Location verification,
//  Muhurta start & end times, customizable lead time offset,
//  Apple-style weekday repeat controls, and authentic Vedic mantras.
//

import SwiftUI
import CoreLocation

public struct SacredAlarmView: View {
    @State private var alarmManager = AlarmManager.shared
    @State private var soundEngine = SoundEngine.shared
    @State private var locationService = LocationService.shared
    @State private var isShowingChronometryGuide = false
    @State private var isTestAlertScheduled = false
    @State private var testCountdown = 5
    @State private var testTimer: Timer?
    @AppStorage("sacredSankalpa") private var selectedSankalpa: String = "dhyana"
    @Environment(\.scenePhase) private var scenePhase
    
    public init() {}
    
    private var currentChronometry: VedicChronometry {
        let target = windowTimes?.start ?? Date()
        let vDate = PanchangaEngine.vedicDate(for: target, coordinate: locationService.currentCoordinate)
        if let panchanga = PanchangaEngine.calculatePanchanga(for: vDate, coordinate: locationService.currentCoordinate) {
            return panchanga.chronometry
        }
        return VedicChronometry.sample
    }
    
    private var windowTimes: MuhurtaWindowTimes? {
        alarmManager.calculateWindowTimes(coordinate: locationService.currentCoordinate)
    }
    
    private var formattedTriggerTime: String {
        guard let time = windowTimes?.triggerTime else {
            return "04:48 AM"
        }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: time)
    }
    
    private var formattedWindowRange: String {
        guard let window = windowTimes else {
            return "4:48 AM – 5:36 AM"
        }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: window.start)) – \(f.string(from: window.end))"
    }
    
    private func formattedWindowRangeWithDate(for window: MuhurtaWindowTimes) -> String {
        let dateF = DateFormatter()
        dateF.dateFormat = "EEE, d MMM"
        return "\(formattedWindowRange) (\(dateF.string(from: window.start)))"
    }
    
    private var leadTimeLabel: String {
        if alarmManager.leadTimeMinutes == 0 {
            return "Exact Target"
        } else if alarmManager.leadTimeMinutes < 0 {
            return "\(abs(alarmManager.leadTimeMinutes))m Earlier"
        } else {
            return "\(alarmManager.leadTimeMinutes)m Later"
        }
    }
    
    public var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.06, blue: 0.08)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 22) {
                    // Header
                    headerBar
                        .padding(.top, 16)
                    
                    // Vedic Cosmic Chronometry Badge & Guide Trigger
                    vedicChronometryBadge
                    
                    // Location Banner in Alarm Section
                    locationInformationCard
                    
                    // Main Alarm Hero Card (Trigger Time + Muhurta Start & End Times)
                    alarmHeroCard
                    
                    // Sound & Notification Verification Test Card
                    testAlarmCard
                    
                    // Repeat Weekday Controls (Apple Clock Style)
                    repeatDaysCard
                    
                    // Lead Time Selector
                    leadTimeCard
                    
                    // Solar Wake Target Picker
                    targetPickerCard
                    
                    // Calculation Methodology (Astronomical vs Classic 48m)
                    calculationMethodologyCard
                    
                    // Vedic Soundscape Picker
                    soundtrackPickerCard
                    
                    // Progressive Awakening Option
                    progressiveAwakeningCard
                    
                    // Sacred Snooze Configuration
                    snoozeCard
                    
                    // Brahma Muhurta Sankalpa (Morning Sacred Intention)
                    brahmaSankalpaCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
        }
        .onAppear {
            alarmManager.checkNotificationSettings()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                alarmManager.checkNotificationSettings()
            }
        }
    }
    
    // MARK: - Vedic Cosmic Chronometry Badge
    
    private var vedicChronometryBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("KALI YUGA \(currentChronometry.kaliYugaYear) • \(currentChronometry.samvatsaraName.uppercased())")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                
                Text("\(currentChronometry.ayana) • \(currentChronometry.ritu) • \(currentChronometry.masa)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.85))
            }
        }
        .padding(10)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(red: 0.94, green: 0.76, blue: 0.42).opacity(0.25), lineWidth: 1)
        )
    }
    
    // MARK: - Header
    
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("AWAKENING")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(2.0)
                    .foregroundColor(.secondary)
                
                Text("Solar Alarm")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Location Information Card
    
    private var locationInformationCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.40, green: 0.80, blue: 0.55).opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.40, green: 0.80, blue: 0.55))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(locationService.cityName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("GPS Synced")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 0.40, green: 0.80, blue: 0.55).opacity(0.18))
                        .foregroundColor(Color(red: 0.40, green: 0.80, blue: 0.55))
                        .clipShape(Capsule())
                }
                
                let lat = locationService.currentCoordinate.latitude
                let lon = locationService.currentCoordinate.longitude
                Text(String(format: "%.4f° N, %.4f° E • Astronomical solar horizon", lat, lon))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color(red: 0.09, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - Alarm Hero Card
    
    private var alarmHeroCard: some View {
        let ochre = Color(red: 0.92, green: 0.70, blue: 0.38)
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("NEXT SOLAR WAKE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(ochre)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { alarmManager.isAlarmEnabled },
                    set: { newValue in
                        if newValue {
                            Task {
                                await alarmManager.requestPermissionAndEnable()
                            }
                        } else {
                            withAnimation(.spring()) {
                                alarmManager.isAlarmEnabled = false
                            }
                        }
                    }
                ))
                    .labelsHidden()
                    .tint(ochre)
            }
            
            // Wake Time & Target Mode
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(formattedTriggerTime)
                        .font(.system(size: 44, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(alarmManager.selectedTarget.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(leadTimeLabel)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(ochre)
                    }
                }
                
                // Explicit Day and Relative Timing
                if let trigger = windowTimes?.triggerTime {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 12))
                            .foregroundColor(ochre)
                        
                        Text("\(alarmManager.formattedTargetDateDescription(for: trigger)) • \(currentChronometry.tithiSanskrit)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.95))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.04))
                    .clipShape(Capsule())
                }
            }
            
            // Muhurta Window Details Box (Showing Start & End Time!)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Clock Window", systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formattedWindowRange)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Label("Vedic Cycle", systemImage: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("14th Muhurta • Concludes at Sunrise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ochre)
                }
                
                if let window = windowTimes {
                    HStack {
                        Text("Window Duration: \(window.durationMinutes) min")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(alarmManager.repeatSummary)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            HStack(spacing: 8) {
                Image(systemName: "bell.and.waves.left.and.right")
                    .font(.system(size: 12))
                    .foregroundColor(ochre)
                
                Text("Awakens with \(alarmManager.selectedSoundtrack.shortName)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color(red: 0.09, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(alarmManager.isAlarmEnabled ? ochre.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Alarm & Sound Verification Test Card
    
    private var testAlarmCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sound & Alarm Verification")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Test audio output volume or schedule a 5-second lock screen alert")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if soundEngine.isPlaying {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 0.92, green: 0.70, blue: 0.38))
                            .frame(width: 6, height: 6)
                        Text("PLAYING")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.92, green: 0.70, blue: 0.38))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(red: 0.92, green: 0.70, blue: 0.38).opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            
            // Dual Test Buttons: Instant Audio Output Test + 5-Second System Alert Test
            HStack(spacing: 12) {
                // Button 1: Immediate Audio Playback
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    soundEngine.togglePlay(soundtrack: alarmManager.selectedSoundtrack)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: soundEngine.isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                        
                        Text(soundEngine.isPlaying ? "Stop Mantra" : "Play \(alarmManager.selectedSoundtrack.shortName)")
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundColor(soundEngine.isPlaying ? .black : Color(red: 0.92, green: 0.70, blue: 0.38))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(soundEngine.isPlaying ? Color(red: 0.92, green: 0.70, blue: 0.38) : Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                
                // Button 2: Schedule 5-second Test Notification
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    trigger5SecondTestAlert()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isTestAlertScheduled ? "bell.badge.fill" : "bell.fill")
                            .font(.system(size: 12, weight: .bold))
                        
                        Text(isTestAlertScheduled ? "Alert in \(testCountdown)s..." : "Test Alert (5s)")
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundColor(isTestAlertScheduled ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(isTestAlertScheduled ? Color(red: 0.40, green: 0.80, blue: 0.55) : Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isTestAlertScheduled)
            }
            
            // Live status banner when test notification is pending
            if isTestAlertScheduled {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.40, green: 0.80, blue: 0.55))
                    
                    Text("Lock your iPhone or swipe to Home. The alert banner and chime will fire in \(testCountdown)s.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(red: 0.40, green: 0.80, blue: 0.55))
                }
                .padding(10)
                .background(Color(red: 0.40, green: 0.80, blue: 0.55).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            
            // System Alarm Capability & Focus Override Notice
            if #available(iOS 26.0, *) {
                if alarmManager.isAlarmKitAuthorized {
                    // Verified Native Clock Alarm (bypasses Sleep Focus & Silent mode)
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.40, green: 0.82, blue: 0.60))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Native Clock Alarm Active")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Apple AlarmKit enabled. Automatically bypasses Sleep Focus, Do Not Disturb, and hardware silent switch.")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.40, green: 0.82, blue: 0.60).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    // AlarmKit not authorized yet
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                            
                            Text("Alarm Permission Required")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button {
                                Task {
                                    await alarmManager.handleAlarmPermissionRequest()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(alarmManager.isAlarmKitDenied ? "Open Settings" : "Grant Permission")
                                    if alarmManager.isAlarmKitDenied {
                                        Image(systemName: "arrow.up.forward.app")
                                            .font(.system(size: 9))
                                    }
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(red: 0.10, green: 0.08, blue: 0.04))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.94, green: 0.76, blue: 0.42))
                                .clipShape(Capsule())
                            }
                        }
                        
                        Text(alarmManager.isAlarmKitDenied
                             ? "Alarms are currently disabled in iOS Settings. Tap 'Open Settings' to allow Alarms so Muhurta can sound and alert you even when Sleep Focus or silent mode is on."
                             : "Allow Muhurta to schedule native alarms so it can sound and alert you even when Sleep Focus or silent mode is on.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.65))
                            .lineSpacing(2)
                    }
                    .padding(12)
                    .background(Color(red: 0.94, green: 0.76, blue: 0.42).opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            } else {
                // iOS < 26 Fallback Notice
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                        
                        Text("Sleep Focus & Mute Switch Support")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) ?? URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Text("iOS Settings")
                                Image(systemName: "arrow.up.forward.app")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                        }
                    }
                    
                    Text("In iOS Settings → Focus → Sleep, ensure Muhurta is allowed under Time-Sensitive Notifications.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.65))
                        .lineSpacing(2)
                }
                .padding(12)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            
            // Volume Level Slider
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "speaker.wave.1.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Text("Alarm Speaker Volume: \(Int(soundEngine.volume * 100))%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Slider(value: Binding(
                    get: { soundEngine.volume },
                    set: { soundEngine.volume = $0 }
                ), in: 0.1...1.0)
                .tint(Color(red: 0.92, green: 0.70, blue: 0.38))
            }
            .padding(.top, 2)
        }
        .padding(18)
        .background(Color(red: 0.09, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isTestAlertScheduled ? Color(red: 0.40, green: 0.80, blue: 0.55).opacity(0.4) : Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func trigger5SecondTestAlert() {
        Task {
            await alarmManager.requestAlarmKitAuthorization()
            await MainActor.run {
                self.isTestAlertScheduled = true
                self.testCountdown = 5
                self.testTimer?.invalidate()
                
                self.alarmManager.scheduleTestAlarm(delaySeconds: 5) { success in
                    if !success {
                        Task { @MainActor in
                            self.isTestAlertScheduled = false
                        }
                    }
                }
                
                self.testTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
                    if self.testCountdown > 1 {
                        self.testCountdown -= 1
                    } else {
                        self.testCountdown = 0
                        self.isTestAlertScheduled = false
                        t.invalidate()
                    }
                }
            }
        }
    }
    
    // MARK: - Repeat Days Card (Apple Clock Style)
    
    private var repeatDaysCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Repeat Schedule")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Select days to automatically calibrate and wake")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(alarmManager.repeatSummary)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.92, green: 0.70, blue: 0.38))
            }
            
            // 7 Weekday Circular Pills (Sun to Sat)
            HStack(spacing: 0) {
                let days = [
                    (id: 1, label: "S"),
                    (id: 2, label: "M"),
                    (id: 3, label: "T"),
                    (id: 4, label: "W"),
                    (id: 5, label: "T"),
                    (id: 6, label: "F"),
                    (id: 7, label: "S")
                ]
                
                ForEach(days, id: \.id) { day in
                    let isSelected = alarmManager.repeatDays.contains(day.id)
                    let ochre = Color(red: 0.92, green: 0.70, blue: 0.38)
                    
                    Button {
                        alarmManager.toggleDay(day.id)
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isSelected ? ochre : Color.white.opacity(0.04))
                                .frame(width: 36, height: 36)
                            
                            Text(day.label)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundColor(isSelected ? Color(red: 0.08, green: 0.06, blue: 0.02) : .white)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)
            
            // Quick Presets
            HStack(spacing: 8) {
                presetButton(title: "Every Day", days: [1, 2, 3, 4, 5, 6, 7])
                presetButton(title: "Weekdays", days: [2, 3, 4, 5, 6])
                presetButton(title: "Weekends", days: [1, 7])
                presetButton(title: "Once", days: [])
            }
        }
        .padding(18)
        .background(Color(red: 0.09, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func presetButton(title: String, days: Set<Int>) -> some View {
        let isSelected = alarmManager.repeatDays == days
        let ochre = Color(red: 0.92, green: 0.70, blue: 0.38)
        
        return Button {
            alarmManager.repeatDays = days
        } label: {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? ochre : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? ochre.opacity(0.12) : Color.white.opacity(0.03))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Lead Time Card
    
    private var leadTimeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Alarm Lead Time")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Adjust wake time relative to the calculated solar window")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(leadTimeLabel)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.92, green: 0.70, blue: 0.38))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 8) {
                leadTimePresetButton(minutes: -30, title: "-30m")
                leadTimePresetButton(minutes: -15, title: "-15m")
                leadTimePresetButton(minutes: 0, title: "Exact")
                leadTimePresetButton(minutes: 15, title: "+15m")
                leadTimePresetButton(minutes: 30, title: "+30m")
            }
        }
        .padding(18)
        .background(Color(red: 0.09, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func leadTimePresetButton(minutes: Int, title: String) -> some View {
        let isSelected = alarmManager.leadTimeMinutes == minutes
        let ochre = Color(red: 0.92, green: 0.70, blue: 0.38)
        
        return Button {
            alarmManager.leadTimeMinutes = minutes
        } label: {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? Color(red: 0.08, green: 0.06, blue: 0.02) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(isSelected ? ochre : Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Target Picker Card
    
    private var targetPickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Solar Target Window")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(AlarmTarget.allCases) { target in
                let isSelected = alarmManager.selectedTarget == target
                
                Button {
                    alarmManager.selectedTarget = target
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(isSelected ? Color(red: 0.92, green: 0.70, blue: 0.38) : Color.white.opacity(0.15))
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(target.rawValue)
                                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? .white : Color.white.opacity(0.8))
                            
                            Text(target.subtitle)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(isSelected ? Color.white.opacity(0.05) : Color.white.opacity(0.02))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(Color(red: 0.09, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - Calculation Methodology Card
    
    private var calculationMethodologyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("CALCULATION TRADITION", systemImage: "sparkles")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                
                Spacer()
                
                Text("Vedic Standard")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            ForEach(MuhurtaCalculationMethod.allCases) { method in
                let isSelected = alarmManager.calculationMethod == method
                let ochre = Color(red: 0.94, green: 0.76, blue: 0.42)
                
                Button {
                    alarmManager.calculationMethod = method
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(isSelected ? ochre : Color.white.opacity(0.15))
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(method.rawValue)
                                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.85))
                                
                                Spacer()
                                
                                Text(method == .astronomical ? "(Favored)" : "(Approximation)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(isSelected ? ochre : .secondary)
                            }
                            
                            Text(method == .astronomical
                                 ? "Divides actual astronomical night into 15 equal parts (~49.6m). True Shastric Drik Ganita."
                                 : "Fixed 48-min Muhurta (2 Ghaṭikās, exactly 96m before sunrise). Standard calendar rule.")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.secondary)
                                .lineSpacing(1.5)
                        }
                    }
                    .padding(12)
                    .background(isSelected ? Color.white.opacity(0.05) : Color.white.opacity(0.02))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? ochre.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(Color(red: 0.09, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - Soundtrack Picker Card
    
    private var soundtrackPickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Vedic Awakening Chants & Audio")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    soundEngine.togglePlay(soundtrack: alarmManager.selectedSoundtrack)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: soundEngine.isPlaying ? "stop.fill" : "play.fill")
                        Text(soundEngine.isPlaying ? "Stop" : "Preview")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 0.92, green: 0.70, blue: 0.38))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
            }
            
            ForEach(SacredSoundtrack.allCases) { soundtrack in
                let isSelected = alarmManager.selectedSoundtrack == soundtrack
                let isThisPlaying = soundEngine.isPlaying && soundEngine.currentSoundtrack == soundtrack
                
                HStack(spacing: 12) {
                    Button {
                        alarmManager.selectedSoundtrack = soundtrack
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: soundtrack.iconName)
                                .font(.system(size: 15))
                                .foregroundColor(isSelected ? Color(red: 0.92, green: 0.70, blue: 0.38) : .secondary)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.04))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(soundtrack.rawValue)
                                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.8))
                                
                                Text(soundtrack.description)
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(red: 0.92, green: 0.70, blue: 0.38))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Individual Preview Play/Stop button
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        if isThisPlaying {
                            soundEngine.stop()
                        } else {
                            soundEngine.togglePlay(soundtrack: soundtrack)
                        }
                    } label: {
                        Image(systemName: isThisPlaying ? "stop.circle.fill" : "play.circle")
                            .font(.system(size: 22))
                            .foregroundColor(isThisPlaying ? Color(red: 0.92, green: 0.70, blue: 0.38) : Color.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(isSelected ? Color.white.opacity(0.05) : Color.white.opacity(0.02))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(18)
        .background(Color(red: 0.09, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - Progressive Awakening Card
    
    private var progressiveAwakeningCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $alarmManager.isProgressiveAwakeningEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Progressive Volume Swell")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Starts as a quiet whisper 15 minutes before wake-up, gently rising to full volume.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .tint(Color(red: 0.92, green: 0.70, blue: 0.38))
        }
        .padding(18)
        .background(Color(red: 0.09, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - Sacred Snooze Configuration Card
    
    private var snoozeCard: some View {
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        
        return VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $alarmManager.isSnoozeEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sacred Snooze")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Allows pausing and repeating the awakening alert using native iOS controls.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .tint(gold)
            
            if alarmManager.isSnoozeEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SNOOZE DURATION")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundColor(gold)
                    
                    HStack(spacing: 8) {
                        snoozeDurationChip(minutes: 5, label: "5 min", sub: "Quick Rest")
                        snoozeDurationChip(minutes: 9, label: "9 min", sub: "Apple Classic")
                        snoozeDurationChip(minutes: 12, label: "12 min", sub: "1/4 Muhurta")
                    }
                }
            }
        }
        .padding(18)
        .background(Color(red: 0.09, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func snoozeDurationChip(minutes: Int, label: String, sub: String) -> some View {
        let isSelected = (alarmManager.snoozeMinutes == minutes)
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        
        return Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                alarmManager.snoozeMinutes = minutes
            }
        } label: {
            VStack(spacing: 3) {
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? Color(red: 0.10, green: 0.08, blue: 0.04) : .white)
                
                Text(sub)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(isSelected ? Color(red: 0.10, green: 0.08, blue: 0.04).opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? gold : Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Brahma Muhurta Sankalpa (Morning Sacred Intention)
    
    private var brahmaSankalpaCard: some View {
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        
        let sankalpas = [
            ("dhyana", "Dhyāna & Stillness", "चित्त शुद्धि", "Internal peace and silent meditation"),
            ("surya", "Sūrya Namaskār", "प्राण तेजस्", "Sun salutation, physical energy, and prāna"),
            ("svadhyaya", "Svādhyāya & Study", "ज्ञान दीक्षा", "Deep wisdom, scripture, and focused intellect"),
            ("creative", "Creative Flow", "सत्त्व स्फूर्ति", "High intuition, writing, and undisturbed focus")
        ]
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("BRAHMA SANKALPA", systemImage: "flame.fill")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(gold)
                
                Spacer()
                
                Text("Sacred Morning Focus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Text("In Vedic tradition, awakening in Brahma Muhurta begins with a Sankalpa (sacred resolve) before worldly interactions.")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
                .lineSpacing(2)
            
            // Vedic Cosmic Sankalpa Coordinates
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundColor(gold)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("KALI YUGA \(currentChronometry.kaliYugaYear) • \(currentChronometry.masaSanskrit) • \(currentChronometry.tithiSanskrit)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(gold)
                    
                    Text("Traditional astronomical coordinates for daily dawn alignment")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(10)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(gold.opacity(0.2), lineWidth: 1)
            )
            
            VStack(spacing: 8) {
                ForEach(sankalpas, id: \.0) { key, title, sanskrit, desc in
                    let isSelected = (selectedSankalpa == key)
                    
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedSankalpa = key
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(isSelected ? gold : Color.white.opacity(0.12))
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(title)
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(isSelected ? .white : Color.white.opacity(0.85))
                                    
                                    Text(sanskrit)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(gold)
                                }
                                
                                Text(desc)
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(gold)
                            }
                        }
                        .padding(12)
                        .background(isSelected ? gold.opacity(0.12) : Color.white.opacity(0.02))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSelected ? gold.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(Color(red: 0.09, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
