//
//  DinacharyaRitualView.swift
//  Muhurta
//
//  State-of-the-art Ayurvedic Morning Sadhana Sanctuary.
//  Multi-phase ritual tracker with Sattva vitality metrics, rich step guidance,
//  and integrated breathwork pacer.
//

import SwiftUI

public struct DinacharyaRitualView: View {
    @State private var steps: [DinacharyaStep] = {
        let defaults = UserDefaults.standard
        var routine = DinacharyaStep.authenticRoutine
        for i in 0..<routine.count {
            let key = "dinacharya_\(routine[i].id)_completed"
            routine[i].isCompleted = defaults.bool(forKey: key)
        }
        return routine
    }()
    
    @State private var selectedPhase: DinacharyaPhase? = nil
    @State private var selectedStepForDetail: DinacharyaStep? = nil
    @State private var showingBreathModal = false
    @State private var isShowingChronometryGuide = false
    @State private var locationService = LocationService.shared
    
    public init() {}
    
    private var currentChronometry: VedicChronometry {
        let vDate = PanchangaEngine.vedicDate(for: Date(), coordinate: locationService.currentCoordinate)
        if let panchanga = PanchangaEngine.calculatePanchanga(for: vDate, coordinate: locationService.currentCoordinate) {
            return panchanga.chronometry
        }
        return VedicChronometry.sample
    }
    
    private var completedCount: Int {
        steps.filter { $0.isCompleted }.count
    }
    
    private var completionFraction: Double {
        steps.isEmpty ? 0 : Double(completedCount) / Double(steps.count)
    }
    
    private var totalRemainingMinutes: Int {
        steps.filter { !$0.isCompleted }.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var filteredSteps: [DinacharyaStep] {
        if let phase = selectedPhase {
            return steps.filter { $0.phase == phase }
        }
        return steps
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Deep obsidian background
                Color(red: 0.05, green: 0.06, blue: 0.08)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 22) {
                        // Header
                        headerBar
                            .padding(.top, 16)
                        
                        // Ayurvedic Seasonal Chronometry (Rtucarya & Kala Ganana)
                        vedicSeasonalBadge
                        
                        // Hero Sattva Vitality Gauge Card
                        sattvaVitalityCard
                        
                        // Quick Breathwork Hero Launcher Card
                        breathworkLauncherBanner
                        
                        // Phase Selector Filter
                        phaseFilterTabs
                        
                        // Ritual Steps by Phase
                        VStack(spacing: 12) {
                            ForEach(filteredSteps) { step in
                                ritualStepCard(step: step)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Breathing room for floating bottom dock
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedStepForDetail) { step in
                RitualDetailSheet(step: step) { updatedStep in
                    toggleStep(updatedStep.id)
                }
            }
            .sheet(isPresented: $showingBreathModal) {
                PranayamaPacerView()
            }
        }
    }
    
    // MARK: - Ayurvedic Seasonal Chronometry Badge
    
    private var vedicSeasonalBadge: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.94, green: 0.76, blue: 0.42).opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("ṚTU-CARYĀ • \(currentChronometry.ritu.uppercased())")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                
                Text("Kali Yuga \(currentChronometry.kaliYugaYear) • \(currentChronometry.ayana) • \(currentChronometry.tithiSanskrit)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(currentChronometry.rituMeaning)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(red: 0.94, green: 0.76, blue: 0.42).opacity(0.25), lineWidth: 1)
        )
    }
    
    // MARK: - Header Bar
    
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("DINACHARYA • दिनचर्या")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(2.0)
                    .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                
                Text("Morning Sadhana")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Reset / All Done Menu
            Menu {
                Button("Mark All as Complete") {
                    setAll(completed: true)
                }
                Button("Reset for Tomorrow") {
                    setAll(completed: false)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundColor(Color.white.opacity(0.7))
                    .padding(8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Sattva Vitality Hero Card
    
    private var sattvaVitalityCard: some View {
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        let emerald = Color(red: 0.40, green: 0.82, blue: 0.60)
        
        return HStack(spacing: 18) {
            // Radial Progress Meter
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 8)
                    .frame(width: 76, height: 76)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(completionFraction))
                    .stroke(
                        LinearGradient(
                            colors: [gold, emerald],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 76, height: 76)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: completionFraction)
                
                VStack(spacing: 1) {
                    Text("\(Int(completionFraction * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Sattva")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(gold)
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text("\(completedCount) of \(steps.count) Cleansings")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                if totalRemainingMinutes > 0 {
                    Text("\(totalRemainingMinutes) min of mindful rituals remaining")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                } else {
                    Text("Complete! Cellular Agni and Prāna fully awakened")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(emerald)
                }
                
                // Biological Dosha Pill
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                    Text("Awakening Agni • Pacifying Night Ama")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(Color.white.opacity(0.75))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.05))
                .clipShape(Capsule())
            }
            
            Spacer()
        }
        .padding(18)
        .background(Color(red: 0.09, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(completionFraction == 1.0 ? emerald.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Breathwork Quick Launcher Banner
    
    private var breathworkLauncherBanner: some View {
        Button {
            showingBreathModal = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.35, green: 0.65, blue: 0.95).opacity(0.18))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "wind")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.50, green: 0.78, blue: 1.0))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Prāṇāyāma Breath Sanctuary")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Interactive")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(red: 0.35, green: 0.65, blue: 0.95).opacity(0.2))
                            .foregroundColor(Color(red: 0.50, green: 0.78, blue: 1.0))
                            .clipShape(Capsule())
                    }
                    
                    Text("Nadi Shodhana, Box Breathing & 4-7-8 harmonizing Nadis")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.35))
            }
            .padding(14)
            .background(Color(red: 0.08, green: 0.10, blue: 0.15))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(red: 0.35, green: 0.65, blue: 0.95).opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Phase Filter Tabs
    
    private var phaseFilterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill(title: "All Stages (\(steps.count))", isSelected: selectedPhase == nil) {
                    selectedPhase = nil
                }
                
                ForEach(DinacharyaPhase.allCases) { phase in
                    let count = steps.filter { $0.phase == phase }.count
                    filterPill(title: "\(phase.rawValue) (\(count))", isSelected: selectedPhase == phase) {
                        selectedPhase = phase
                    }
                }
            }
        }
    }
    
    private func filterPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        return Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .black : Color.white.opacity(0.75))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? gold : Color.white.opacity(0.05))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Individual Ritual Step Card
    
    private func ritualStepCard(step: DinacharyaStep) -> some View {
        let emerald = Color(red: 0.40, green: 0.82, blue: 0.60)
        
        return HStack(spacing: 14) {
            // Checkmark Button
            Button {
                toggleStep(step.id)
            } label: {
                ZStack {
                    Circle()
                        .stroke(step.isCompleted ? emerald : Color.white.opacity(0.20), lineWidth: 1.5)
                        .frame(width: 26, height: 26)
                    
                    if step.isCompleted {
                        Circle()
                            .fill(emerald)
                            .frame(width: 18, height: 18)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(.black)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Emoji / Icon
            Text(step.emoji)
                .font(.system(size: 22))
                .frame(width: 32)
            
            // Titles & Duration
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(step.titleSanskrit)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(step.isCompleted ? .secondary : .white)
                        .strikethrough(step.isCompleted, color: .secondary)
                }
                
                Text(step.subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.55))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Duration & Info Button
            Button {
                selectedStepForDetail = step
            } label: {
                HStack(spacing: 3) {
                    Text("\(step.durationMinutes)m")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                }
                .foregroundColor(Color.white.opacity(0.5))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.04))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(step.isCompleted ? emerald.opacity(0.25) : Color.white.opacity(0.04), lineWidth: 1)
        )
    }
    
    private func toggleStep(_ id: String) {
        if let idx = steps.firstIndex(where: { $0.id == id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                steps[idx].isCompleted.toggle()
            }
            UserDefaults.standard.set(steps[idx].isCompleted, forKey: "dinacharya_\(id)_completed")
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
    
    private func setAll(completed: Bool) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            for i in 0..<steps.count {
                steps[i].isCompleted = completed
                UserDefaults.standard.set(completed, forKey: "dinacharya_\(steps[i].id)_completed")
            }
        }
    }
}

// MARK: - Ritual Detail Sheet with Step Guidance and Timer

public struct RitualDetailSheet: View {
    public let step: DinacharyaStep
    public let onToggleComplete: (DinacharyaStep) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var timeRemaining: Int = 0
    @State private var isTimerActive: Bool = false
    @State private var timer: Timer?
    
    public init(step: DinacharyaStep, onToggleComplete: @escaping (DinacharyaStep) -> Void) {
        self.step = step
        self.onToggleComplete = onToggleComplete
    }
    
    public var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.07, blue: 0.10)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                    }
                    
                    // Header
                    HStack(spacing: 14) {
                        Text(step.emoji)
                            .font(.system(size: 38))
                            .frame(width: 54, height: 54)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(step.phase.rawValue)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                            
                            Text(step.titleSanskrit)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(step.titleEnglish)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Interactive Step Timer
                    VStack(spacing: 12) {
                        HStack {
                            Text("PRACTICE TIMER")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formattedTime(timeRemaining))
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                        }
                        
                        Button {
                            toggleTimer()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isTimerActive ? "pause.fill" : "play.fill")
                                Text(isTimerActive ? "Pause Timer" : (timeRemaining < step.durationMinutes * 60 ? "Resume Timer" : "Start \(step.durationMinutes) min Timer"))
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.94, green: 0.76, blue: 0.42))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Method & Instructions", systemImage: "list.bullet")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(step.instructions)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.85))
                            .lineSpacing(3)
                    }
                    
                    // Physiological & Spiritual Benefits
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Ayurvedic & Biological Benefits", systemImage: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.40, green: 0.82, blue: 0.60))
                        
                        Text(step.benefits)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    
                    // Required Materials
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Materials Needed", systemImage: "shippingbox.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(step.materials)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    // Mark Completed Button
                    Button {
                        onToggleComplete(step)
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                            Text(step.isCompleted ? "Completed Today" : "Mark as Completed")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(step.isCompleted ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(step.isCompleted ? Color(red: 0.40, green: 0.82, blue: 0.60) : Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.top, 10)
                }
                .padding(24)
            }
        }
        .onAppear {
            timeRemaining = step.durationMinutes * 60
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func toggleTimer() {
        if isTimerActive {
            timer?.invalidate()
            isTimerActive = false
        } else {
            isTimerActive = true
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    isTimerActive = false
                    t.invalidate()
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
        }
    }
    
    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
