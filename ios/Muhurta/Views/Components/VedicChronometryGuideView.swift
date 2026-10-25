//
//  VedicChronometryGuideView.swift
//  Muhurta
//
//  An inspiring, beginner-friendly interactive masterclass on Vedic Chronometry (Kāla Gaṇanā).
//  Educates users on Kali Yuga 5128, Samvatsaras, Ayanas, Ritus, Tithis, and the Daily Sankalpa.
//

import SwiftUI

public struct VedicChronometryGuideView: View {
    public let chronometry: VedicChronometry
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTopic: ChronometryTopic = .kaliYuga
    
    public enum ChronometryTopic: String, CaseIterable, Identifiable {
        case kaliYuga = "Kali Yuga Era"
        case samvatsara = "60 Jovian Years"
        case ayanaRitu = "Ayana & 6 Ritus"
        case tithi = "Lunar Tithis"
        case sankalpa = "Daily Sankalpa"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .kaliYuga: return "hourglass.bottomhalf.filled"
            case .samvatsara: return "circle.hexagonpath.fill"
            case .ayanaRitu: return "sun.and.horizon.fill"
            case .tithi: return "moon.stars.fill"
            case .sankalpa: return "sparkles"
            }
        }
    }
    
    public init(chronometry: VedicChronometry) {
        self.chronometry = chronometry
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.08)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Cosmic Identity Header
                        cosmicHeaderCard
                        
                        // Topic Selector Horizontal Strip
                        topicSelectorBar
                        
                        // Dynamic Educational Deep-Dive Content
                        switch selectedTopic {
                        case .kaliYuga:
                            kaliYugaGuide
                        case .samvatsara:
                            samvatsaraGuide
                        case .ayanaRitu:
                            ayanaRituGuide
                        case .tithi:
                            tithiGuide
                        case .sankalpa:
                            sankalpaGuide
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Vedic Calendar Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
                }
            }
        }
    }
    
    // MARK: - Cosmic Header Card
    
    private var cosmicHeaderCard: some View {
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("AUTHENTIC VEDIC TIME", systemImage: "sparkles")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(gold)
                Spacer()
                Text("Kāla Gaṇanā (काल गणना)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Year \(chronometry.kaliYugaYear) of Kali Yuga")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("\(chronometry.samvatsaraName) Samvatsara • \(chronometry.masa) • \(chronometry.tithiSanskrit)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(gold)
            }
            
            Text("Unlike the Gregorian calendar, which counts arbitrary solar days from midnight, the Vedic calendar anchors human consciousness directly to the geometry of the Sun, Moon, and cosmos.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
                .lineSpacing(2)
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
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(gold.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Topic Selector
    
    private var topicSelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChronometryTopic.allCases) { topic in
                    let isSelected = selectedTopic == topic
                    let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTopic = topic
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: topic.icon)
                                .font(.system(size: 11))
                            Text(topic.rawValue)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? gold : Color.white.opacity(0.04))
                        .foregroundColor(isSelected ? Color(red: 0.08, green: 0.06, blue: 0.02) : .white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Topic 1: Kali Yuga Era
    
    private var kaliYugaGuide: some View {
        VStack(alignment: .leading, spacing: 14) {
            guideSectionHeader(title: "The Era: Kali Yuga \(chronometry.kaliYugaYear)", subtitle: "Continuous Astronomical Time since 3102 BCE")
            
            guideConceptCard(
                term: "Continuous Year \(chronometry.kaliYugaYear)",
                sanskrit: "कियुगाब्द \(chronometry.kaliYugaYear)",
                description: "According to classical astronomical treatises (Surya Siddhanta and Aryabhata), the Kali Yuga epoch began on midnight of 18 February 3102 BCE at the Ujjain meridian, when all major planets aligned at zero degrees Aries. Rather than political calendar decrees, the Vedic calendar continuously counts unbroken sidereal solar years from this astronomical epoch."
            )
            
            guideConceptCard(
                term: "Vikrama Samvat (\(chronometry.vikramSamvat))",
                sanskrit: "विक्रम संवत् \(chronometry.vikramSamvat)",
                description: "Established in 57 BCE by Emperor Vikramaditya of Ujjain to commemorate the liberation of the Malwa region. Widely used for traditional festivities and lunar calendars across northern and western India."
            )
            
            guideConceptCard(
                term: "Śaka Samvat (\(chronometry.sakaSamvat))",
                sanskrit: "शालिवाहन शक \(chronometry.sakaSamvat)",
                description: "Established in 78 CE by King Shalivahana. It forms the astronomical bedrock of the Indian National Calendar and Panchanga almanacs across the Deccan and southern India."
            )
        }
    }
    
    // MARK: - Topic 2: 60-Year Jovian Cycle
    
    private var samvatsaraGuide: some View {
        VStack(alignment: .leading, spacing: 14) {
            guideSectionHeader(title: "60-Year Jovian Cycle (Samvatsara)", subtitle: "The Harmonic Resonance of Jupiter & Sun")
            
            guideConceptCard(
                term: "Current Year: \(chronometry.samvatsaraName)",
                sanskrit: "\(chronometry.samvatsaraName) संवत्सर (Year \(chronometry.samvatsaraNumber) of 60)",
                description: "Jupiter takes approximately 12 solar years to orbit the Sun. 5 Jupiter cycles equal 60 years. In ancient Vedic astronomy, every single year in this 60-year cycle has a distinct Sanskrit name describing the prevailing mental, energetic, and spiritual atmosphere of the planet."
            )
            
            guideConceptCard(
                term: "Cosmic Resonance",
                sanskrit: "बृहस्पति चक्र",
                description: "The 60-year cycle matches the lowest common multiple of Saturn (30-year orbit) and Jupiter (12-year orbit). Every 60 years, the two master outer planets realign in the same sidereal zodiacal sector, creating a complete societal generational rebirth."
            )
        }
    }
    
    // MARK: - Topic 3: Ayana & 6 Ritus
    
    private var ayanaRituGuide: some View {
        VStack(alignment: .leading, spacing: 14) {
            guideSectionHeader(title: "Ayana & The 6 Vedic Seasons (Ṛtus)", subtitle: "The Solar Breath of the Earth")
            
            guideConceptCard(
                term: chronometry.ayana,
                sanskrit: "दक्षिणायन (July to January)",
                description: chronometry.ayanaMeaning + ". When the Sun travels southward (Dakshinayana), the nights lengthen, cooling the earth. It is designated by Rishis as the Pitru-yana (spiritual window) favored for purification, mantra sadhana, and inward contemplation."
            )
            
            guideConceptCard(
                term: chronometry.ritu,
                sanskrit: "शरद् ऋतु (Autumn Season)",
                description: chronometry.rituMeaning + ". The Vedic system recognizes 6 distinct two-month seasons (Vasanta, Grishma, Varsha, Sharad, Hemanta, Shishira). Sharad Ritu features clear autumn skies and moonlight; Ayurveda recommends pacifying accumulated summer Pitta with cooling hydration and sweet spices."
            )
            
            guideConceptCard(
                term: "Solar Month: \(chronometry.masa)",
                sanskrit: chronometry.masaSanskrit,
                description: chronometry.masaMeaning + ". Defined by the Sun's transit through the sidereal constellation of Tula (Libra)."
            )
        }
    }
    
    // MARK: - Topic 4: Lunar Tithis
    
    private var tithiGuide: some View {
        VStack(alignment: .leading, spacing: 14) {
            guideSectionHeader(title: "Lunar Tithis: The True Vedic Day", subtitle: "The 12-Degree Dance of Sun and Moon")
            
            guideConceptCard(
                term: "Why Tithis Replace Calendar Numbers",
                sanskrit: "तिथि (Lunar Day)",
                description: "A Gregorian day is an arbitrary 24 hours. A Tithi is a living astronomical angle: the exact time taken for the Moon to separate from the Sun by 12 degrees. Because the Moon moves at variable speeds in its elliptical orbit, a Tithi can last anywhere from 19 to 26 hours!"
            )
            
            guideConceptCard(
                term: chronometry.paksha,
                sanskrit: "पक्ष (The Two Fortnights)",
                description: "Each lunar month has two halves: Shukla Paksha (Waxing, 0° to 180° elongation, increasing prana and vitality) and Krishna Paksha (Waning, 180° to 360° elongation, dissolving ego and cultivating deep meditation)."
            )
            
            guideConceptCard(
                term: "Today's Phase: \(chronometry.tithiSanskrit)",
                sanskrit: "तिथि प्रभाव",
                description: chronometry.tithiMeaning
            )
        }
    }
    
    // MARK: - Topic 5: Daily Sankalpa
    
    private var sankalpaGuide: some View {
        let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
        
        return VStack(alignment: .leading, spacing: 14) {
            guideSectionHeader(title: "The Daily Sankalpa", subtitle: "Your Address in Universal Space-Time")
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Traditional Sanskrit Recitation")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(gold)
                
                Text(chronometry.sankalpaSanskrit)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                
                Divider()
                    .overlay(Color.white.opacity(0.1))
                    .padding(.vertical, 4)
                
                Text("Beginner English Meaning")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(gold)
                
                Text(chronometry.sankalpaEnglish)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
            }
            .padding(16)
            .background(Color(red: 0.08, green: 0.09, blue: 0.13))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(gold.opacity(0.25), lineWidth: 1)
            )
        }
    }
    
    // MARK: - UI Helper Cards
    
    private func guideSectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.top, 4)
    }
    
    private func guideConceptCard(term: String, sanskrit: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(term)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(sanskrit)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.94, green: 0.76, blue: 0.42))
            }
            
            Text(description)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }
}
