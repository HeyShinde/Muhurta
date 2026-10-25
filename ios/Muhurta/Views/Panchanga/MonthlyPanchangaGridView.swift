//
//  MonthlyPanchangaGridView.swift
//  Muhurta
//
//  State-of-the-Art Vedic Chronometry & Monthly Panchāṅga Sanctuary.
//  An original, ultra-premium Apple-grade calendar experience:
//  - Dual Vedic-Gregorian Month Ribbon (Māsa, Ṛtu, Samvatsara, Kali Yuga)
//  - Interactive Lunar-Solar Mosaic with inline Tithi labels & Sacred Jewel Badges
//  - Luminous Moon Phase Hero with illumination metrics
//  - 5 Sacred Limbs (Pañca-Aṅga) Bento Cards
//  - Śubha & Aśubha Action Windows Timeline (Abhijit, Rāhu Kāla, Yamagaṇḍa, Gulika)
//  - Consecrated Daily Saṅkalpam in Sanskrit Devanagari with One-Tap Copy
//  - Daily Festival & Vrata Dossier
//

import SwiftUI
import CoreLocation

public struct MonthlyPanchangaGridView: View {
    @State private var locationService = LocationService.shared
    @State private var currentMonthDate: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var isShowingAddEventSheet = false
    @State private var isShowingChronometryGuide = false
    @State private var copiedSankalpa = false
    
    public init() {}
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 1 // Sunday
        return cal
    }
    
    private var currentCoordinate: CLLocationCoordinate2D {
        locationService.currentCoordinate
    }
    
    private var currentVedicToday: Date {
        PanchangaEngine.vedicDate(for: Date(), coordinate: currentCoordinate)
    }
    
    private var gregorianMonthYear: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: currentMonthDate)
    }
    
    private var daysInCurrentMonthGrid: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonthDate) else {
            return []
        }
        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingDaysCount = firstWeekday - 1
        
        var dates: [Date] = []
        if leadingDaysCount > 0 {
            for dayOffset in stride(from: -leadingDaysCount, to: 0, by: 1) {
                if let d = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) {
                    dates.append(d)
                }
            }
        }
        
        var curr = monthStart
        while curr < monthEnd {
            dates.append(curr)
            guard let next = calendar.date(byAdding: .day, value: 1, to: curr) else { break }
            curr = next
        }
        
        let remainder = dates.count % 7
        if remainder > 0 {
            let trailingDaysCount = 7 - remainder
            if let lastDate = dates.last {
                for dayOffset in 1...trailingDaysCount {
                    if let d = calendar.date(byAdding: .day, value: dayOffset, to: lastDate) {
                        dates.append(d)
                    }
                }
            }
        }
        return dates
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.08)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Dual Vedic & Gregorian Month Navigation Ribbon
                        monthNavigationRibbon
                            .padding(.top, 10)
                        
                        // 2. Weekday Column Header (S M T W T F S)
                        weekdayHeaderRow
                        
                        // 3. Innovative Lunar-Solar Mosaic Calendar Grid
                        lunarSolarMosaicGrid
                        
                        // 4. Selected Date Luminous Moon & Panchanga Hero
                        selectedDateHeroDossier
                        
                        // 5. Pañca-Aṅga 5 Core Limbs Bento Grid
                        pancaAngaBentoGrid
                        
                        // 6. Sacred Windows of Action (Śubha & Aśubha Timelines)
                        actionWindowsTimelineCard
                        
                        // 7. Today's Festivals & Holy Observances
                        dailyFestivalsSection
                        
                        // 8. Traditional Daily Saṅkalpam (Devanagari + Meaning)
                        dailySankalpaCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 130) // Clear floating dock
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingAddEventSheet) {
                AddLifeEventView()
            }
            .sheet(isPresented: $isShowingChronometryGuide) {
                VedicCalendarFullGuideView()
            }
        }
    }
    
    // MARK: - 1. Month Navigation Ribbon
    
    private var monthNavigationRibbon: some View {
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: currentMonthDate) ?? currentMonthDate
        let chronometry = PanchangaEngine.calculateChronometry(for: noon, coordinate: currentCoordinate)
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        
        return VStack(spacing: 8) {
            // Month navigation row
            HStack(spacing: 12) {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color(red: 0.94, green: 0.60, blue: 0.28))
                }
                
                VStack(spacing: 2) {
                    Text(gregorianMonthYear)
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("\(chronometry.masaSanskrit) • \(chronometry.ritu)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(gold)
                }
                
                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color(red: 0.94, green: 0.60, blue: 0.28))
                }
                
                Spacer()
                
                // Quick Jump to Today
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        currentMonthDate = Date()
                        selectedDate = Date()
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11))
                        Text("Today")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(gold.opacity(0.12))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(gold.opacity(0.3), lineWidth: 0.8)
                    )
                }
                
                // Consecrate Milestone (+) Button
                Button {
                    isShowingAddEventSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color(red: 0.94, green: 0.60, blue: 0.28))
                }
            }
            
            // Cosmic Era Ribbon
            HStack {
                Text("\(chronometry.samvatsaraName.uppercased()) • \(chronometry.masa.uppercased())")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(gold.opacity(0.9))
                Spacer()
                Text("📍 \(locationService.cityName)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - 2. Weekday Header Row
    
    private var weekdayHeaderRow: some View {
        HStack {
            ForEach(["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.45))
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - 3. Lunar-Solar Mosaic Calendar Grid
    
    private var lunarSolarMosaicGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(daysInCurrentMonthGrid, id: \.timeIntervalSince1970) { date in
                mosaicDateCell(for: date)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private func mosaicDateCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDate(date, inSameDayAs: currentVedicToday)
        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonthDate, toGranularity: .month)
        let dayNum = calendar.component(.day, from: date)
        
        // Compute mini Tithi abbreviation and festival badge
        let summary = PanchangaEngine.tithiMiniSummary(for: date, coordinate: currentCoordinate)
        let badge = VedicFestivalManager.badgeSymbol(for: date, coordinate: currentCoordinate)
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        
        // Clean Tithi short label (e.g., "शु.१४", "पूर्णिमा", "कृ.४", "अमा.")
        let shortTithiLabel: String = {
            if summary.tithiDevanagari == "पूर्णिमा" { return "पूर्ण." }
            if summary.tithiDevanagari == "अमावास्या" { return "अमा." }
            let prefix = summary.isShukla ? "शु." : "कृ."
            return "\(prefix)\(summary.tithiNum)"
        }()
        
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedDate = date
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 2) {
                // Day number
                Text("\(dayNum)")
                    .font(.system(size: 15, weight: (isSelected || isToday) ? .bold : .medium, design: .serif))
                    .foregroundColor(
                        isSelected ? .white :
                        (isToday ? gold :
                        (isCurrentMonth ? .white.opacity(0.9) : .white.opacity(0.25)))
                    )
                
                // Inline Tithi Label (Devanagari Tithi scan!)
                Text(shortTithiLabel)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(
                        isSelected ? .white.opacity(0.9) :
                        (summary.tithiNum == 11 ? Color(red: 0.40, green: 0.85, blue: 0.60) :
                        (summary.tithiNum == 15 ? gold :
                        (isCurrentMonth ? .white.opacity(0.55) : .white.opacity(0.2))))
                    )
                
                // Sacred Jewel Indicator (dot or icon)
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10))
                        .frame(height: 12)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 12)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.94, green: 0.42, blue: 0.20), Color(red: 0.85, green: 0.30, blue: 0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 0.94, green: 0.42, blue: 0.20).opacity(0.5), radius: 8, y: 3)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(gold, lineWidth: 1.5)
                        .background(gold.opacity(0.10))
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 4. Selected Date Luminous Moon Hero Dossier
    
    private var selectedDateHeroDossier: some View {
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let vDate = PanchangaEngine.vedicDate(for: noon, coordinate: currentCoordinate)
        let panchanga = PanchangaEngine.calculatePanchanga(for: vDate, coordinate: currentCoordinate)
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        let saffron = Color(red: 0.94, green: 0.60, blue: 0.28)
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE, d MMMM yyyy"
        let fullDateStr = dayFormatter.string(from: selectedDate)
        
        return VStack(spacing: 16) {
            // Top Row: Date, Weekday & Share Action
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(fullDateStr)
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    if let p = panchanga {
                        Text("\(p.chronometry.tithiSanskrit) • \(p.chronometry.masa)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(saffron)
                    }
                }
                
                Spacer()
                
                // Native Share Button
                if let p = panchanga {
                    ShareLink(
                        item: buildShareText(panchanga: p, date: selectedDate),
                        subject: Text("Vedic Panchāṅga • \(fullDateStr)")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(gold)
                            .padding(10)
                            .background(gold.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
            }
            
            // Moon Visualizer with Illumination & Phase Details
            HStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white, Color(red: 0.75, green: 0.82, blue: 0.92)],
                                center: .center,
                                startRadius: 5,
                                endRadius: 36
                            )
                        )
                        .frame(width: 68, height: 68)
                        .shadow(color: Color.white.opacity(0.35), radius: 12)
                    
                    // Crater textures
                    Circle()
                        .fill(Color.black.opacity(0.10))
                        .frame(width: 16, height: 16)
                        .offset(x: -10, y: -8)
                    Circle()
                        .fill(Color.black.opacity(0.08))
                        .frame(width: 22, height: 22)
                        .offset(x: 12, y: 10)
                }
                
                if let p = panchanga {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(p.chronometry.tithiName)
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        
                        Text("\(p.paksha) • \(p.chronometry.samvatsaraName)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(gold)
                        
                        Text(p.chronometry.tithiMeaning)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.65))
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.11, blue: 0.16),
                            Color(red: 0.07, green: 0.08, blue: 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(red: 0.94, green: 0.60, blue: 0.28).opacity(0.25), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 5. Pañca-Aṅga Bento Grid
    
    private var pancaAngaBentoGrid: some View {
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let vDate = PanchangaEngine.vedicDate(for: noon, coordinate: currentCoordinate)
        let panchanga = PanchangaEngine.calculatePanchanga(for: vDate, coordinate: currentCoordinate)
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        
        return VStack(spacing: 12) {
            HStack {
                Text("पञ्च-अङ्ग • 5 Sacred Limbs")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    isShowingChronometryGuide = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundColor(gold)
                }
            }
            
            if let p = panchanga {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    bentoCell(
                        title: "वासर (Vāra)",
                        sanskrit: p.vara.nameSanskrit,
                        english: "\(p.vara.nameEnglish) • Ruled by \(p.vara.rulingGraha)",
                        icon: "sun.max.fill",
                        color: Color(red: 0.94, green: 0.60, blue: 0.28)
                    )
                    
                    bentoCell(
                        title: "तिथि (Tithi)",
                        sanskrit: p.chronometry.tithiSanskrit,
                        english: "\(p.paksha) • Phase \(p.chronometry.tithiNumber)",
                        icon: "moon.fill",
                        color: gold
                    )
                    
                    bentoCell(
                        title: "नक्षत्र (Nakṣatra)",
                        sanskrit: p.nakshatraName,
                        english: "\(p.nakshatraQuality) • Deity \(p.nakshatraDeity)",
                        icon: "sparkles",
                        color: Color(red: 0.40, green: 0.85, blue: 0.60)
                    )
                    
                    bentoCell(
                        title: "योग (Yoga)",
                        sanskrit: p.yogaName,
                        english: "Cosmic Sun-Moon Angle",
                        icon: "circle.circle.fill",
                        color: Color(red: 0.70, green: 0.60, blue: 0.95)
                    )
                }
            }
        }
    }
    
    private func bentoCell(title: String, sanskrit: String, english: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }
            
            Text(sanskrit)
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text(english)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color.opacity(0.9))
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 6. Sacred Windows of Action Timeline Card
    
    private var actionWindowsTimelineCard: some View {
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let vDate = PanchangaEngine.vedicDate(for: noon, coordinate: currentCoordinate)
        let panchanga = PanchangaEngine.calculatePanchanga(for: vDate, coordinate: currentCoordinate)
        let solar = SolarCalculator.calculateSolarTimes(for: vDate, coordinate: currentCoordinate)
        
        return VStack(spacing: 12) {
            HStack {
                Text("काल चक्र • Action Windows (Śubha & Aśubha)")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Spacer()
            }
            
            if let p = panchanga, let s = solar {
                VStack(spacing: 8) {
                    // Sunrise & Sunset
                    HStack {
                        actionWindowChip(label: "Sūryodaya (Sunrise)", time: formatTime(s.sunrise), icon: "sunrise.fill", color: Color(red: 0.94, green: 0.76, blue: 0.42))
                        actionWindowChip(label: "Sūryāsta (Sunset)", time: formatTime(s.sunset), icon: "sunset.fill", color: Color(red: 0.94, green: 0.50, blue: 0.22))
                    }
                    
                    // Abhijit (Auspicious)
                    actionWindowRow(
                        name: "Abhijit Muhūrta (Midday Golden Window)",
                        range: p.actionWindows.abhijit.formattedRange,
                        badge: "ŚUBHA (SUPREME)",
                        color: Color(red: 0.40, green: 0.85, blue: 0.60)
                    )
                    
                    // Rahu Kalam (Inauspicious)
                    actionWindowRow(
                        name: "Rāhu Kāla (Tamasic Window)",
                        range: p.actionWindows.rahuKalam.formattedRange,
                        badge: "AŚUBHA (AVOID)",
                        color: Color(red: 0.94, green: 0.40, blue: 0.40)
                    )
                    
                    // Yamaganda & Gulika
                    HStack {
                        actionWindowChip(label: "Yamagaṇḍa", time: p.actionWindows.yamaganda.formattedRange, icon: "exclamationmark.triangle.fill", color: Color(red: 0.94, green: 0.60, blue: 0.28))
                        actionWindowChip(label: "Gulika Kāla", time: p.actionWindows.gulika.formattedRange, icon: "circle.grid.cross.fill", color: Color(red: 0.70, green: 0.55, blue: 0.95))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private func actionWindowChip(label: String, time: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                Text(time)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
    
    private func actionWindowRow(name: String, range: String, badge: String, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(range)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
            }
            Spacer()
            Text(badge)
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.15))
                .cornerRadius(6)
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
    
    // MARK: - 7. Daily Festivals Section
    
    private var dailyFestivalsSection: some View {
        let festivals = VedicFestivalManager.festivals(for: selectedDate, coordinate: currentCoordinate)
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        
        return VStack(spacing: 12) {
            HStack {
                Text("पर्वदिनम् • Festivals & Vratas")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Spacer()
            }
            
            if !festivals.isEmpty {
                VStack(spacing: 10) {
                    ForEach(festivals) { fest in
                        festivalCardRow(fest: fest, gold: gold)
                    }
                }
            } else {
                HStack(spacing: 12) {
                    Text("☀️")
                        .font(.system(size: 22))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nitya Sādhana")
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        Text("Standard auspicious solar day for continuous contemplation and worship.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    private func festivalCardRow(fest: VedicFestival, gold: Color) -> some View {
        HStack(spacing: 14) {
            Text(fest.iconSymbol)
                .font(.system(size: 26))
                .frame(width: 44, height: 44)
                .background(Color(hex: fest.colorHex).opacity(0.18))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 3) {
                Text(fest.nameSanskrit)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Text(fest.nameEnglish)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(gold)
                    Text("• \(fest.deity)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
                Text(fest.description)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: fest.colorHex).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 8. Traditional Daily Saṅkalpam
    
    private var dailySankalpaCard: some View {
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let chronometry = PanchangaEngine.calculateChronometry(for: noon, coordinate: currentCoordinate)
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "scroll.fill")
                    .foregroundColor(gold)
                Text("दैनिक सङ्कल्प • Authentic Sankalpam")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = chronometry.sankalpaSanskrit
                    copiedSankalpa = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copiedSankalpa = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copiedSankalpa ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                        Text(copiedSankalpa ? "Copied" : "Copy")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(gold.opacity(0.12))
                    .cornerRadius(6)
                }
            }
            
            Text(chronometry.sankalpaSanskrit)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundColor(Color(red: 0.98, green: 0.88, blue: 0.70))
                .lineSpacing(5)
            
            Text(chronometry.sankalpaEnglish)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.65))
                .lineSpacing(3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(gold.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helpers
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentMonthDate) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                currentMonthDate = newDate
                selectedDate = newDate
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "hh:mm a"
        return f.string(from: date)
    }
    
    private func buildShareText(panchanga: PanchangaSnapshot, date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        let dStr = f.string(from: date)
        
        return """
        🕉️ Vedic Panchāṅga • \(dStr)
        📍 \(locationService.cityName)
        
        • संवत्सर: \(panchanga.chronometry.samvatsaraName) (\(panchanga.chronometry.ayana))
        • मास: \(panchanga.chronometry.ritu) • \(panchanga.chronometry.masaSanskrit)
        • तिथि: \(panchanga.chronometry.tithiSanskrit) (\(panchanga.paksha))
        • वासर: \(panchanga.vara.nameSanskrit) (\(panchanga.vara.rulingGraha))
        • नक्षत्र: \(panchanga.nakshatraName)
        • योग: \(panchanga.yogaName)
        
        Shared via Muhurta App
        """
    }
}

// MARK: - Color Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 240, 180, 80)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
