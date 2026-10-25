//
//  SolarDashboardView.swift
//  Muhurta
//
//  A state-of-the-art Vedic Solar Ephemeris & Cosmic Chronobiology Sanctuary.
//  Featuring real-time Celestial Sun Arc, Atmospheric Prāna & Guna dynamics,
//  live Sacred Muhurta countdown, and Suryodayadi Ahoratra timeline.
//

import SwiftUI
import CoreLocation

public struct SolarDashboardView: View {
    @State private var locationService = LocationService.shared
    @State private var currentSnapshot: MuhurtaSnapshot?
    @State private var currentPanchanga: PanchangaSnapshot?
    @State private var timer: Timer?
    @State private var selectedDate = Date()
    @State private var isShowingDatePicker = false
    @State private var isShowingChronometryGuide = false
    @State private var isShowingLifeEvents = false
    @State private var isTimelineExpanded = false
    @Namespace private var dateStripNamespace
    
    public init() {}
    
    /// The authentic Vedic Calendar day (Sūryodayāt Sūryodaya)
    private var currentVedicToday: Date {
        PanchangaEngine.vedicDate(for: Date(), coordinate: locationService.currentCoordinate)
    }
    
    private var isSelectedDateToday: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: currentVedicToday)
    }
    
    private var calculationTargetDate: Date {
        if isSelectedDateToday {
            return Date()
        } else {
            let calendar = Calendar.current
            // Solar noon (12:00:00 PM) for selectedDate evaluates that date's daytime solar cycle cleanly
            return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        }
    }
    
    private var vedicPhaseSubtitle: String {
        guard let snapshot = currentSnapshot else {
            return "Astronomical Ephemeris & 30 Muhurtas"
        }
        if !isSelectedDateToday {
            let f = DateFormatter()
            f.dateFormat = "EEEE, d MMMM yyyy"
            return f.string(from: selectedDate)
        }
        let now = calculationTargetDate
        if now < snapshot.solarTimes.sunrise {
            return "Pre-Dawn (Rātri-Śeṣa) • Sūryodayāt Sūryodaya"
        } else if now < snapshot.solarTimes.sunset {
            return "Solar Daylight • Sūryodayādi"
        } else {
            return "Rātri Sandhyā • Sūryodayādi"
        }
    }
    
    public var body: some View {
        ZStack {
            // Serene matte obsidian canvas
            Color(red: 0.05, green: 0.06, blue: 0.08)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 22) {
                    // Refined Editorial Header with Location & 7-Day Vedic Date Strip
                    editorialHeader
                        .padding(.top, 16)
                    
                    if let snapshot = currentSnapshot {
                        if isSelectedDateToday {
                            // Atmospheric Prāna & Active Muhurta Hero Card (LIVE)
                            activeSacredHeroCard(snapshot: snapshot)
                            
                            // Celestial Solar Arc Visualizer (LIVE)
                            SolarArcVisualizer(snapshot: snapshot)
                        } else {
                            // Dedicated Date Schedule Hero Card (no live countdowns, pure scheduled timings!)
                            selectedDateScheduleHeroCard(snapshot: snapshot, panchanga: currentPanchanga)
                        }
                        
                        // Daily Windows of Action (Rahu Kalam, Yamaganda, Gulika, Abhijit)
                        if let panchanga = currentPanchanga {
                            dailyActionWindowsCard(panchanga: panchanga)
                            
                            // Panchanga Essentials (5 Limbs of Vedic Time)
                            panchangaEssentialsCard(panchanga: panchanga)
                        }
                        
                        // Solar Ephemeris Quartet (Sunrise, Noon, Sunset, Civil Dawn)
                        solarMetricsGrid(snapshot: snapshot)
                        
                        if isSelectedDateToday {
                            // Dosha Chronobiology Clock
                            DoshaClockView(
                                currentDosha: snapshot.currentDosha,
                                currentWindow: snapshot.currentDoshaWindow
                            )
                            
                            // Evening Sandhya Wind-Down Anchor
                            bedtimeRecommendationCard(snapshot: snapshot)
                        }
                        
                        // 30 Muhurta Ahoratra Ephemeris
                        muhurtaTimelineCard(snapshot: snapshot)
                    } else {
                        loadingPlaceholder
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120) // Ergonomic breathing room above floating dock
            }
        }
        .sheet(isPresented: $isShowingDatePicker) {
            datePickerSheet
        }
        .sheet(isPresented: $isShowingLifeEvents) {
            LifeEventsView()
        }
        .onAppear {
            locationService.requestPermission()
            selectedDate = currentVedicToday
            refreshCalculations()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if isSelectedDateToday {
                    refreshCalculations()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    // MARK: - Editorial Header & 7-Day Date Strip
    
    private var editorialHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Location & GPS status + Top Controls
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 0.40, green: 0.82, blue: 0.60))
                        .frame(width: 7, height: 7)
                    
                    Text(locationService.cityName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
                
                Spacer()
                
                if !isSelectedDateToday {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedDate = currentVedicToday
                        }
                        refreshCalculations()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Vedic Today")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(red: 0.94, green: 0.76, blue: 0.42).opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                
                Button {
                    isShowingDatePicker = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    isShowingLifeEvents = true
                } label: {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                        .frame(width: 30, height: 30)
                        .background(Color(red: 0.94, green: 0.76, blue: 0.42).opacity(0.12))
                        .clipShape(Circle())
                }
                
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    locationService.requestLocation()
                    refreshCalculations()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }
            
            // Screen Title with Authentic Vedic Day
            VStack(alignment: .leading, spacing: 3) {
                if let panchanga = currentPanchanga {
                    Text(panchanga.chronometry.tithiSanskrit)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Text(panchanga.vara.nameSanskrit)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                        
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(vedicPhaseSubtitle)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Vedic Solar Arc")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            // Authentic Vedic 7-Tithi Strip
            dateStripView
        }
    }
    
    private var dateStripView: some View {
        let calendar = Calendar.current
        let baseDate = currentVedicToday
        let days: [Date] = (-3...3).compactMap { offset in
            guard let raw = calendar.date(byAdding: .day, value: offset, to: baseDate) else { return nil }
            return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: raw)
        }
        let coord = locationService.currentCoordinate
        
        return HStack(spacing: 6) {
            ForEach(days, id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isToday = calendar.isDate(date, inSameDayAs: currentVedicToday)
                let mini = PanchangaEngine.tithiMiniSummary(for: date, coordinate: coord)
                let dayNum = dateDayNumber(date)
                
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedDate = date
                    }
                    refreshCalculations()
                } label: {
                    VStack(spacing: 4) {
                        // Devanagari Vāra (शनि, रवि, सोम, etc.)
                        Text(mini.varaDevanagari)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isSelected ? Color(red: 0.10, green: 0.08, blue: 0.04) : Color(red: 0.94, green: 0.76, blue: 0.42))
                        
                        // Authentic Devanagari Tithi (चतुर्दशी, पूर्णिमा, etc.)
                        Text(mini.tithiDevanagari)
                            .font(.system(size: 11, weight: isSelected ? .bold : .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundColor(isSelected ? Color(red: 0.10, green: 0.08, blue: 0.04) : .white)
                        
                        // Subtle bridge number (Roman calendar day) + Paksha Dot
                        HStack(spacing: 3) {
                            Text(dayNum)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(isSelected ? Color(red: 0.10, green: 0.08, blue: 0.04).opacity(0.8) : .secondary.opacity(0.6))
                            
                            Circle()
                                .fill(isToday ? (isSelected ? Color(red: 0.10, green: 0.08, blue: 0.04) : Color(red: 0.94, green: 0.76, blue: 0.42)) : Color.clear)
                                .frame(width: 3, height: 3)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.98, green: 0.84, blue: 0.52),
                                                Color(red: 0.92, green: 0.72, blue: 0.36)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .matchedGeometryEffect(id: "selectedDayPill", in: dateStripNamespace)
                                    .shadow(color: Color(red: 0.94, green: 0.76, blue: 0.42).opacity(0.35), radius: 8, x: 0, y: 3)
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.04))
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Daily Windows of Action Card (Rahu Kalam, Yamaganda, Gulika, Abhijit)
    
    private func dailyActionWindowsCard(panchanga: PanchangaSnapshot) -> some View {
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        let activeWindow = isSelectedDateToday ? panchanga.actionWindows.activeWindow(at: calculationTargetDate) : nil
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("DAILY ACTION WINDOWS", systemImage: "bolt.shield.fill")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(gold)
                
                Spacer()
                
                Text("Ashtabhaga Timings")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Dynamic Live Active Banner (Only displayed on today)
            if let active = activeWindow {
                HStack(spacing: 8) {
                    Image(systemName: active.type.isAuspicious ? "sparkles" : "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(active.type.accentColor)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("ACTIVE NOW: \(active.type.rawValue)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(active.type.isAuspicious ? "Favorable celestial alignment for high-impact actions." : "Inauspicious window; avoid commencing new contracts or travel.")
                            .font(.system(size: 10))
                            .foregroundColor(Color.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding(10)
                .background(active.type.accentColor.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(active.type.accentColor.opacity(0.4), lineWidth: 1)
                )
            }
            
            // 2x2 Action Windows Grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                actionWindowMiniCard(window: panchanga.actionWindows.abhijit, icon: "sun.max.fill")
                actionWindowMiniCard(window: panchanga.actionWindows.rahuKalam, icon: "exclamationmark.triangle.fill")
                actionWindowMiniCard(window: panchanga.actionWindows.yamaganda, icon: "hand.raised.fill")
                actionWindowMiniCard(window: panchanga.actionWindows.gulika, icon: "hourglass")
            }
        }
        .padding(18)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func actionWindowMiniCard(window: ActionWindow, icon: String) -> some View {
        let isActive = isSelectedDateToday && window.contains(date: calculationTargetDate)
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(window.type.accentColor)
                
                Text(window.type.rawValue)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                if isActive {
                    Circle()
                        .fill(window.type.accentColor)
                        .frame(width: 5, height: 5)
                }
            }
            
            Text(window.formattedRange)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(window.type.accentColor)
            
            HStack {
                Text(window.type.sanskritName)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(window.type.isAuspicious ? "Auspicious" : "Avoid")
                    .font(.system(size: 8, weight: .heavy))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(window.type.accentColor.opacity(0.18))
                    .foregroundColor(window.type.accentColor)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(isActive ? window.type.accentColor.opacity(0.10) : Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isActive ? window.type.accentColor.opacity(0.3) : Color.white.opacity(0.03), lineWidth: 1)
        )
    }
    
    // MARK: - Panchanga Essentials Card (5 Limbs of Vedic Time)
    
    private func panchangaEssentialsCard(panchanga: PanchangaSnapshot) -> some View {
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("PANCHANGA ESSENTIALS", systemImage: "sparkles")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(gold)
                
                Spacer()
                
                Text("5 Limbs of Vedic Time")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                // 1. Vāra (Solar Day)
                panchangaLimbCard(
                    limb: "VĀRA (SOLAR DAY)",
                    mainTitle: panchanga.vara.nameSanskrit,
                    subTitle: "\(panchanga.vara.nameEnglish) • \(panchanga.vara.rulingGraha)",
                    badge: "Element: \(panchanga.vara.element)",
                    tint: Color(red: 0.94, green: 0.76, blue: 0.42)
                )
                
                // 2. Tithi (Lunar Phase)
                panchangaLimbCard(
                    limb: "TITHI (LUNAR DAY)",
                    mainTitle: panchanga.tithiName,
                    subTitle: "\(panchanga.paksha) Paksha",
                    badge: "Phase #\(panchanga.tithiNumber)",
                    tint: Color(red: 0.85, green: 0.88, blue: 0.98)
                )
                
                // 3. Nakshatra (Lunar Mansion)
                panchangaLimbCard(
                    limb: "NAKSHATRA (MANSION)",
                    mainTitle: panchanga.nakshatraName,
                    subTitle: "Deity: \(panchanga.nakshatraDeity)",
                    badge: panchanga.nakshatraQuality,
                    tint: Color(red: 0.40, green: 0.82, blue: 0.60)
                )
                
                // 4. Yoga (Solar-Lunar Union)
                panchangaLimbCard(
                    limb: "YOGA (SOLAR-LUNAR)",
                    mainTitle: panchanga.yogaName,
                    subTitle: "Cosmic Resonance",
                    badge: "Harmonic",
                    tint: Color(red: 0.60, green: 0.50, blue: 0.85)
                )
            }
        }
        .padding(18)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func panchangaLimbCard(limb: String, mainTitle: String, subTitle: String, badge: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(limb)
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .tracking(1.0)
                .foregroundColor(.secondary)
            
            Text(mainTitle)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(subTitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(tint)
            
            Text(badge)
                .font(.system(size: 8, weight: .semibold))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(tint.opacity(0.14))
                .foregroundColor(tint)
                .clipShape(Capsule())
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
        )
    }
    
    // MARK: - Active Sacred Window Hero Card
    
    private func activeSacredHeroCard(snapshot: MuhurtaSnapshot) -> some View {
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        let activeMuhurta = snapshot.currentMuhurta ?? snapshot.brahmaMuhurta
        let target = calculationTargetDate
        let isNow = activeMuhurta.contains(date: target)
        
        let remainingSeconds = max(0, activeMuhurta.endTime.timeIntervalSince(target))
        let remainingMins = Int(remainingSeconds / 60)
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isNow ? gold : Color.white.opacity(0.4))
                        .frame(width: 6, height: 6)
                    
                    Text(isNow ? "ACTIVE SACRED WINDOW" : "UPCOMING WINDOW")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundColor(isNow ? gold : .secondary)
                }
                
                Spacer()
                
                // Auspiciousness Badge
                Text(activeMuhurta.quality.rawValue.uppercased())
                    .font(.system(size: 9, weight: .heavy))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(activeMuhurta.quality.accentColor.opacity(0.2))
                    .foregroundColor(activeMuhurta.quality.accentColor)
                    .clipShape(Capsule())
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(activeMuhurta.nameSanskrit)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(activeMuhurta.nameEnglish)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.85))
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(formatRange(start: activeMuhurta.startTime, end: activeMuhurta.endTime))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(gold)
                }
            }
            
            // Progress Bar if Active
            if isNow && activeMuhurta.duration > 0 {
                let progress = activeMuhurta.progress(at: target)
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 5)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(gold)
                                .frame(width: geo.size.width * CGFloat(progress), height: 5)
                        }
                    }
                    .frame(height: 5)
                    
                    HStack {
                        Text("\(remainingMins)m remaining in this window")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(gold)
                        Spacer()
                        Text("Deity: \(activeMuhurta.deity)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                HStack {
                    Text("Presiding Deity: \(activeMuhurta.deity)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.8))
                    Spacer()
                    Text("Muhurta \(activeMuhurta.index) of 30")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            
            Text(activeMuhurta.description)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
        .padding(20)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isNow ? gold.opacity(0.4) : Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - Selected Date Schedule Hero Card (Shown on non-today dates)
    
    private func selectedDateScheduleHeroCard(snapshot: MuhurtaSnapshot, panchanga: PanchangaSnapshot?) -> some View {
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        let dateString = f.string(from: selectedDate)
        
        let brahma = snapshot.brahmaMuhurta
        
        return VStack(alignment: .leading, spacing: 16) {
            // Header with Kali Yuga & Samvatsara
            if let chrono = panchanga?.chronometry {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .foregroundColor(gold)
                        
                        Text("\(chrono.samvatsaraName.uppercased()) SAMVATSARA")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.2)
                            .foregroundColor(gold)
                    }
                    
                    Spacer()
                    
                    Text("\(chrono.ayana) • \(chrono.ritu)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Big Vedic Tithi & Masa Headline
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(chrono.tithiSanskrit)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Text("\(chrono.masa) • \(panchanga?.vara.nameSanskrit ?? "")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(gold)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(dateString)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateString)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Astronomical ephemeris for this solar day")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // Primary Brahma Muhurta Schedule Pill
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(gold.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(gold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Brahma Muhurta (Sacred Dawn)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(formatRange(start: brahma.startTime, end: brahma.endTime))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(gold)
                }
                
                Spacer()
                
                Text("\(Int(brahma.duration / 60))m Window")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .foregroundColor(.secondary)
                    .clipShape(Capsule())
            }
            .padding(12)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(gold.opacity(0.2), lineWidth: 1)
            )
            
            // 3-Column Key Timing Highlights
            HStack(spacing: 8) {
                scheduleMiniHighlight(
                    title: "Sunrise",
                    time: snapshot.solarTimes.sunrise,
                    icon: "sunrise.fill",
                    tint: Color(red: 0.94, green: 0.76, blue: 0.42)
                )
                
                scheduleMiniHighlight(
                    title: "Abhijit (Noon)",
                    time: snapshot.abhijitMuhurta.startTime,
                    icon: "sun.max.fill",
                    tint: Color(red: 0.40, green: 0.82, blue: 0.60)
                )
                
                scheduleMiniHighlight(
                    title: "Sunset",
                    time: snapshot.solarTimes.sunset,
                    icon: "sunset.fill",
                    tint: Color(red: 0.92, green: 0.55, blue: 0.40)
                )
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.13, blue: 0.18),
                    Color(red: 0.08, green: 0.09, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    private func scheduleMiniHighlight(title: String, time: Date, icon: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(tint)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(time, format: Date.FormatStyle(date: .omitted, time: .shortened))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    // MARK: - Solar Ephemeris Quartet Grid
    
    private func solarMetricsGrid(snapshot: MuhurtaSnapshot) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            metricCard(title: "Sunrise", sub: "Surya Udaya", time: snapshot.solarTimes.sunrise, icon: "sunrise.fill", tint: Color(red: 0.94, green: 0.76, blue: 0.42))
            metricCard(title: "Solar Noon", sub: "Abhijit Zenith", time: snapshot.solarTimes.solarNoon, icon: "sun.max.fill", tint: Color(red: 1.0, green: 0.85, blue: 0.40))
            metricCard(title: "Sunset", sub: "Astamaya", time: snapshot.solarTimes.sunset, icon: "sunset.fill", tint: Color(red: 0.92, green: 0.55, blue: 0.40))
            metricCard(title: "Civil Dawn", sub: "Pratah Sandhya", time: snapshot.solarTimes.civilDawn ?? snapshot.dawnSandhya.startTime, icon: "sparkles", tint: Color(red: 0.60, green: 0.50, blue: 0.85))
        }
    }
    
    private func metricCard(title: String, sub: String, time: Date, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text(time, format: Date.FormatStyle(date: .omitted, time: .shortened))
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(tint)
            
            Text(sub)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }
    
    // MARK: - Evening Sandhya Card
    
    private func bedtimeRecommendationCard(snapshot: MuhurtaSnapshot) -> some View {
        let brahmaStart = snapshot.brahmaMuhurta.startTime
        let idealBedtimeStart = brahmaStart.addingTimeInterval(-8.0 * 3600.0)
        let idealBedtimeEnd = brahmaStart.addingTimeInterval(-7.5 * 3600.0)
        
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        let rangeStr = "\(f.string(from: idealBedtimeStart)) – \(f.string(from: idealBedtimeEnd))"
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("SANDHYA SLEEP ONSET", systemImage: "moon.fill")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                
                Spacer()
                
                Text("Kapha Phase (6–10 PM)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(rangeStr)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("5 Cycles (7.5 hrs)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Text("To awaken naturally during Brahma Muhurta, sleep during the evening Kapha phase to complete 5 unbroken 90-minute ultradian sleep cycles.")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
        .padding(18)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - 30 Muhurta Ephemeris Timeline Card
    
    private func muhurtaTimelineCard(snapshot: MuhurtaSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sūryodayādi Ephemeris")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Complete 30 Muhurta Cycle of the 24h Ahoratra")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isTimelineExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isTimelineExpanded ? "Collapse" : "View All 30")
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: isTimelineExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
            }
            
            if isTimelineExpanded {
                MuhurtaTimelineView(muhurtas: snapshot.allMuhurtas, isLiveDate: isSelectedDateToday)
                    .padding(.top, 6)
            } else {
                VStack(spacing: 8) {
                    let brahma = snapshot.brahmaMuhurta
                    timelineMiniRow(name: "Brahma Muhurta", devanagari: "ब्रह्म मुहूर्त", time: brahma.formatted12HourRange, deity: "Brahmā", badge: "Sacred", badgeColor: Color(red: 0.94, green: 0.76, blue: 0.42))
                    timelineMiniRow(name: "Prātaḥ Sandhya", devanagari: "उषस् काल", time: snapshot.dawnSandhya.formatted12HourRange, deity: "Uṣas", badge: "Sacred", badgeColor: Color(red: 0.92, green: 0.55, blue: 0.40))
                    timelineMiniRow(name: "Abhijit Muhurta", devanagari: "अभिजित्", time: snapshot.abhijitMuhurta.formatted12HourRange, deity: "Viṣṇu", badge: "Auspicious", badgeColor: Color(red: 0.40, green: 0.82, blue: 0.60))
                    timelineMiniRow(name: "Sāyaṁ Sandhya", devanagari: "सायं सन्ध्या", time: snapshot.duskSandhya.formatted12HourRange, deity: "Varuṇa", badge: "Sacred", badgeColor: Color(red: 0.60, green: 0.50, blue: 0.85))
                }
            }
        }
        .padding(18)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func timelineMiniRow(name: String, devanagari: String, time: String, deity: String, badge: String, badgeColor: Color) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(badgeColor)
                .frame(width: 7, height: 7)
            
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(name)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("(\(devanagari))")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Text("Deity: \(deity)")
                    .font(.system(size: 10))
                    .foregroundColor(Color.white.opacity(0.55))
            }
            
            Spacer()
            
            Text(time)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(badgeColor)
        }
        .padding(10)
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    // MARK: - Helpers & Time Conversions
    
    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color(red: 0.94, green: 0.76, blue: 0.42))
            Text("Computing Astronomical Solar Coordinates...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
    }
    
    private func refreshCalculations() {
        let coord = locationService.currentCoordinate
        let target = calculationTargetDate
        currentSnapshot = MuhurtaEngine.calculateSnapshot(at: target, coordinate: coord)
        currentPanchanga = PanchangaEngine.calculatePanchanga(for: target, coordinate: coord)
    }
    
    private func secondsFromMidnight(for date: Date) -> Double {
        let calendar = Calendar.current
        let c = calendar.dateComponents([.hour, .minute, .second], from: date)
        return Double((c.hour ?? 0) * 3600 + (c.minute ?? 0) * 60 + (c.second ?? 0))
    }
    
    private func dateFromSeconds(seconds: Double, on baseDate: Date) -> Date {
        let calendar = Calendar.current
        let sec = Int(seconds) % 86400
        let h = sec / 3600
        let m = (sec % 3600) / 60
        let s = sec % 60
        return calendar.date(bySettingHour: h, minute: m, second: s, of: baseDate) ?? baseDate
    }
    
    private func dateWeekdayShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date).uppercased()
    }
    
    private func dateDayNumber(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
    
    private func formatScrubbedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm:ss a"
        return f.string(from: date)
    }
    
    private func formatShortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
    
    private func formatRange(start: Date, end: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: start)) – \(f.string(from: end))"
    }
    
    private func skyPhaseDescription(altitude: Double) -> String {
        if altitude > 50 {
            return "Solar Zenith (Agni Peak)"
        } else if altitude > 20 {
            return "Daylight Radiance"
        } else if altitude > 0 {
            return "Low Solar Elevation"
        } else if altitude > -6 {
            return "Civil Twilight (Sandhya)"
        } else if altitude > -12 {
            return "Nautical Twilight (Brahma)"
        } else if altitude > -18 {
            return "Astronomical Dawn"
        } else {
            return "Deep Night (Nāstika)"
        }
    }
    
    private var datePickerSheet: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(Color(red: 0.94, green: 0.76, blue: 0.42))
                .padding()
                
                Spacer()
            }
            .navigationTitle("Select Solar Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        refreshCalculations()
                        isShowingDatePicker = false
                    }
                    .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                }
            }
        }
        .presentationDetents([.medium])
    }
}
