//
//  SadhanaSanctuaryView.swift
//  Muhurta
//
//  Reimagined, ultra-luxurious Daily Sādhana Sanctuary.
//  Harmoniously integrates Brahma Muhūrta Awakening with Ayurvedic Dinacharya
//  and Prānāyāma breathwork in a pristine, uncluttered Apple-grade aesthetic.
//

import SwiftUI
import CoreLocation

public struct SadhanaSanctuaryView: View {
    @State private var alarmManager = AlarmManager.shared
    @State private var locationService = LocationService.shared
    @State private var soundEngine = SoundEngine.shared
    
    @State private var selectedTab: SadhanaTab = .awaken
    @State private var showingBreathwork = false
    @State private var showingDetailForStep: DinacharyaStep? = nil
    @State private var isPlayingSample = false
    
    @AppStorage("sacredSankalpa") private var selectedSankalpa: String = "dhyana"
    
    // Dinacharya steps persistent state
    @State private var dinacharyaSteps: [DinacharyaStep] = {
        let defaults = UserDefaults.standard
        var routine = DinacharyaStep.authenticRoutine
        for i in 0..<routine.count {
            let key = "dinacharya_\(routine[i].id)_completed"
            routine[i].isCompleted = defaults.bool(forKey: key)
        }
        return routine
    }()
    
    public enum SadhanaTab: String, CaseIterable, Identifiable {
        case awaken = "Awaken"
        case dinacharya = "Dinacharya"
        
        public var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .awaken: return "sun.horizon.fill"
            case .dinacharya: return "sparkles"
            }
        }
    }
    
    public init() {}
    
    private var currentCoordinate: CLLocationCoordinate2D {
        locationService.currentCoordinate
    }
    
    private var currentChronometry: VedicChronometry {
        PanchangaEngine.calculateChronometry(for: Date(), coordinate: currentCoordinate)
    }
    
    private var windowTimes: MuhurtaWindowTimes? {
        alarmManager.calculateWindowTimes(coordinate: currentCoordinate)
    }
    
    private var formattedWakeTime: String {
        guard let time = windowTimes?.triggerTime else {
            return "04:33 AM"
        }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: time)
    }
    
    private var formattedWindowRange: String {
        guard let window = windowTimes else {
            return "4:33 AM – 5:21 AM"
        }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: window.start)) – \(f.string(from: window.end))"
    }
    
    private var weeklyAlarmSchedule: [AlarmManager.WeeklyDayAlarm] {
        alarmManager.weeklyAlarmSchedule(coordinate: currentCoordinate)
    }
    
    private func formattedShortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f.string(from: date)
    }
    
    private var completedRitualsCount: Int {
        dinacharyaSteps.filter { $0.isCompleted }.count
    }
    
    private var vitalityFraction: Double {
        dinacharyaSteps.isEmpty ? 0 : Double(completedRitualsCount) / Double(dinacharyaSteps.count)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.08)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Clean Editorial Header
                        editorialHeader
                            .padding(.top, 10)
                        
                        // Modern Capsule Segment Switcher
                        capsuleSegmentSwitcher
                        
                        // Main Tab Views
                        if selectedTab == .awaken {
                            awakenSanctuaryView
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        } else {
                            dinacharyaSanctuaryView
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 80) // Clear floating dock
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingBreathwork) {
                PranayamaPacerView()
            }
            .sheet(item: $showingDetailForStep) { step in
                RitualDetailSheet(step: step) { updatedStep in
                    toggleStep(updatedStep.id)
                }
            }
        }
    }
    
    // MARK: - Editorial Header
    
    private var editorialHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("दैनिक साधना")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.86, blue: 0.60), Color(red: 0.94, green: 0.60, blue: 0.28)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Brahma Muhūrta Awakening & Dinacharya")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
    }
    
    // MARK: - Segment Switcher
    
    private var capsuleSegmentSwitcher: some View {
        HStack(spacing: 4) {
            ForEach(SadhanaTab.allCases) { tab in
                let isSelected = selectedTab == tab
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .serif))
                    }
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.94, green: 0.42, blue: 0.20),
                                            Color(red: 0.85, green: 0.30, blue: 0.15)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color(red: 0.94, green: 0.42, blue: 0.20).opacity(0.35), radius: 6)
                        } else {
                            Color.clear
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Awaken Sanctuary View
    
    private var awakenSanctuaryView: some View {
        VStack(spacing: 18) {
            // Hero Solar Alarm Awakening Card
            heroAwakeningCard
            
            // Alarm Schedule & Sound Configuration Bento Card
            alarmSettingsBentoCard
            
            // Morning Brahma Muhurta Sankalpa
            brahmaMuhurtaSankalpaCard
        }
    }
    
    private var heroAwakeningCard: some View {
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        let saffron = Color(red: 0.94, green: 0.60, blue: 0.28)
        
        return VStack(spacing: 16) {
            // Header inside card
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(alarmManager.isAlarmEnabled ? Color(red: 0.4, green: 0.85, blue: 0.5) : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text(alarmManager.isAlarmEnabled ? "SOLAR AWAKENING ACTIVE" : "ALARM PAUSED")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(alarmManager.isAlarmEnabled ? gold : .white.opacity(0.4))
                }
                
                Spacer()
                
                // Master Toggle
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
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                ))
                .labelsHidden()
                .tint(Color(red: 0.94, green: 0.50, blue: 0.22))
            }
            
            // Large Awakening Time Display
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(formattedWakeTime)
                    .font(.system(size: 46, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                Text("Brahma Muhūrta")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(saffron)
                
                Spacer()
            }
            .padding(.top, 4)
            
            // Ambient Status Pill
            HStack(spacing: 8) {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(gold)
                    .font(.system(size: 12))
                
                Text("Window: \(formattedWindowRange) • Concludes at Sunrise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
            
            // Audio Indicator
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(saffron)
                Text("Awakens with \(alarmManager.selectedSoundtrack.shortName)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                
                Button {
                    toggleAudioSample()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isPlayingSample ? "stop.fill" : "play.fill")
                            .font(.system(size: 10))
                        Text(isPlayingSample ? "Stop" : "Preview")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(gold.opacity(0.12))
                    .cornerRadius(8)
                }
            }
            .padding(.top, 2)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.11, blue: 0.16),
                            Color(red: 0.07, green: 0.08, blue: 0.11)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            alarmManager.isAlarmEnabled ? Color(red: 0.94, green: 0.60, blue: 0.28).opacity(0.35) : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private var alarmSettingsBentoCard: some View {
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        
        return VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Awakening Schedule")
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("Dynamic Solar Times • \(alarmManager.repeatSummary)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(gold)
                }
                Spacer()
            }
            
            // Weekday Repeat & Dynamic Astronomical Wakeup Times
            HStack(spacing: 5) {
                ForEach(weeklyAlarmSchedule) { item in
                    let isSelected = alarmManager.repeatDays.contains(item.id)
                    
                    Button {
                        toggleRepeatDay(item.id)
                    } label: {
                        VStack(spacing: 4) {
                            Text(item.daySymbol)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(isSelected ? Color(red: 0.10, green: 0.08, blue: 0.04) : .white.opacity(0.85))
                            
                            if let trigger = item.triggerTime {
                                Text(formattedShortTime(trigger))
                                    .font(.system(size: 9.5, weight: isSelected ? .heavy : .medium, design: .rounded))
                                    .foregroundColor(isSelected ? Color(red: 0.15, green: 0.10, blue: 0.02) : gold.opacity(0.9))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelected ? gold : Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    item.isToday ? Color.white.opacity(0.9) : (isSelected ? Color.clear : Color.white.opacity(0.08)),
                                    lineWidth: item.isToday ? 1.5 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // Sound Selector Menu Row
            HStack {
                Text("Sacred Awakening Chant")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                
                Menu {
                    ForEach(SacredSoundtrack.allCases) { sound in
                        Button {
                            alarmManager.selectedSoundtrack = sound
                        } label: {
                            HStack {
                                Text(sound.shortName)
                                if alarmManager.selectedSoundtrack == sound {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(alarmManager.selectedSoundtrack.shortName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(gold)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(gold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            // Lead Time Offset Row
            HStack {
                Text("Astronomical Offset")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                
                Menu {
                    Button("Exact Brahma Muhurta (96m before sunrise)") { alarmManager.leadTimeMinutes = 0 }
                    Button("15 min Earlier") { alarmManager.leadTimeMinutes = -15 }
                    Button("30 min Earlier") { alarmManager.leadTimeMinutes = -30 }
                    Button("48 min (1 Muhurta before sunrise)") { alarmManager.leadTimeMinutes = 48 }
                } label: {
                    HStack(spacing: 4) {
                        Text(alarmManager.leadTimeMinutes == 0 ? "Exact Start" : "\(abs(alarmManager.leadTimeMinutes))m Offset")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(gold)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(gold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            // Smooth Volume Fade-in Toggle
            Toggle(isOn: Binding(
                get: { alarmManager.isProgressiveAwakeningEnabled },
                set: { alarmManager.isProgressiveAwakeningEnabled = $0 }
            )) {
                Text("Gentle Sunrise Volume Ramp (15m)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
            .tint(gold)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private var brahmaMuhurtaSankalpaCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(Color(red: 0.94, green: 0.60, blue: 0.28))
                Text("Brahma Muhūrta Saṅkalpa")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text("ब्रह्ममुहूर्ते बुध्येत धर्माथौ चानुचिन्तयेत्। कायक्लेशांश्च तन्मूलान् वेदतत्त्वार्थमेव च॥")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                .lineSpacing(4)
            
            Text("“Awake in Brahma Muhurta; contemplate on spiritual dharma, truth, and the divine nature of the Self before beginning worldly actions.” — Ashtanga Hridayam")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.94, green: 0.60, blue: 0.28).opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Dinacharya Sanctuary View
    
    private var dinacharyaSanctuaryView: some View {
        VStack(spacing: 18) {
            // Sattva Vitality Dial Hero Card
            sattvaVitalityHeroCard
            
            // Prānāyāma Quick Launcher
            pranayamaLauncherCard
            
            // Sacred Morning Steps List
            VStack(spacing: 10) {
                ForEach(dinacharyaSteps) { step in
                    dinacharyaStepRow(step: step)
                }
            }
        }
    }
    
    private var sattvaVitalityHeroCard: some View {
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        let percent = Int(vitalityFraction * 100)
        
        return HStack(spacing: 18) {
            // Radial Progress
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 8)
                    .frame(width: 72, height: 72)
                
                Circle()
                    .trim(from: 0, to: CGFloat(vitalityFraction))
                    .stroke(
                        LinearGradient(
                            colors: [Color(red: 0.40, green: 0.85, blue: 0.60), gold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                
                Text("\(percent)%")
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Sattva Vitality")
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                Text("\(completedRitualsCount) of \(dinacharyaSteps.count) sacred rituals complete")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(gold)
                
                Text("Harmonizes Tridoṣa (Vāta, Pitta, Kapha)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private var pranayamaLauncherCard: some View {
        Button {
            showingBreathwork = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.40, green: 0.85, blue: 0.60).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "lungs.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.40, green: 0.85, blue: 0.60))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sama Vṛtti Prānāyāma Pacer")
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    Text("Box & 4-7-8 rhythmic breath balance for prana flow")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.40, green: 0.85, blue: 0.60))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.07, green: 0.08, blue: 0.11))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.40, green: 0.85, blue: 0.60).opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func dinacharyaStepRow(step: DinacharyaStep) -> some View {
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        
        return HStack(spacing: 14) {
            // Checkbox Button
            Button {
                toggleStep(step.id)
            } label: {
                ZStack {
                    Circle()
                        .fill(step.isCompleted ? Color(red: 0.40, green: 0.85, blue: 0.60) : Color.white.opacity(0.06))
                        .frame(width: 32, height: 32)
                    
                    if step.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Text info (tappable to open detail sheet)
            Button {
                showingDetailForStep = step
            } label: {
                HStack(spacing: 10) {
                    Text(step.emoji)
                        .font(.system(size: 22))
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.titleSanskrit)
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(step.isCompleted ? .white.opacity(0.6) : .white)
                            .strikethrough(step.isCompleted, color: .white.opacity(0.4))
                        
                        HStack(spacing: 6) {
                            Text(step.subtitle)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(gold)
                            
                            Text("• \(step.durationMinutes) min")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(step.isCompleted ? Color(red: 0.40, green: 0.85, blue: 0.60).opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helpers
    
    private func toggleStep(_ id: String) {
        if let idx = dinacharyaSteps.firstIndex(where: { $0.id == id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                dinacharyaSteps[idx].isCompleted.toggle()
                UserDefaults.standard.set(dinacharyaSteps[idx].isCompleted, forKey: "dinacharya_\(id)_completed")
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    private func toggleRepeatDay(_ day: Int) {
        if alarmManager.repeatDays.contains(day) {
            alarmManager.repeatDays.remove(day)
        } else {
            alarmManager.repeatDays.insert(day)
        }
    }
    
    private func toggleAudioSample() {
        soundEngine.togglePlay(soundtrack: alarmManager.selectedSoundtrack)
        isPlayingSample = soundEngine.isPlaying
    }
}
