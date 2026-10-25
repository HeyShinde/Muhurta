//
//  MuhurtaTimelineView.swift
//  Muhurta
//
//  Complete 30 Muhurta Vedic Ephemeris timeline aligned with authentic
//  Hindu Suryodayadi tradition (Sunrise-to-Sunrise Ahoratra).
//

import SwiftUI

public struct MuhurtaTimelineView: View {
    public let muhurtas: [MuhurtaPeriod]
    public let isLiveDate: Bool
    @State private var filterDaytime = true
    
    public init(muhurtas: [MuhurtaPeriod], isLiveDate: Bool = true) {
        self.muhurtas = muhurtas
        self.isLiveDate = isLiveDate
    }
    
    private var filteredList: [MuhurtaPeriod] {
        muhurtas.filter { $0.isDaytime == filterDaytime }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with Day / Night Switcher
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vedic Muhurta Ephemeris")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("30 divisions of the astronomical Ahoratra (Sunrise to Sunrise)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Picker("Cycle", selection: $filterDaytime) {
                    Text("Day (15)").tag(true)
                    Text("Night (15)").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
            
            // Authentic Vedic Cycle Exploration Banner
            cycleExplorationBanner
            
            // List of 15 Muhurtas (Flowing uninterrupted from Sunset to Sunrise)
            VStack(spacing: 8) {
                ForEach(filteredList) { period in
                    MuhurtaRow(period: period, isLiveDate: isLiveDate)
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
    
    // MARK: - Cycle Exploration Banner
    
    private var cycleExplorationBanner: some View {
        let ochre = Color(red: 0.92, green: 0.70, blue: 0.38)
        
        return HStack(spacing: 10) {
            Image(systemName: filterDaytime ? "sun.max.fill" : "moon.stars.fill")
                .font(.system(size: 13))
                .foregroundColor(filterDaytime ? ochre : Color(red: 0.55, green: 0.65, blue: 0.85))
            
            VStack(alignment: .leading, spacing: 2) {
                if filterDaytime {
                    Text("DINAMAN • DAYTIME SOLAR PHASE (SUNRISE → SUNSET)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundColor(ochre)
                    
                    if let first = filteredList.first, let last = filteredList.last {
                        Text("\(first.formattedTimeRange.components(separatedBy: " – ").first ?? "") to \(last.formattedTimeRange.components(separatedBy: " – ").last ?? "") • 15 Solar Windows")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("RATRIMAN • NOCTURNAL PHASE (SUNSET → NEXT SUNRISE)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundColor(Color(red: 0.55, green: 0.65, blue: 0.85))
                    
                    Text("Vedic day remains uninterrupted until Sunrise. All 15 night Muhurtas belong to this solar cycle.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct MuhurtaRow: View {
    let period: MuhurtaPeriod
    let isLiveDate: Bool
    
    private var isCurrent: Bool {
        isLiveDate && period.contains(date: Date())
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Index & Quality Dot
            ZStack {
                Circle()
                    .fill(period.quality.accentColor.opacity(0.18))
                    .frame(width: 28, height: 28)
                
                Text("\(period.index)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(period.quality.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(period.nameSanskrit)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isCurrent ? period.quality.accentColor : .white)
                    
                    if isCurrent {
                        Text("NOW")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(period.quality.accentColor)
                            .foregroundColor(.black)
                            .clipShape(Capsule())
                    }
                }
                
                Text(period.nameEnglish)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                // Time Range
                Text(formatTimeRange(start: period.startTime, end: period.endTime))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                
                // Vedic Quality Tag
                Text(period.quality.rawValue.capitalized)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(period.quality.accentColor)
            }
        }
        .padding(10)
        .background(isCurrent ? period.quality.accentColor.opacity(0.1) : Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isCurrent ? period.quality.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
    
    private func formatTimeRange(start: Date, end: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: start)) – \(f.string(from: end))"
    }
}
