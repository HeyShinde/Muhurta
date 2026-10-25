//
//  ContentView.swift
//  Muhurta
//
//  Understated, human-crafted navigation container with a sleek, docked glassmorphic tab bar.
//

import SwiftUI

enum SacredTab: Int, CaseIterable {
    case solar = 0
    case panchanga = 1
    case sadhana = 2
    case sounds = 3
    case profile = 4
    
    var title: String {
        switch self {
        case .solar: return "Solar Arc"
        case .panchanga: return "Panchāṅga"
        case .sadhana: return "Sādhana"
        case .sounds: return "Mantras"
        case .profile: return "Profile"
        }
    }
    
    var iconName: String {
        switch self {
        case .solar: return "sun.horizon.fill"
        case .panchanga: return "calendar"
        case .sadhana: return "sparkles"
        case .sounds: return "book.pages.fill"
        case .profile: return "person.crop.circle"
        }
    }
}

struct ContentView: View {
    @Bindable var alarmManager = AlarmManager.shared
    @AppStorage("activeSacredTab_v2") private var activeTabRaw: Int = 0
    @Namespace private var tabNamespace
    
    private var selectedTab: SacredTab {
        SacredTab(rawValue: activeTabRaw) ?? .panchanga
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content Area
            Group {
                switch selectedTab {
                case .solar:
                    SolarDashboardView()
                case .panchanga:
                    MonthlyPanchangaGridView()
                case .sadhana:
                    SadhanaSanctuaryView()
                case .sounds:
                    SoundscapePlayerView()
                case .profile:
                    VedicProfileSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Ultra-modern Floating Glass Island Dock
            floatingGlassDock
                .padding(.horizontal, 20)
                // .padding(.bottom, 2)
        }
        .fullScreenCover(isPresented: $alarmManager.isAlarmRinging) {
            SacredAlarmRingingView()
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea(.keyboard)
    }
    
    private var floatingGlassDock: some View {
        HStack(spacing: 4) {
            ForEach(SacredTab.allCases, id: \.rawValue) { tab in
                let isSelected = selectedTab == tab
                let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        activeTabRaw = tab.rawValue
                    }
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                } label: {
                    ZStack {
                        if isSelected {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            gold.opacity(0.20),
                                            gold.opacity(0.08)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .matchedGeometryEffect(id: "activeTabCapsule", in: tabNamespace)
                                .overlay(
                                    Capsule()
                                        .stroke(gold.opacity(0.35), lineWidth: 1)
                                )
                                .padding(.horizontal, 2)
                        }
                        
                        VStack(spacing: 2) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: isSelected ? 15 : 13.5, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? gold : Color.white.opacity(0.45))
                                .scaleEffect(isSelected ? 1.05 : 1.0)
                            
                            Text(tab.title)
                                .font(.system(size: 9.5, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundColor(isSelected ? .white : Color.white.opacity(0.40))
                        }
                        // .padding(.vertical, 6)
                        .padding(.horizontal, 4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 8)
        // .padding(.vertical, 5)
        .background(
            ZStack {
                // Frosted blur backing
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.13).opacity(0.85))
                    .background(.ultraThinMaterial)
                
                // Fine gold/white rim outline
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color(red: 0.94, green: 0.76, blue: 0.42).opacity(0.12),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Color.black.opacity(0.45), radius: 24, x: 0, y: 12)
    }
}

#Preview {
    ContentView()
}
