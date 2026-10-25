//
//  PranayamaPacerView.swift
//  Muhurta
//
//  Interactive breathwork pacer with haptic feedback and expanding mandala animation.
//

import SwiftUI
import CoreHaptics

public struct PranayamaPacerView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var breathPhase: BreathPhase = .inhale
    @State private var phaseSecondsRemaining = 4
    @State private var totalSecondsElapsed = 0
    @State private var isActive = false
    @State private var timer: Timer?
    @State private var circleScale: CGFloat = 0.6
    
    private let targetMinutes = 5
    
    enum BreathPhase: String {
        case inhale = "Puraka (Inhale)"
        case holdIn = "Antar Kumbhaka (Hold)"
        case exhale = "Rechaka (Exhale)"
        case holdOut = "Bahya Kumbhaka (Rest)"
        
        var duration: Int { 4 }
        
        var instruction: String {
            switch self {
            case .inhale: return "Draw cool cosmic prana deep into the lower abdomen"
            case .holdIn: return "Still the mind in full fullness"
            case .exhale: return "Release all residual tension completely"
            case .holdOut: return "Rest in pure spacious awareness"
            }
        }
        
        var next: BreathPhase {
            switch self {
            case .inhale: return .holdIn
            case .holdIn: return .exhale
            case .exhale: return .holdOut
            case .holdOut: return .inhale
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Dark sanctuary background
            Color(red: 0.04, green: 0.05, blue: 0.10)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Top Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PRANAYAMA & DHYANA")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(2)
                            .foregroundColor(Color(red: 0.95, green: 0.77, blue: 0.35))
                        Text("Sama Vritti (Box Breathing)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button {
                        stopTimer()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // Expanding Breath Mandala
                ZStack {
                    // Outer Soft Glow Ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.77, blue: 0.35).opacity(0.25),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 160
                            )
                        )
                        .scaleEffect(circleScale * 1.3)
                    
                    // Middle Decorative Petals Ring
                    Circle()
                        .stroke(
                            Color(red: 0.95, green: 0.77, blue: 0.35).opacity(0.4),
                            style: StrokeStyle(lineWidth: 2, dash: [6, 8])
                        )
                        .frame(width: 220, height: 220)
                        .scaleEffect(circleScale)
                    
                    // Core Luminous Center
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.84, blue: 0.45),
                                    Color(red: 0.88, green: 0.62, blue: 0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(circleScale)
                        .shadow(color: Color.orange.opacity(0.5), radius: 20)
                    
                    // Center Countdown Number
                    VStack(spacing: 2) {
                        Text("\(phaseSecondsRemaining)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.08, green: 0.05, blue: 0.02))
                        
                        Text("SEC")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(2)
                            .foregroundColor(Color(red: 0.25, green: 0.18, blue: 0.08))
                    }
                }
                .frame(height: 300)
                
                // Breath Phase Text
                VStack(spacing: 8) {
                    Text(breathPhase.rawValue)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(breathPhase.instruction)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }
                
                Spacer()
                
                // Bottom Control Button
                Button {
                    if isActive {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: isActive ? "pause.fill" : "play.fill")
                        Text(isActive ? "Pause Practice" : "Begin Sacred Breath")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(Color(red: 0.08, green: 0.06, blue: 0.02))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.85, blue: 0.45),
                                Color(red: 0.88, green: 0.68, blue: 0.25)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func startTimer() {
        isActive = true
        triggerHaptic()
        animateCircle(for: breathPhase)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if phaseSecondsRemaining > 1 {
                phaseSecondsRemaining -= 1
            } else {
                breathPhase = breathPhase.next
                phaseSecondsRemaining = breathPhase.duration
                triggerHaptic()
                animateCircle(for: breathPhase)
            }
            totalSecondsElapsed += 1
        }
    }
    
    private func stopTimer() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }
    
    private func animateCircle(for phase: BreathPhase) {
        withAnimation(.easeInOut(duration: Double(phase.duration))) {
            switch phase {
            case .inhale:
                circleScale = 1.15
            case .holdIn:
                circleScale = 1.15
            case .exhale:
                circleScale = 0.6
            case .holdOut:
                circleScale = 0.6
            }
        }
    }
}
