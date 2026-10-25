//
//  MuhurtaEngine.swift
//  Muhurta
//
//  The Core Solar & Vedic Calculation Engine.
//  Coordinates astronomical ephemeris with the 15 daily and 15 nightly Muhurtas.
//

import Foundation
import CoreLocation

public struct MuhurtaSnapshot: Sendable {
    public let timestamp: Date
    public let coordinate: CLLocationCoordinate2D
    public let solarTimes: SolarTimes
    public let solarPosition: SolarPosition
    
    // Core Sacred Windows
    public let brahmaMuhurta: MuhurtaPeriod
    public let dawnSandhya: MuhurtaPeriod
    public let abhijitMuhurta: MuhurtaPeriod
    public let duskSandhya: MuhurtaPeriod
    
    // Pre-Dawn Brahma Muhurta of this calendar day's morning (e.g. Oct 25 04:33 - 05:22)
    public let preDawnBrahmaMuhurta: MuhurtaPeriod
    
    // All 30 Muhurtas of the Ahoratra
    public let allMuhurtas: [MuhurtaPeriod]
    
    // Current Active States
    public let currentMuhurta: MuhurtaPeriod?
    public let currentDosha: Dosha
    public let currentDoshaWindow: DoshaWindow
    
    public var isBrahmaMuhurtaActive: Bool {
        brahmaMuhurta.contains(date: timestamp) || preDawnBrahmaMuhurta.contains(date: timestamp)
    }
    
    public var isAbhijitActive: Bool {
        abhijitMuhurta.contains(date: timestamp)
    }
    
    public var timeUntilBrahmaMuhurta: TimeInterval {
        if isBrahmaMuhurtaActive {
            return 0
        }
        return brahmaMuhurta.startTime.timeIntervalSince(timestamp)
    }
}

// MARK: - Calculation Methodology

public enum MuhurtaCalculationMethod: String, CaseIterable, Identifiable, Sendable {
    case astronomical = "Astronomical (Rātri-Māna)"
    case fixedStandard = "Classic 48-Min (Smriti)"
    
    public var id: String { rawValue }
    
    public var shortTitle: String {
        switch self {
        case .astronomical: return "Astronomical"
        case .fixedStandard: return "Classic 48m"
        }
    }
}

public enum MuhurtaEngine {
    
    // MARK: - Public Calculation Engine
    
    public static func calculateSnapshot(
        at date: Date = Date(),
        coordinate: CLLocationCoordinate2D,
        method: MuhurtaCalculationMethod = .astronomical
    ) -> MuhurtaSnapshot? {
        guard let todaySolar = SolarCalculator.calculateSolarTimes(for: date, coordinate: coordinate) else {
            return nil
        }
        
        let position = SolarCalculator.calculatePosition(at: date, coordinate: coordinate)
        
        var calendar = Calendar.current
        calendar.timeZone = .current
        
        let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        
        let yesterdaySolar = SolarCalculator.calculateSolarTimes(for: yesterdayDate, coordinate: coordinate)
        let tomorrowSolar = SolarCalculator.calculateSolarTimes(for: tomorrowDate, coordinate: coordinate)
        
        // 1. Pre-Dawn Brahma Muhurta of this calendar date's morning
        let preDawnSunset = yesterdaySolar?.sunset ?? todaySolar.sunrise.addingTimeInterval(-43200)
        let preDawnNightDuration = todaySolar.sunrise.timeIntervalSince(preDawnSunset)
        
        // 2. Daytime duration: from sunrise to sunset of today
        let dayDuration = todaySolar.dayDuration
        
        // 3. Night duration: from today's sunset to tomorrow's sunrise
        let nextSunrise = tomorrowSolar?.sunrise ?? todaySolar.sunset.addingTimeInterval(43200)
        let nightDuration = nextSunrise.timeIntervalSince(todaySolar.sunset)
        
        // Determine Muhurta lengths based on methodology:
        let preDawnMuhurtaDuration: TimeInterval
        let dayMuhurtaDuration: TimeInterval
        let nightMuhurtaDuration: TimeInterval
        
        switch method {
        case .astronomical:
            preDawnMuhurtaDuration = preDawnNightDuration / 15.0
            dayMuhurtaDuration = dayDuration / 15.0
            nightMuhurtaDuration = nightDuration / 15.0
        case .fixedStandard:
            preDawnMuhurtaDuration = 48.0 * 60.0
            dayMuhurtaDuration = 48.0 * 60.0
            nightMuhurtaDuration = 48.0 * 60.0
        }
        
        let preDawnBrahmaStart = todaySolar.sunrise.addingTimeInterval(-2.0 * preDawnMuhurtaDuration)
        let preDawnBrahmaEnd = todaySolar.sunrise.addingTimeInterval(-1.0 * preDawnMuhurtaDuration)
        let preDawnBrahma = MuhurtaPeriod(
            id: "pre_dawn_brahma",
            index: 14,
            isDaytime: false,
            nameSanskrit: "Brahma Muhurta (ब्रह्म मुहूर्त)",
            nameEnglish: "The Creator's Hour",
            deity: "Brahma",
            quality: .sacred,
            description: "Peak stillness, high intuitive clarity, and sublime spiritual receptivity. The mind is undisturbed by worldly turbulence.",
            startTime: preDawnBrahmaStart,
            endTime: preDawnBrahmaEnd
        )
        
        // Next Night's Brahma Muhurta (occurs in pre-dawn of tomorrow morning)
        let nextBrahmaStart = nextSunrise.addingTimeInterval(-2.0 * nightMuhurtaDuration)
        let nextBrahmaEnd = nextSunrise.addingTimeInterval(-1.0 * nightMuhurtaDuration)
        let nextBrahma = MuhurtaPeriod(
            id: "next_brahma_muhurta",
            index: 14,
            isDaytime: false,
            nameSanskrit: "Brahma Muhurta (ब्रह्म मुहूर्त)",
            nameEnglish: "The Creator's Hour",
            deity: "Brahma",
            quality: .sacred,
            description: "Peak stillness, high intuitive clarity, and sublime spiritual receptivity. The mind is undisturbed by worldly turbulence.",
            startTime: nextBrahmaStart,
            endTime: nextBrahmaEnd
        )
        
        // Active Brahma Muhurta anchor:
        // If current time is before today's sunrise (e.g. 02:00 AM or 04:35 AM), the active/relevant Brahma Muhurta is today morning's preDawnBrahma!
        // If after today's sunrise, the upcoming one is nextBrahma!
        let brahmaMuhurta = (date < todaySolar.sunrise) ? preDawnBrahma : nextBrahma
        
        // 4. Dawn Sandhya
        let dawnSandhya = MuhurtaPeriod(
            id: "dawn_sandhya",
            index: 15,
            isDaytime: false,
            nameSanskrit: "Pratah Sandhya / Ushas (उषस्)",
            nameEnglish: "The Dawn Twilight Junction",
            deity: "Varuna & Mitra",
            quality: .sacred,
            description: "Sacred transition from darkness to radiant light. Traditional time for Gayatri Mantra, Pranayama, and Surya worship.",
            startTime: (date < todaySolar.sunrise) ? preDawnBrahmaEnd : nextBrahmaEnd,
            endTime: (date < todaySolar.sunrise) ? todaySolar.sunrise : nextSunrise
        )
        
        // 5. Abhijit Muhurta: 8th Muhurta of the daytime (spanning solar noon)
        let abhijitStart = todaySolar.sunrise.addingTimeInterval(7.0 * dayMuhurtaDuration)
        let abhijitEnd = todaySolar.sunrise.addingTimeInterval(8.0 * dayMuhurtaDuration)
        let abhijitMuhurta = MuhurtaPeriod(
            id: "abhijit_muhurta",
            index: 8,
            isDaytime: true,
            nameSanskrit: "Abhijit Muhurta (अभिजित्)",
            nameEnglish: "The Victorious Hour",
            deity: "Hari / Vishnu",
            quality: .sacred,
            description: "The most auspicious daytime window. Eliminates all inauspicious astrological doshas and grants focus and victory.",
            startTime: abhijitStart,
            endTime: abhijitEnd
        )
        
        // 6. Dusk Sandhya (Sayana Sandhya): 1st Muhurta of the night right after sunset
        let duskSandhyaEnd = todaySolar.sunset.addingTimeInterval(nightMuhurtaDuration)
        let duskSandhya = MuhurtaPeriod(
            id: "dusk_sandhya",
            index: 1,
            isDaytime: false,
            nameSanskrit: "Sayam Sandhya (सायं सन्ध्या)",
            nameEnglish: "The Evening Twilight Junction",
            deity: "Shiva",
            quality: .auspicious,
            description: "The cosmic threshold between active labor and restful contemplation. Ideal for evening dhyana and lamp lighting.",
            startTime: todaySolar.sunset,
            endTime: duskSandhyaEnd
        )
        
        // 7. Generate all 30 Muhurtas for this Vedic Ahoratra (Sūryodayāt Sūryodaya):
        // If current time is before today's sunrise, we are in the night-phase (rātri-śeṣa) of yesterday's Ahoratra!
        let allMuhurtas: [MuhurtaPeriod]
        let currentMuhurta: MuhurtaPeriod?
        
        if date < todaySolar.sunrise {
            let prevSunrise = yesterdaySolar?.sunrise ?? todaySolar.sunrise.addingTimeInterval(-86400)
            let prevDayMuhurtaDuration = (preDawnSunset.timeIntervalSince(prevSunrise)) / 15.0
            let ongoingMuhurtas = generateAllMuhurtas(
                sunrise: prevSunrise,
                sunset: preDawnSunset,
                nextSunrise: todaySolar.sunrise,
                dayMuhurtaDuration: prevDayMuhurtaDuration,
                nightMuhurtaDuration: preDawnMuhurtaDuration
            )
            allMuhurtas = ongoingMuhurtas
            currentMuhurta = ongoingMuhurtas.first { $0.contains(date: date) }
        } else {
            let upcomingMuhurtas = generateAllMuhurtas(
                sunrise: todaySolar.sunrise,
                sunset: todaySolar.sunset,
                nextSunrise: nextSunrise,
                dayMuhurtaDuration: dayMuhurtaDuration,
                nightMuhurtaDuration: nightMuhurtaDuration
            )
            allMuhurtas = upcomingMuhurtas
            currentMuhurta = upcomingMuhurtas.first { $0.contains(date: date) }
        }
        
        let (currentDosha, currentDoshaWindow) = calculateDosha(for: date)
        
        return MuhurtaSnapshot(
            timestamp: date,
            coordinate: coordinate,
            solarTimes: todaySolar,
            solarPosition: position,
            brahmaMuhurta: brahmaMuhurta,
            dawnSandhya: dawnSandhya,
            abhijitMuhurta: abhijitMuhurta,
            duskSandhya: duskSandhya,
            preDawnBrahmaMuhurta: preDawnBrahma,
            allMuhurtas: allMuhurtas,
            currentMuhurta: currentMuhurta,
            currentDosha: currentDosha,
            currentDoshaWindow: currentDoshaWindow
        )
    }
    
    // MARK: - Dosha Biological Clock
    
    public static func calculateDosha(for date: Date = Date()) -> (Dosha, DoshaWindow) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        switch hour {
        case 2..<6:
            return (.vata, DoshaWindow(
                dosha: .vata,
                label: "Dawn Vata Phase (02:00 – 06:00)",
                startHour: 2,
                endHour: 6,
                activityRecommendation: "Peak mental clarity and spiritual awakening. Ideal for meditation, sacred chanting, and waking with lightness."
            ))
        case 6..<10:
            return (.kapha, DoshaWindow(
                dosha: .kapha,
                label: "Morning Kapha Phase (06:00 – 10:00)",
                startHour: 6,
                endHour: 10,
                activityRecommendation: "Heavy, stable physical stamina. Optimal time for rigorous exercise, Surya Namaskar, and dynamic movement."
            ))
        case 10..<14:
            return (.pitta, DoshaWindow(
                dosha: .pitta,
                label: "Midday Pitta Phase (10:00 – 14:00)",
                startHour: 10,
                endHour: 14,
                activityRecommendation: "Peak digestive fire (Jatharagni) and analytical drive. Best for your largest meal and complex cognitive work."
            ))
        case 14..<18:
            return (.vata, DoshaWindow(
                dosha: .vata,
                label: "Afternoon Vata Phase (14:00 – 18:00)",
                startHour: 14,
                endHour: 18,
                activityRecommendation: "Creative synthesis, communication, and agile thinking. Keep warm and hydrate with herbal teas."
            ))
        case 18..<22:
            return (.kapha, DoshaWindow(
                dosha: .kapha,
                label: "Evening Kapha Phase (18:00 – 22:00)",
                startHour: 18,
                endHour: 22,
                activityRecommendation: "Natural melatonin onset, winding down, and grounding. Eat a light dinner, dim bright screens, and prepare for restful sleep."
            ))
        default: // 22:00 to 02:00
            return (.pitta, DoshaWindow(
                dosha: .pitta,
                label: "Midnight Pitta Phase (22:00 – 02:00)",
                startHour: 22,
                endHour: 2,
                activityRecommendation: "Internal cellular repair and liver detoxification. Deep sleep during this phase is vital for rejuvenation."
            ))
        }
    }
    
    // MARK: - Internal 30 Muhurta Generator
    
    private static func generateAllMuhurtas(
        sunrise: Date,
        sunset: Date,
        nextSunrise: Date,
        dayMuhurtaDuration: TimeInterval,
        nightMuhurtaDuration: TimeInterval
    ) -> [MuhurtaPeriod] {
        var result: [MuhurtaPeriod] = []
        
        // 15 Daytime Muhurtas
        let dayDefs: [(sanskrit: String, english: String, deity: String, quality: MuhurtaQuality, desc: String)] = [
            ("Rudra (रुद्र)", "Fierce Surge", "Rudra", .inauspicious, "Turbulent energy; avoid commencing delicate endeavors."),
            ("Ahi / Sarpa (अहि)", "Serpent Wisdom", "Sarpa", .inauspicious, "Introspective but intense; caution advised in new undertakings."),
            ("Mitra (मित्र)", "Radiant Friendship", "Mitra", .auspicious, "Harmony, alliance, and cooperative ventures flourish."),
            ("Pitru (पितृ)", "Ancestral Memory", "Pitaras", .inauspicious, "Dedicated to remembering roots; pause material expansions."),
            ("Vasu (वसु)", "Material Blessing", "Vasus", .auspicious, "Prosperity, foundation laying, and trade blessings."),
            ("Varaha (वराह)", "Steadfast Grounding", "Varaha", .auspicious, "Strength, overcoming obstacles, and establishing order."),
            ("Vishwadeva (विश्वेदेव)", "Universal Concord", "Vishwadevas", .auspicious, "High collective harmony and learning."),
            ("Abhijit (अभिजित्)", "The Victorious Noon", "Vishnu", .sacred, "Supreme clarity. Neutralizes adversities; optimal for victory."),
            ("Vidhi / Brahma (विधि)", "Creative Architect", "Brahma", .auspicious, "Design, planning, writing, and creative construction."),
            ("Indra (इन्द्र)", "Sovereign Might", "Indra", .auspicious, "Leadership, public addresses, and decisive execution."),
            ("Indrani (इन्द्राणी)", "Graceful Poise", "Indrani", .auspicious, "Aesthetic pursuits, artistic creation, and social grace."),
            ("Varuna (वरुण)", "Deep Wisdom", "Varuna", .auspicious, "Philosophical study, water rituals, and truthful inquiry."),
            ("Aryama (अर्यमा)", "Noble Integrity", "Aryama", .auspicious, "Charity, community welfare, and noble covenants."),
            ("Bhaga (भग)", "Sensory Passion", "Bhaga", .inauspicious, "Prone to restless desires; maintain disciplined composure."),
            ("Girisha (गिरीश)", "Pinnacle Stillness", "Shiva", .auspicious, "Calm reflection as daylight fades toward twilight.")
        ]
        
        for i in 0..<15 {
            let start = sunrise.addingTimeInterval(Double(i) * dayMuhurtaDuration)
            let end = sunrise.addingTimeInterval(Double(i + 1) * dayMuhurtaDuration)
            let def = dayDefs[i]
            result.append(MuhurtaPeriod(
                id: "day_\(i + 1)",
                index: i + 1,
                isDaytime: true,
                nameSanskrit: def.sanskrit,
                nameEnglish: def.english,
                deity: def.deity,
                quality: def.quality,
                description: def.desc,
                startTime: start,
                endTime: end
            ))
        }
        
        // 15 Nighttime Muhurtas
        let nightDefs: [(sanskrit: String, english: String, deity: String, quality: MuhurtaQuality, desc: String)] = [
            ("Shiva / Sandhya (शिव)", "Dusk Dissolution", "Shiva", .auspicious, "Quiet twilight contemplation and lamp lighting."),
            ("Ajapada (अजपाद)", "Ascetic Flame", "Aja Ekapada", .inauspicious, "Deep nocturnal austerity; restfulness recommended."),
            ("Ahirbudhnya (अहिर्बुध्न्य)", "Abyssal Wisdom", "Ahirbudhnya", .auspicious, "Kundalini contemplation and restful inwardness."),
            ("Pushan (पूषन्)", "Nurturing Guide", "Pushan", .auspicious, "Peaceful nourishment and gentle evening companionship."),
            ("Ashwini (अश्विनी)", "Twin Healers", "Ashwins", .auspicious, "Cellular restoration and restorative sleep."),
            ("Yama (यम)", "Law of Nature", "Yama", .inauspicious, "Disciplined withdrawal; keep sleep environment quiet."),
            ("Agni (अग्नि)", "Sacred Hearth", "Agni", .auspicious, "Internal metabolic assimilation; deep rest."),
            ("Vidhata (विधाता)", "Ordainer", "Vidhata", .auspicious, "Subconscious processing and dream integration."),
            ("Kanda / Chanda (कण्ड)", "Intense Veil", "Chanda", .inauspicious, "Late night darkness; preserve tranquil slumber."),
            ("Aditi (अदिति)", "Boundless Space", "Aditi", .auspicious, "Cosmic mother; deep peaceful slumber."),
            ("Jiva (जीव)", "Wisdom of Guru", "Brihaspati", .auspicious, "Higher spiritual intuition gently awakening."),
            ("Vishnu (विष्णु)", "All-Pervading Life", "Vishnu", .sacred, "Sustaining peace; prelude to pre-dawn stillness."),
            ("Dyumani (द्युमणि)", "Luminous Glow", "Surya", .auspicious, "The first subtle thinning of the cosmic dark."),
            ("Brahma (ब्रह्म मुहूर्त)", "The Creator's Hour", "Brahma", .sacred, "Peak sattvic dawn frequency. Perfect for meditation and awakening."),
            ("Samudra / Ushas (समुद्र)", "The Radiant Shore", "Ushas", .sacred, "The physical dawn breaks over the horizon.")
        ]
        
        for i in 0..<15 {
            let start = sunset.addingTimeInterval(Double(i) * nightMuhurtaDuration)
            let end = sunset.addingTimeInterval(Double(i + 1) * nightMuhurtaDuration)
            let def = nightDefs[i]
            result.append(MuhurtaPeriod(
                id: "night_\(i + 1)",
                index: i + 1,
                isDaytime: false,
                nameSanskrit: def.sanskrit,
                nameEnglish: def.english,
                deity: def.deity,
                quality: def.quality,
                description: def.desc,
                startTime: start,
                endTime: end
            ))
        }
        
        return result
    }
}
