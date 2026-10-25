//
//  SolarArcVisualizer.swift
//  Muhurta
//
//  A minimalist circular celestial dial visualizing the Sun's position relative to the horizon,
//  illuminating Brahma Muhurta, Dawn/Dusk Sandhya, and Abhijit Muhurta.
//

import SwiftUI
import CoreLocation

public struct SolarArcVisualizer: View {
    public let snapshot: MuhurtaSnapshot
    @State private var isPulsing = false
    
    public init(snapshot: MuhurtaSnapshot) {
        self.snapshot = snapshot
    }
    
    private func normalizedTime(_ date: Date) -> Double {
        let calendar = Calendar.current
        let hour = Double(calendar.component(.hour, from: date))
        let minute = Double(calendar.component(.minute, from: date))
        let second = Double(calendar.component(.second, from: date))
        return (hour * 3600.0 + minute * 60.0 + second) / 86400.0
    }
    
    private func angle(for normalized: Double) -> Angle {
        let degrees = (normalized - 0.5) * 360.0 - 90.0
        return Angle(degrees: degrees)
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background Minimalist Track
                Circle()
                    .stroke(Color(red: 0.12, green: 0.14, blue: 0.18), lineWidth: 16)
                    .frame(width: 250, height: 250)
                
                // Subtle Center Depth
                Circle()
                    .fill(Color(red: 0.07, green: 0.08, blue: 0.11))
                    .frame(width: 218, height: 218)
                
                // Horizon Indicator (Clean dashed hairline)
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    Path { path in
                        path.move(to: CGPoint(x: 25, y: h / 2))
                        path.addLine(to: CGPoint(x: w - 25, y: h / 2))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                    .foregroundColor(Color.white.opacity(0.15))
                }
                .frame(width: 250, height: 250)
                
                // MARK: - Highlighted Sacred Windows
                
                // 1. Brahma Muhurta Arc (Warm Dawn Amber)
                MuhurtaArcSegment(
                    startFraction: normalizedTime(snapshot.brahmaMuhurta.startTime),
                    endFraction: normalizedTime(snapshot.brahmaMuhurta.endTime),
                    color: Color(red: 0.92, green: 0.70, blue: 0.38),
                    lineWidth: 12
                )
                
                // 2. Dawn Sandhya / Ushas Arc (Gentle Terracotta Rose)
                MuhurtaArcSegment(
                    startFraction: normalizedTime(snapshot.dawnSandhya.startTime),
                    endFraction: normalizedTime(snapshot.dawnSandhya.endTime),
                    color: Color(red: 0.88, green: 0.52, blue: 0.40),
                    lineWidth: 12
                )
                
                // 3. Abhijit Muhurta Arc (Quiet Sage Green)
                MuhurtaArcSegment(
                    startFraction: normalizedTime(snapshot.abhijitMuhurta.startTime),
                    endFraction: normalizedTime(snapshot.abhijitMuhurta.endTime),
                    color: Color(red: 0.40, green: 0.78, blue: 0.65),
                    lineWidth: 14
                )
                
                // 4. Dusk Sandhya Arc (Restful Twilight Indigo)
                MuhurtaArcSegment(
                    startFraction: normalizedTime(snapshot.duskSandhya.startTime),
                    endFraction: normalizedTime(snapshot.duskSandhya.endTime),
                    color: Color(red: 0.55, green: 0.50, blue: 0.72),
                    lineWidth: 12
                )
                
                // MARK: - The Sun Indicator (Precision Instrument Style)
                let nowFraction = normalizedTime(snapshot.timestamp)
                let sunAngle = angle(for: nowFraction)
                let radius: CGFloat = 125
                let sunX = radius * cos(CGFloat(sunAngle.radians))
                let sunY = radius * sin(CGFloat(sunAngle.radians))
                
                ZStack {
                    Circle()
                        .fill(Color(red: 0.92, green: 0.70, blue: 0.38).opacity(isPulsing ? 0.3 : 0.1))
                        .frame(width: 26, height: 26)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .shadow(color: Color.orange.opacity(0.4), radius: 4)
                }
                .offset(x: sunX, y: sunY)
                
                // MARK: - Center Information Gauge
                VStack(spacing: 3) {
                    if snapshot.isBrahmaMuhurtaActive {
                        Text("BRAHMA MUHURTA")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.5)
                            .foregroundColor(Color(red: 0.92, green: 0.70, blue: 0.38))
                        
                        Text("Active Now")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    } else if snapshot.isAbhijitActive {
                        Text("ABHIJIT MUHURTA")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.5)
                            .foregroundColor(Color(red: 0.40, green: 0.78, blue: 0.65))
                        
                        Text("Midday Clarity")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        Text(snapshot.solarPosition.isDaylight ? "DAYLIGHT" : "NIGHT SKY")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(1.5)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%+.1f°", snapshot.solarPosition.altitude))
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Solar Altitude")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 260, height: 260)
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
            
            // Minimalist Legend
            HStack(spacing: 14) {
                legendItem(color: Color(red: 0.92, green: 0.70, blue: 0.38), label: "Brahma", range: snapshot.brahmaMuhurta)
                legendItem(color: Color(red: 0.88, green: 0.52, blue: 0.40), label: "Ushas", range: snapshot.dawnSandhya)
                legendItem(color: Color(red: 0.40, green: 0.78, blue: 0.65), label: "Abhijit", range: snapshot.abhijitMuhurta)
            }
        }
    }
    
    private func legendItem(color: Color, label: String, range: MuhurtaPeriod) -> some View {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        let rangeStr = "\(f.string(from: range.startTime))–\(f.string(from: range.endTime))"
        
        return HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
            
            Text(rangeStr)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}

private struct MuhurtaArcSegment: View {
    let startFraction: Double
    let endFraction: Double
    let color: Color
    let lineWidth: CGFloat
    
    private var normalizedTrim: (start: CGFloat, end: CGFloat) {
        let s = CGFloat(startFraction)
        var e = CGFloat(endFraction)
        if e < s { e += 1.0 }
        return (s, e)
    }
    
    var body: some View {
        Circle()
            .trim(from: normalizedTrim.start, to: normalizedTrim.end)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .frame(width: 250, height: 250)
    }
}
