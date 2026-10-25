//
//  SacredAlarmRingingView.swift
//  Muhurta
//
//  Full-screen sacred awakening sanctuary displayed when the alarm fires.
//  Features breathing solar corona aura, large authentic time display,
//  current astronomical coordinates, Sanskrit awakening invocation,
//  and intuitive Snooze / Awaken Sadhana actions.
//

import SwiftUI

struct SacredAlarmRingingView: View {
    @Bindable var alarmManager = AlarmManager.shared
    @State private var currentTime = Date()
    @State private var auraScale: CGFloat = 1.0
    @State private var wavePhase: CGFloat = 0.0
    
    private let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
    private let saffron = Color(red: 0.96, green: 0.58, blue: 0.28)
    
    var body: some View {
        ZStack {
            // Cosmic Obsidian Sky
            Color(red: 0.04, green: 0.05, blue: 0.07).ignoresSafeArea()
            
            // Pulsing Solar Corona & Breathing Aura
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [saffron.opacity(0.35), gold.opacity(0.15), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: geo.size.width * 0.7
                            )
                        )
                        .scaleEffect(auraScale)
                        .frame(width: geo.size.width * 1.2, height: geo.size.width * 1.2)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.35)
                    
                    Circle()
                        .stroke(gold.opacity(0.2), lineWidth: 1)
                        .frame(width: 240, height: 240)
                        .scaleEffect(auraScale * 1.05)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.35)
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Top Header Pill
                HStack(spacing: 6) {
                    Image(systemName: "sun.horizon.fill")
                        .foregroundColor(gold)
                    Text("BRAHMA MUHURTA AWAKENING • ब्रह्म मुहूर्त")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(gold)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(gold.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(gold.opacity(0.3), lineWidth: 1))
                .padding(.top, 40)
                
                Spacer()
                
                // Big Radiant Time Display
                VStack(spacing: 6) {
                    Text(timeFormatter.string(from: currentTime))
                        .font(.system(size: 64, weight: .light, design: .serif))
                        .foregroundColor(.white)
                        .shadow(color: gold.opacity(0.4), radius: 16)
                    
                    Text("Sunrise Synchronized • \(alarmManager.selectedTarget.rawValue)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(gold.opacity(0.9))
                }
                
                // Sacred Sanskrit Awakening Invocation Card
                VStack(spacing: 12) {
                    Text("उत्तिष्ठोत्तिष्ठ गोविन्द उत्तिष्ठ गरुडध्वज।")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundColor(gold)
                    
                    Text("उत्तिष्ठ कमलाकान्त त्रैलोक्यं मङ्गलं कुरु॥")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundColor(gold)
                    
                    Text("“Awaken into sacred consciousness; greet the rising light with peace and consecrated prana.”")
                        .font(.system(size: 12, design: .serif))
                        .italic()
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(gold.opacity(0.25), lineWidth: 1))
                )
                .padding(.horizontal, 24)
                
                // Sound Engine Ambient Indicator
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .foregroundColor(gold)
                    Text("Playing: \(alarmManager.selectedSoundtrack.shortName)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                Spacer()
                
                // Bottom Interactive Actions: Snooze & Begin Sadhana
                VStack(spacing: 14) {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        alarmManager.stopRingingAlarm()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 17, weight: .bold))
                            Text("Awaken & Begin Sadhana")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(gold)
                        .clipShape(Capsule())
                        .shadow(color: gold.opacity(0.4), radius: 12, y: 4)
                    }
                    
                    if alarmManager.isSnoozeEnabled {
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            alarmManager.snoozeRingingAlarm()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "moon.zzz.fill")
                                Text("Snooze (\(alarmManager.snoozeMinutes) min)")
                            }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                auraScale = 1.15
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                currentTime = Date()
            }
        }
    }
    
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mm:ss a"
        return f
    }
}
