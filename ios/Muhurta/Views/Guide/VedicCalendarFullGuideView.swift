//
//  VedicCalendarFullGuideView.swift
//  Muhurta
//
//  Comprehensive, human-crafted educational guide to Vedic Chronometry (काल-विज्ञान).
//  Teaches beginners how the Vedic calendar functions, why it differs from Gregorian midnight,
//  and breaks down the exact mechanics of Sūryodaya, Tithis, Yugas, and Muhurtas.
//

import SwiftUI
import CoreLocation

struct VedicCalendarFullGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: GuideTab = .midnightVsSunrise
    @State private var interactiveTestDate: Date = Date()
    
    private let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
    private let ujjainCoordinate = CLLocationCoordinate2D(latitude: 23.1765, longitude: 75.7885)
    
    enum GuideTab: String, CaseIterable, Identifiable {
        case midnightVsSunrise = "Midnight vs Sunrise"
        case cosmicEpoch = "Kali Yuga 5,128"
        case solarSeasons = "Ayanas & Ṛtus"
        case lunarTithis = "Tithis & Months"
        case muhurtas = "30 Muhurtas"
        case converter = "Sankalpa Tool"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .midnightVsSunrise: return "sun.horizon.fill"
            case .cosmicEpoch: return "globe.badge.chevron.backward"
            case .solarSeasons: return "sun.max.fill"
            case .lunarTithis: return "moon.stars.fill"
            case .muhurtas: return "clock.fill"
            case .converter: return "wand.and.stars"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Tab Bar
                categoryTabBar
                    .padding(.vertical, 8)
                    .background(Color(red: 0.07, green: 0.08, blue: 0.12))
                
                ScrollView {
                    VStack(spacing: 24) {
                        switch selectedTab {
                        case .midnightVsSunrise:
                            midnightVsSunriseSection
                        case .cosmicEpoch:
                            cosmicEpochSection
                        case .solarSeasons:
                            solarSeasonsSection
                        case .lunarTithis:
                            lunarTithisSection
                        case .muhurtas:
                            thirtyMuhurtasSection
                        case .converter:
                            interactiveConverterSection
                        }
                    }
                    .padding(20)
                }
            }
            .background(Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea())
            .toolbarBackground(Color(red: 0.05, green: 0.06, blue: 0.09), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Vedic Calendar Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(gold)
                }
            }
        }
    }
    
    // MARK: - Tab Bar
    
    private var categoryTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GuideTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                        }
                        .foregroundColor(isSelected ? .black : Color.white.opacity(0.65))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSelected ? gold : Color.white.opacity(0.06))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(isSelected ? gold : Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 1. Midnight vs Sunrise Section
    
    private var midnightVsSunriseSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            guideHeroHeader(
                title: "12:00 AM Midnight vs Sūryodaya (Sunrise)",
                subtitle: "The Astronomical Truth of Biological Time",
                icon: "sun.horizon.fill"
            )
            
            // Core Philosophy Card
            cardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    Text("The Fundamental Clock Divergence")
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    HStack(alignment: .top, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "clock.badge.xmark")
                                    .foregroundColor(.red)
                                Text("Gregorian Midnight")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Text("Artificial civil convention. The calendar day arbitrarily increments at 12:00:00 AM while nature sleeps in deep darkness. It ignores solar position, lunar gravity, and human endocrinology.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.65))
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "sunrise.fill")
                                    .foregroundColor(gold)
                                Text("Vedic Sūryodaya")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(gold)
                            }
                            Text("Biological & astronomical reality. The Vedic day (Ahorātra) strictly begins when the upper limb of the Sun touches the eastern horizon, activating photosynthesis, cortisol, and prāṇic currents.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.65))
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            // What is Rātri-Śeṣa?
            cardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.95))
                        Text("What happens between 12:00 AM and Sunrise?")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("In Vedic astronomy, the hours between midnight and sunrise (e.g. 12:00 AM – 6:30 AM) are called **Rātri-Śeṣa (रात्रि-शेष)** — the concluding quarter of yesterday's night. Even though a digital smartphone flips to 'Sunday' at 12:01 AM, **in cosmic reality it is still Saturday until the Sun actually rises**.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                        .lineSpacing(4)
                }
            }
        }
    }
    
    // MARK: - 2. Cosmic Epoch (Kali Yuga)
    
    private var cosmicEpochSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            guideHeroHeader(
                title: "The Kali Yuga Clock (Year 5,128)",
                subtitle: "How the True Vedic Year is Derived",
                icon: "globe.badge.chevron.backward"
            )
            
            cardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    Text("The Astronomical Epoch: 3102 BCE")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("The current Kali Yuga epoch began on **February 18, 3102 BCE at midnight** (0° longitude of Ujjain, the Greenwich of ancient Vedic astronomy). At this exact moment, all seven traditional celestial bodies (Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn) formed a conjunction at 0° sidereal Aries (Revatī-Aśvinī junction) as Lord Krishna concluded his earthly līlā.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                        .lineSpacing(4)
                    
                    HStack(spacing: 12) {
                        statPill(label: "CURRENT YEAR", value: "5,128")
                        statPill(label: "DURATION", value: "432,000y")
                        statPill(label: "PHASE", value: "1st Sandhyā")
                    }
                    .padding(.top, 4)
                }
            }
            
            cardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    Text("The 60-Year Jovian Cycle (Samvatsaras)")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("Jupiter (Bṛhaspati) takes ~11.86 solar years to traverse the 12 zodiac signs. Five Jovian revolutions create a grand **60-year Samvatsara cycle**, where each year possesses a unique Sanskrit name, presiding deity, and psychological climate. The current Vedic year is **Parābhava (पराभव)**.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                        .lineSpacing(4)
                }
            }
        }
    }
    
    // MARK: - 3. Solar Seasons (Ayanas & Ritus)
    
    private var solarSeasonsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            guideHeroHeader(
                title: "Solar Dynamics: Ayanas & 6 Ṛtus",
                subtitle: "Synchronizing Circadian Rhythms with the Sun",
                icon: "sun.max.fill"
            )
            
            cardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    Text("The Two Cosmic Solstitial Paths (Ayanas)")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Text("1.")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(gold)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Uttarāyaṇa (उत्तरायण) • Northern Climb")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Begins at Makar Sankranti (Jan 14/15). Known as Devayāna (the path of gods). Daylight increases, vitality expands, ideal for initiation, marriage, and outward creation.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.65))
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        HStack(alignment: .top, spacing: 10) {
                            Text("2.")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.94, green: 0.45, blue: 0.55))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dakṣiṇāyana (दक्षिणायन) • Southern Descent")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Begins at Karka Sankranti (July 16). Known as Pitṛyāna (ancestral path). Nights lengthen, prāna turns inward, ideal for tapas, sadhana, meditation, and introspection.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.65))
                            }
                        }
                    }
                }
            }
            
            cardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    Text("The Six Vedic Seasons (Ṣaḍ-Ṛtavaḥ)")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    let ritus = [
                        ("Vasanta (वसन्त)", "Spring", "Kapha liquefies; practice cleansing & fasting"),
                        ("Grīṣma (ग्रीष्म)", "Summer", "Pitta increases; cool hydration, sweet fruits"),
                        ("Varṣā (वर्षा)", "Monsoon", "Vata aggravates; warm spices, avoid raw cold foods"),
                        ("Śarat (शरद्)", "Autumn", "Pitta purges; moon bathing, ghee, spiritual stillness"),
                        ("Hemanta (हेमन्त)", "Pre-Winter", "Agni burns highest; hearty nourishing grains, sesame oil"),
                        ("Śiśira (शिशिर)", "Late Winter", "Preserve warmth; warm herbal decoctions, grounding sadhana")
                    ]
                    
                    VStack(spacing: 8) {
                        ForEach(ritus, id: \.0) { r in
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(r.0)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(gold)
                                    Text(r.1)
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                Spacer()
                                Text(r.2)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 4. Lunar Tithis & Year Boundary
    
    private var lunarTithisSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            guideHeroHeader(
                title: "Lunar Architecture: Tithis & Month Rollover",
                subtitle: "How the Year Strictly Ends on Phālguna Amāvāsyā",
                icon: "moon.stars.fill"
            )
            
            cardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    Text("The Mathematical Definition of a Tithi")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("A Tithi is not a fixed 24-hour day. It is the precise time during which the angular separation between the Moon and Sun increases by **12 degrees**:")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                    
                    Text("Tithi Number = ⌊(Moon Longitude - Sun Longitude) / 12°⌋ + 1")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(gold)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    
                    Text("Because the Moon moves faster at perigee and slower at apogee, a Tithi can vary between 19 and 26 hours. The Tithi prevailing at **local sunrise** becomes the Udaya Tithi for the entire civil day.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.65))
                        .lineSpacing(3)
                }
            }
            
            cardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    Text("When Does the Vedic Year Actually End?")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("• The Vedic year does **NOT** end on December 31st or an arbitrary date in April.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                    
                    Text("• Under the authentic astronomical **Amanta system**, the year concludes on **Phālguna Amāvāsyā (फाल्गुन अमावास्या)** — the New Moon in sidereal Pisces (Mīna rāśi).")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                        .lineSpacing(3)
                    
                    Text("• The new Vedic year begins with dawn on **Caitra Śukla Pratipadā (चैत्र शुक्ल प्रतिपदा)** — celebrated across India as Ugadi, Gudi Padwa, and Navaratri. From January through March, the Vedic year strictly remains in the current Kali Yuga year (5,128).")
                        .font(.system(size: 13))
                        .foregroundColor(gold.opacity(0.9))
                        .lineSpacing(3)
                }
            }
            
            cardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Adhika Māsa: The Leap Month of the Cosmos")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("A lunar year is ~354 days, while a solar year is ~365.25 days (a difference of ~11 days each year). Every **32.5 months**, the Vedic calendar adds an intercalary **Adhika Māsa (अधिक मास - Puruṣottama Māsa)**. This guarantees that festivals and seasons remain synchronized with solar astronomy for millennia without drifting.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                        .lineSpacing(4)
                }
            }
        }
    }
    
    // MARK: - 5. Thirty Muhurtas
    
    private var thirtyMuhurtasSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            guideHeroHeader(
                title: "The 30 Muhurtas of the Day",
                subtitle: "Structuring Human Life in 48-Minute Celestial Windows",
                icon: "clock.fill"
            )
            
            cardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Circadian Precision in Ancient Times")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("One full day and night (Ahorātra) is divided into **30 Muhurtas** (15 during daylight, 15 during night). Each Muhurta is approximately **48 minutes** long, expanding and contracting proportionally with the seasonal length of day and night.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                        .lineSpacing(4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        muhurtaHighlightRow(
                            name: "14th Muhurta: Brahma (ब्रह्म)",
                            time: "96 to 48 min before sunrise",
                            desc: "Peak nascent oxygen & pineal melatonin; highest spiritual lucidity for meditation and awakening."
                        )
                        muhurtaHighlightRow(
                            name: "15th Muhurta: Samudra / Ushas (समुद्र)",
                            time: "48 to 0 min before sunrise",
                            desc: "Golden pre-dawn civil twilight; gratitude, contemplation, and Gayatri chanting."
                        )
                        muhurtaHighlightRow(
                            name: "8th Day Muhurta: Abhijit (अभिजित्)",
                            time: "Solar Noon (~11:48 AM – 12:35 PM)",
                            desc: "Sun at its supreme zenith; cancels all negative planetary doshas and blesses new endeavors."
                        )
                    }
                    .padding(.top, 6)
                }
            }
        }
    }
    
    // MARK: - 6. Interactive Sankalpa Converter
    
    private var interactiveConverterSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            guideHeroHeader(
                title: "Vedic Coordinate & Sankalpa Converter",
                subtitle: "Discover the Cosmic Coordinates of Any Date",
                icon: "wand.and.stars"
            )
            
            cardContainer {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Select Any Date & Time")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    
                    DatePicker(
                        "Test Date",
                        selection: $interactiveTestDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .colorScheme(.dark)
                    .padding(10)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    
                    let chrono = PanchangaEngine.calculateChronometry(for: interactiveTestDate, coordinate: ujjainCoordinate)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("COSMIC CHRONOMETRY ADDRESS")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(gold)
                        
                        Text("Kali Yuga Year \(chrono.kaliYugaYear) • \(chrono.samvatsaraName) Samvatsara")
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        
                        Text("\(chrono.ayana) • \(chrono.ritu) • \(chrono.masa) • \(chrono.tithiSanskrit)")
                            .font(.system(size: 13))
                            .foregroundColor(gold.opacity(0.9))
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        Text("PERSONAL SANKALPA RECITATION:")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.5))
                        
                        Text(chrono.sankalpaSanskrit)
                            .font(.system(size: 12, design: .serif))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(10)
                    }
                    .padding(14)
                    .background(Color(red: 0.10, green: 0.11, blue: 0.16))
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(gold.opacity(0.3), lineWidth: 1))
                }
            }
        }
    }
    
    // MARK: - Helper UI Components
    
    private func guideHeroHeader(title: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(gold)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.white)
            }
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(gold.opacity(0.8))
        }
        .padding(.horizontal, 4)
    }
    
    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }
    
    private func statPill(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.5))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(gold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
    
    private func muhurtaHighlightRow(name: String, time: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(gold)
                Spacer()
                Text(time)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
            Text(desc)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}
