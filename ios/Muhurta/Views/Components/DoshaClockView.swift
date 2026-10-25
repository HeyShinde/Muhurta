//
//  DoshaClockView.swift
//  Muhurta
//
//  Ayurvedic 24-hour biological circadian clock visualization (Vata, Pitta, Kapha).
//

import SwiftUI

public struct DoshaClockView: View {
    public let currentDosha: Dosha
    public let currentWindow: DoshaWindow
    
    public init(currentDosha: Dosha, currentWindow: DoshaWindow) {
        self.currentDosha = currentDosha
        self.currentWindow = currentWindow
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Dosha Body Clock", systemImage: "circle.hexagongrid.fill")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(currentDosha.rawValue.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(currentDosha.themeColor.opacity(0.2))
                    .foregroundColor(currentDosha.themeColor)
                    .clipShape(Capsule())
            }
            
            // Current Active Dosha Card
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: currentDosha.iconName)
                        .font(.system(size: 22))
                        .foregroundColor(currentDosha.themeColor)
                        .frame(width: 44, height: 44)
                        .background(currentDosha.themeColor.opacity(0.15))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentWindow.label)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(currentDosha.elements)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(currentWindow.activityRecommendation)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.85))
                    .lineSpacing(3)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(currentDosha.themeColor.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // 24-Hour Cycle Gauge Bar
            HStack(spacing: 4) {
                DoshaBarSegment(dosha: .vata, timeLabel: "2–6 AM", isCurrent: currentDosha == .vata)
                DoshaBarSegment(dosha: .kapha, timeLabel: "6–10 AM", isCurrent: currentDosha == .kapha)
                DoshaBarSegment(dosha: .pitta, timeLabel: "10–2 PM", isCurrent: currentDosha == .pitta)
                DoshaBarSegment(dosha: .vata, timeLabel: "2–6 PM", isCurrent: currentDosha == .vata)
                DoshaBarSegment(dosha: .kapha, timeLabel: "6–10 PM", isCurrent: currentDosha == .kapha)
                DoshaBarSegment(dosha: .pitta, timeLabel: "10–2 AM", isCurrent: currentDosha == .pitta)
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

private struct DoshaBarSegment: View {
    let dosha: Dosha
    let timeLabel: String
    let isCurrent: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4)
                .fill(dosha.themeColor.opacity(isCurrent ? 1.0 : 0.35))
                .frame(height: isCurrent ? 8 : 4)
                .animation(.spring(), value: isCurrent)
            
            Text(timeLabel)
                .font(.system(size: 9, weight: isCurrent ? .bold : .regular))
                .foregroundColor(isCurrent ? .white : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
