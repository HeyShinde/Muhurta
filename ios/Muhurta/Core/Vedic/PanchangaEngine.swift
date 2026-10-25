//
//  PanchangaEngine.swift
//  Muhurta
//
//  Vedic Chronometry & Ephemeris Engine.
//  Computes Rahu Kalam, Yamaganda, Gulika Kalam, Abhijit,
//  and the core limbs of Vedic Panchanga (Vāra, Tithi, Nakshatra, Yoga).
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Action Window Types

public enum ActionWindowType: String, Sendable {
    case abhijit = "Abhijit Muhurta"
    case rahuKalam = "Rahu Kalam"
    case yamaganda = "Yamaganda"
    case gulika = "Gulika Kalam"
    
    public var sanskritName: String {
        switch self {
        case .abhijit: return "अभिजित् मुहूर्त"
        case .rahuKalam: return "राहु काल"
        case .yamaganda: return "यमगण्ड"
        case .gulika: return "गुलिक काल"
        }
    }
    
    public var isAuspicious: Bool {
        switch self {
        case .abhijit: return true
        case .rahuKalam, .yamaganda: return false
        case .gulika: return false
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .abhijit: return Color(red: 0.40, green: 0.82, blue: 0.60) // Emerald
        case .rahuKalam: return Color(red: 0.94, green: 0.42, blue: 0.42) // Coral Red
        case .yamaganda: return Color(red: 0.96, green: 0.62, blue: 0.32) // Amber Orange
        case .gulika: return Color(red: 0.65, green: 0.55, blue: 0.88) // Purple Lavender
        }
    }
    
    public var description: String {
        switch self {
        case .abhijit:
            return "Supreme midday window spanning solar noon. Cancels all doshas; ideal for beginning vital tasks, meetings, and journeys."
        case .rahuKalam:
            return "Governed by Rahu. Heavy tamasic friction; avoid inaugurations, financial investments, purchasing assets, or signing contracts."
        case .yamaganda:
            return "Governed by Yama (Lord of obstacles). Undertakings commenced during Yamaganda face unexpected hurdles or delays."
        case .gulika:
            return "Governed by Gulika (son of Saturn). Favorable for spiritual penance, meditation, and repetitive tasks; avoid initiating new journeys."
        }
    }
}

public struct ActionWindow: Identifiable, Sendable {
    public var id: String { type.rawValue }
    public let type: ActionWindowType
    public let start: Date
    public let end: Date
    
    public func contains(date: Date) -> Bool {
        date >= start && date <= end
    }
    
    public var formattedRange: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: start)) – \(f.string(from: end))"
    }
    
    public var durationMinutes: Int {
        max(1, Int(end.timeIntervalSince(start) / 60.0))
    }
}

public struct VedicActionWindows: Sendable {
    public let abhijit: ActionWindow
    public let rahuKalam: ActionWindow
    public let yamaganda: ActionWindow
    public let gulika: ActionWindow
    
    public var allWindows: [ActionWindow] {
        [abhijit, rahuKalam, yamaganda, gulika]
    }
    
    public func activeWindow(at date: Date) -> ActionWindow? {
        allWindows.first { $0.contains(date: date) }
    }
}

// MARK: - Panchanga Types

public struct VedicVara: Sendable {
    public let weekdayNumber: Int // 1 = Sunday ... 7 = Saturday
    public let nameSanskrit: String
    public let nameEnglish: String
    public let rulingGraha: String
    public let element: String
    public let deity: String
    public let essence: String
}

public struct VedicChronometry: Sendable, Identifiable {
    public var id: String { "\(kaliYugaYear)_\(masa)_\(paksha)_\(tithiName)" }
    
    // Core Cosmic Eras
    public let kaliYugaYear: Int           // e.g. 5128 (कियुगाब्द)
    public let vikramSamvat: Int           // e.g. 2083 (विक्रम संवत्)
    public let sakaSamvat: Int             // e.g. 1948 (शालिवाहन शक)
    public let samvatsaraName: String      // e.g. "Parābhava (पराभव)"
    public let samvatsaraNumber: Int       // 40
    
    // Solar & Seasonal Cycles
    public let ayana: String               // e.g. "Dakṣiṇāyana (दक्षिणायन)"
    public let ayanaMeaning: String        // "Southern Solar Arc: Sadhana, Inner Purification & Receptivity"
    public let ritu: String                // e.g. "Śarat Ṛtu (शरद् ऋतु)"
    public let rituMeaning: String         // "Autumn: Pitta balance, luminous moonlit nights & spiritual clarity"
    public let masa: String                // e.g. "Āśvina (आश्विन)"
    public let masaSanskrit: String        // "आश्विन मास"
    public let masaMeaning: String         // "Month of spiritual illumination, inner victory and Navarātri"
    
    // Lunar Coordinates
    public let paksha: String              // e.g. "Śukla Pakṣa (शुक्ल पक्ष)"
    public let tithiName: String           // e.g. "Caturdaśī"
    public let tithiSanskrit: String       // e.g. "चतुर्दशी"
    public let tithiShort: String          // e.g. "चतुर्दशी" or short abbreviation
    public let tithiNumber: Int            // 14
    public let tithiMeaning: String        // "14th lunar phase: Dissolution of past impressions and preparation for fullness"
    
    // Traditional Daily Sankalpa
    public let sankalpaSanskrit: String
    public let sankalpaEnglish: String
    
    public var shortCosmicAddress: String {
        "Kali Yuga \(kaliYugaYear) • \(samvatsaraName) • \(masa) \(tithiSanskrit)"
    }
    
    public static var sample: VedicChronometry {
        let ujjain = CLLocationCoordinate2D(latitude: 23.1765, longitude: 75.7885)
        if let p = PanchangaEngine.calculatePanchanga(for: Date(), coordinate: ujjain) {
            return p.chronometry
        }
        let jd = Date().timeIntervalSince1970 / 86400.0 + 2440587.5
        let kaliEpochJD = 588465.5
        let kaliAhargana = max(0.0, jd - kaliEpochJD)
        let siderealYearLength = 365.256363004
        let kaliYear = Int(kaliAhargana / siderealYearLength) + 1
        let vikramYear = kaliYear - 3045
        let sakaYear = kaliYear - 3180
        let samvatsaraIdx = ((sakaYear + 11) % 60 + 60) % 60
        let samvatsaraName = PanchangaEngine.getSamvatsaraName(for: samvatsaraIdx)
        return VedicChronometry(
            kaliYugaYear: kaliYear,
            vikramSamvat: vikramYear,
            sakaSamvat: sakaYear,
            samvatsaraName: samvatsaraName,
            samvatsaraNumber: samvatsaraIdx + 1,
            ayana: "Dakṣiṇāyana (दक्षिणायन)",
            ayanaMeaning: "Southern Solar Arc: Inner Purification & Sadhana",
            ritu: "Śarat Ṛtu (शरद् ऋतु)",
            rituMeaning: "Autumn: Pitta balance, luminous clarity & reflection",
            masa: "Kārtika (कार्तिक)",
            masaSanskrit: "कार्तिक मास",
            masaMeaning: "Month of illumination and sacred lamps",
            paksha: "Śukla Pakṣa (शुक्ल पक्ष)",
            tithiName: "Caturdaśī",
            tithiSanskrit: "चतुर्दशी",
            tithiShort: "चतुर्दशी",
            tithiNumber: 14,
            tithiMeaning: "Dissolution of past impressions before fullness",
            sankalpaSanskrit: "ॐ तत्सत् श्रीब्रह्मणो द्वितीयपरार्धे श्रीश्वेतवाराहकल्पे वैवस्वतमन्वन्तरे अष्टाविंशतितमे कलियुगे...",
            sankalpaEnglish: "Year \(kaliYear) of Kali Yuga, \(samvatsaraName) Samvatsara."
        )
    }
}

public struct PanchangaSnapshot: Sendable {
    public let vara: VedicVara
    public let tithiName: String
    public let tithiNumber: Int
    public let paksha: String
    public let nakshatraName: String
    public let nakshatraDeity: String
    public let nakshatraQuality: String
    public let yogaName: String
    public let actionWindows: VedicActionWindows
    public let chronometry: VedicChronometry
}

// MARK: - Engine

public enum PanchangaEngine {
    
    /// Returns the authentic Vedic day (Sūryodayāt Sūryodaya).
    /// If the time is before astronomical sunrise, the Vedic day is the previous calendar day.
    public static func vedicDate(for date: Date = Date(), coordinate: CLLocationCoordinate2D) -> Date {
        guard let solar = SolarCalculator.calculateSolarTimes(for: date, coordinate: coordinate) else {
            return date
        }
        let calendar = Calendar.current
        if date < solar.sunrise {
            return calendar.date(byAdding: .day, value: -1, to: date) ?? date
        }
        return date
    }
    
    /// Computes full Vedic Chronometry (Kali Yuga year, Samvatsara, Ayana, Ritu, Masa, Tithi, Sankalpa) for a date.
    public static func calculateChronometry(for date: Date = Date(), coordinate: CLLocationCoordinate2D) -> VedicChronometry {
        if let p = calculatePanchanga(for: date, coordinate: coordinate) {
            return p.chronometry
        }
        return VedicChronometry.sample
    }
    
    /// Computes Action Windows (Rahu, Yama, Gulika, Abhijit) and Panchanga limbs for a given date and coordinates.
    public static func calculatePanchanga(for date: Date = Date(), coordinate: CLLocationCoordinate2D) -> PanchangaSnapshot? {
        guard let solar = SolarCalculator.calculateSolarTimes(for: date, coordinate: coordinate) else {
            return nil
        }
        
        let vDate = vedicDate(for: date, coordinate: coordinate)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: vDate) // 1 = Sunday, 7 = Saturday
        let vara = getVara(for: weekday)
        
        // 1. Calculate Daytime 8 equal segments for Rahu, Yama, Gulika
        let dayDuration = solar.sunset.timeIntervalSince(solar.sunrise)
        let partDuration = dayDuration / 8.0
        
        // Rahu Kalam Segment Mapping (0-indexed)
        // Sun: 7, Mon: 1, Tue: 6, Wed: 4, Thu: 5, Fri: 3, Sat: 2
        let rahuSegment: [Int: Int] = [1: 7, 2: 1, 3: 6, 4: 4, 5: 5, 6: 3, 7: 2]
        // Yamaganda Segment Mapping
        // Sun: 4, Mon: 3, Tue: 2, Wed: 1, Thu: 0, Fri: 6, Sat: 5
        let yamaSegment: [Int: Int] = [1: 4, 2: 3, 3: 2, 4: 1, 5: 0, 6: 6, 7: 5]
        // Gulika Segment Mapping
        // Sun: 6, Mon: 5, Tue: 4, Wed: 3, Thu: 2, Fri: 1, Sat: 0
        let gulikaSegment: [Int: Int] = [1: 6, 2: 5, 3: 4, 4: 3, 5: 2, 6: 1, 7: 0]
        
        // Use calendar weekday for the upcoming daylight hours if calculating upcoming solar day
        let actionWeekday = (date < solar.sunrise) ? calendar.component(.weekday, from: date) : weekday
        let rIndex = rahuSegment[actionWeekday] ?? 7
        let yIndex = yamaSegment[actionWeekday] ?? 4
        let gIndex = gulikaSegment[actionWeekday] ?? 6
        
        let rahuStart = solar.sunrise.addingTimeInterval(Double(rIndex) * partDuration)
        let rahuEnd = rahuStart.addingTimeInterval(partDuration)
        let rahuWindow = ActionWindow(type: .rahuKalam, start: rahuStart, end: rahuEnd)
        
        let yamaStart = solar.sunrise.addingTimeInterval(Double(yIndex) * partDuration)
        let yamaEnd = yamaStart.addingTimeInterval(partDuration)
        let yamaWindow = ActionWindow(type: .yamaganda, start: yamaStart, end: yamaEnd)
        
        let gulikaStart = solar.sunrise.addingTimeInterval(Double(gIndex) * partDuration)
        let gulikaEnd = gulikaStart.addingTimeInterval(partDuration)
        let gulikaWindow = ActionWindow(type: .gulika, start: gulikaStart, end: gulikaEnd)
        
        // Abhijit Muhurta: 8th Muhurta of the 15 daytime Muhurtas
        let muhurtaDuration = dayDuration / 15.0
        let abhijitStart = solar.sunrise.addingTimeInterval(7.0 * muhurtaDuration)
        let abhijitEnd = solar.sunrise.addingTimeInterval(8.0 * muhurtaDuration)
        let abhijitWindow = ActionWindow(type: .abhijit, start: abhijitStart, end: abhijitEnd)
        
        let actionWindows = VedicActionWindows(
            abhijit: abhijitWindow,
            rahuKalam: rahuWindow,
            yamaganda: yamaWindow,
            gulika: gulikaWindow
        )
        
        // 2. Astronomical Longitude calculations for Tithi, Nakshatra, Yoga
        let jd = date.timeIntervalSince1970 / 86400.0 + 2440587.5
        let t = (jd - 2451545.0) / 36525.0
        
        // Sun Longitude
        let l0 = (280.46646 + 36000.76983 * t).truncatingRemainder(dividingBy: 360.0)
        let m = (357.52911 + 35999.05029 * t).truncatingRemainder(dividingBy: 360.0)
        let c = (1.914602 - 0.004817 * t) * sin(m * .pi / 180.0) + (0.019993 - 0.000101 * t) * sin(2.0 * m * .pi / 180.0)
        let sunLong = (l0 + c + 360.0).truncatingRemainder(dividingBy: 360.0)
        
        // Moon Longitude (Chapront / Meeus periodic approximations)
        let lp = (218.3164477 + 481267.88123421 * t).truncatingRemainder(dividingBy: 360.0)
        let d = (297.8501921 + 445267.1114034 * t).truncatingRemainder(dividingBy: 360.0)
        let mp = (134.9633964 + 477198.8675055 * t).truncatingRemainder(dividingBy: 360.0)
        let f = (93.2720950 + 483202.0175233 * t).truncatingRemainder(dividingBy: 360.0)
        
        let moonCorr = 6.288774 * sin(mp * .pi / 180.0)
            + 1.274027 * sin((2.0 * d - mp) * .pi / 180.0)
            + 0.658314 * sin(2.0 * d * .pi / 180.0)
            + 0.213618 * sin(2.0 * mp * .pi / 180.0)
            - 0.185116 * sin(m * .pi / 180.0)
            - 0.114332 * sin(2.0 * f * .pi / 180.0)
        
        let moonLong = (lp + moonCorr + 720.0).truncatingRemainder(dividingBy: 360.0)
        
        // Tithi: Angle between Moon and Sun in 12-degree increments
        let elong = (moonLong - sunLong + 360.0).truncatingRemainder(dividingBy: 360.0)
        let tithiIndex = min(29, max(0, Int(elong / 12.0)))
        let tithiInfo = getTithi(for: tithiIndex)
        
        // Lahiri Ayanamsha for Sidereal coordinate mapping
        let ayanamsha = 23.85 + (t * 100.0 * 50.29 / 3600.0)
        let siderealMoon = (moonLong - ayanamsha + 720.0).truncatingRemainder(dividingBy: 360.0)
        let nakshatraIndex = min(26, max(0, Int(siderealMoon / (360.0 / 27.0))))
        let nakshatraInfo = getNakshatra(for: nakshatraIndex)
        
        // Yoga: Sum of Sun & Moon longitudes in 13°20' increments
        let siderealSun = (sunLong - ayanamsha + 720.0).truncatingRemainder(dividingBy: 360.0)
        let yogaIndex = min(26, max(0, Int(((siderealSun + siderealMoon).truncatingRemainder(dividingBy: 360.0)) / (360.0 / 27.0))))
        let yogaName = getYoga(for: yogaIndex)
        
        let chronometry = calculateChronometry(
            date: date,
            siderealSun: siderealSun,
            tithiIndex: tithiIndex,
            tithiInfo: tithiInfo,
            vara: vara
        )
        
        return PanchangaSnapshot(
            vara: vara,
            tithiName: tithiInfo.name,
            tithiNumber: tithiInfo.number,
            paksha: tithiInfo.paksha,
            nakshatraName: nakshatraInfo.name,
            nakshatraDeity: nakshatraInfo.deity,
            nakshatraQuality: nakshatraInfo.quality,
            yogaName: yogaName,
            actionWindows: actionWindows,
            chronometry: chronometry
        )
    }
    
    // MARK: - Vedic Cosmic Chronometry Engine
    
    private static func calculateChronometry(
        date: Date,
        siderealSun: Double,
        tithiIndex: Int,
        tithiInfo: (name: String, number: Int, paksha: String),
        vara: VedicVara
    ) -> VedicChronometry {
        // In the authentic Amanta Vedic Calendar, the year ends on Phālguna Amāvāsyā (New Moon of Phālguna).
        // The new year begins on Caitra Śukla Pratipadā (Ugadi / Gudi Padwa / Chaitra Navratri).
        let calendar = Calendar.current
        let gYear = calendar.component(.year, from: date)
        let caitraNewYear = caitraSuklaPratipada(forGregorianYear: gYear)
        
        let effectiveYear = (date >= caitraNewYear) ? gYear : (gYear - 1)
        let kaliYear = effectiveYear + 3102
        let vikramYear = effectiveYear + 57
        let sakaYear = effectiveYear - 78
        
        // 60-Year Jovian Cycle (Samvatsara) based on Saka Era
        let samvatsaraIdx = ((sakaYear + 11) % 60 + 60) % 60
        let samvatsaraName = getSamvatsaraName(for: samvatsaraIdx)
        
        // Ayana (Solar Course)
        let isDakshinayana = (siderealSun >= 90.0 && siderealSun < 270.0)
        let ayana = isDakshinayana ? "Dakṣiṇāyana (दक्षिणायन)" : "Uttarāyaṇa (उत्तरायण)"
        let ayanaMeaning = isDakshinayana ? "Southern Solar Arc: Sadhana, Inner Purification & Receptivity" : "Northern Solar Arc: Vitality, Outward Action & Spiritual Illumination"
        
        // Ritu (6 Vedic Seasons)
        let (ritu, rituMeaning) = getRitu(for: siderealSun)
        
        // Masa (Vedic Lunar-Solar Month)
        let (masa, masaSanskrit, masaMeaning) = getMasa(for: siderealSun)
        
        // Tithi Devanagari & Significance
        let tithiSanskritNames = [
            "प्रतिपदा", "द्वितीया", "तृतीया", "चतुर्थी", "पञ्चमी",
            "षष्ठी", "सप्तमी", "अष्टमी", "नवमी", "दशमी",
            "एकादशी", "द्वादशी", "त्रयोदशी", "चतुर्दशी"
        ]
        
        let tithiSanskrit: String
        let tithiShort: String
        let tithiMeaning: String
        
        if tithiIndex < 14 {
            tithiShort = tithiSanskritNames[tithiIndex]
            tithiSanskrit = "शुक्ल \(tithiShort)"
            tithiMeaning = "\(tithiInfo.number)th waxing phase: Expanding prana and conscious receptivity"
        } else if tithiIndex == 14 {
            tithiShort = "पूर्णिमा"
            tithiSanskrit = "पूर्णिमा (Full Moon)"
            tithiMeaning = "Full illumination: Summit of cosmic prana, sublime devotion & clarity"
        } else if tithiIndex < 29 {
            let offset = tithiIndex - 15
            tithiShort = tithiSanskritNames[offset]
            tithiSanskrit = "कृष्ण \(tithiShort)"
            tithiMeaning = "\(tithiInfo.number)th waning phase: Dissolution of attachments and inward contemplative depth"
        } else {
            tithiShort = "अमावास्या"
            tithiSanskrit = "अमावास्या (New Moon)"
            tithiMeaning = "Stillness of the void: Deep meditative absorption, ancestor remembrance & reset"
        }
        
        let sankalpaSanskrit = "ॐ तत्सत्। श्रीश्वेतवराहकल्पे वैवस्वतमन्वन्तरे अष्टाविंशतितमे कलियुगे कलिप्रथमचरणे, \(samvatsaraName) नाम संवत्सरे, \(ayana), \(ritu), \(masaSanskrit), \(tithiInfo.paksha), \(tithiSanskrit) तिथौ, \(vara.nameSanskrit) वासरे।"
        let sankalpaEnglish = "At this sacred moment in Kali Yuga Year \(kaliYear) (\(samvatsaraName) Samvatsara), during \(ayana), in \(ritu), in the sacred month of \(masa), \(tithiInfo.paksha), on \(tithiSanskrit) tithi, on this auspicious \(vara.nameEnglish)."
        
        return VedicChronometry(
            kaliYugaYear: kaliYear,
            vikramSamvat: vikramYear,
            sakaSamvat: sakaYear,
            samvatsaraName: samvatsaraName,
            samvatsaraNumber: samvatsaraIdx + 1,
            ayana: ayana,
            ayanaMeaning: ayanaMeaning,
            ritu: ritu,
            rituMeaning: rituMeaning,
            masa: masa,
            masaSanskrit: masaSanskrit,
            masaMeaning: masaMeaning,
            paksha: tithiInfo.paksha,
            tithiName: tithiInfo.name,
            tithiSanskrit: tithiSanskrit,
            tithiShort: tithiShort,
            tithiNumber: tithiInfo.number,
            tithiMeaning: tithiMeaning,
            sankalpaSanskrit: sankalpaSanskrit,
            sankalpaEnglish: sankalpaEnglish
        )
    }
    
    // MARK: - Tables
    
    private static func getVara(for weekday: Int) -> VedicVara {
        switch weekday {
        case 1:
            return VedicVara(weekdayNumber: 1, nameSanskrit: "Ravivāra (रविवार)", nameEnglish: "Sunday", rulingGraha: "Surya (Sun)", element: "Tejas (Fire)", deity: "Shiva", essence: "Vitality, Leadership & Spiritual Radiance")
        case 2:
            return VedicVara(weekdayNumber: 2, nameSanskrit: "Somavāra (सोमवार)", nameEnglish: "Monday", rulingGraha: "Chandra (Moon)", element: "Jala (Water)", deity: "Parvati", essence: "Emotional Calm, Nurturing & Meditation")
        case 3:
            return VedicVara(weekdayNumber: 3, nameSanskrit: "Maṅgalavāra (मंगलवार)", nameEnglish: "Tuesday", rulingGraha: "Mangala (Mars)", element: "Tejas (Fire)", deity: "Kartikeya", essence: "Courage, Willpower, Discipline & Resolve")
        case 4:
            return VedicVara(weekdayNumber: 4, nameSanskrit: "Budhavāra (बुधवार)", nameEnglish: "Wednesday", rulingGraha: "Budha (Mercury)", element: "Prithvi (Earth)", deity: "Vishnu", essence: "Intellect, Articulation, Trade & Learning")
        case 5:
            return VedicVara(weekdayNumber: 5, nameSanskrit: "Guruvāra (गुरुवार)", nameEnglish: "Thursday", rulingGraha: "Brihaspati (Jupiter)", element: "Akasha (Space)", deity: "Brahma", essence: "Wisdom, Expansion, Teaching & Grace")
        case 6:
            return VedicVara(weekdayNumber: 6, nameSanskrit: "Śukravāra (शुक्रवार)", nameEnglish: "Friday", rulingGraha: "Shukra (Venus)", element: "Jala (Water)", deity: "Lakshmi", essence: "Harmony, Creative Arts, Devotion & Beauty")
        default:
            return VedicVara(weekdayNumber: 7, nameSanskrit: "Śanivāra (शनिवार)", nameEnglish: "Saturday", rulingGraha: "Shani (Saturn)", element: "Vayu (Air)", deity: "Yama", essence: "Patience, Humility, Grounding & Solitude")
        }
    }
    
    private static func getTithi(for index: Int) -> (name: String, number: Int, paksha: String) {
        let tithiNames = [
            "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
            "Shasthi", "Saptami", "Ashtami", "Navami", "Dashami",
            "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi"
        ]
        
        if index < 14 {
            let num = index + 1
            return ("Shukla \(tithiNames[index])", num, "Shukla Paksha (Waxing)")
        } else if index == 14 {
            return ("Purnima (Full Moon • पूर्णिमा)", 15, "Shukla Paksha (Waxing Peak)")
        } else if index < 29 {
            let offset = index - 15
            let num = offset + 1
            return ("Krishna \(tithiNames[offset])", num, "Krishna Paksha (Waning)")
        } else {
            return ("Amavasya (New Moon • अमावस्या)", 30, "Krishna Paksha (Waning Peak)")
        }
    }
    
    private static func getNakshatra(for index: Int) -> (name: String, deity: String, quality: String) {
        let nakshatras = [
            ("Ashwini (अश्विनी)", "Ashwini Kumaras", "Light & Swift"),
            ("Bharani (भरणी)", "Yama", "Restrained & Deep"),
            ("Krittika (कृत्तिका)", "Agni", "Piercing & Illuminating"),
            ("Rohini (रोहिणी)", "Brahma / Prajapati", "Creative, Fertile & Fixed"),
            ("Mrigashira (मृगशीर्षा)", "Soma", "Gentle & Searching"),
            ("Ardra (आर्द्रा)", "Rudra", "Sharp, Transformative & Intense"),
            ("Punarvasu (पुनर्वसु)", "Aditi", "Movable, Restorative & Renewal"),
            ("Pushya (पुष्य)", "Brihaspati", "Most Nourishing & Auspicious"),
            ("Ashlesha (आश्लेषा)", "Sarpa / Naga", "Clinging & Mystical"),
            ("Magha (मघा)", "Pitrus (Ancestors)", "Royal & Majestic"),
            ("Purva Phalguni (पूर्वाफाल्गुनी)", "Bhaga", "Pleasant, Joyful & Creative"),
            ("Uttara Phalguni (उत्तराफाल्गुनी)", "Aryaman", "Steadfast & Honorable"),
            ("Hasta (हस्त)", "Savitr", "Dexterous, Skillful & Light"),
            ("Chitra (चित्रा)", "Vishwakarma", "Soft, Elegant & Architectural"),
            ("Swati (स्वाति)", "Vayu", "Independent & Free-Moving"),
            ("Vishakha (विशाखा)", "Indragni", "Goal-Oriented & Purposeful"),
            ("Anuradha (अनुराधा)", "Mitra", "Devotional, Friendly & Harmonious"),
            ("Jyeshtha (ज्येष्ठा)", "Indra", "Protective & Senior"),
            ("Mula (मूल)", "Nirriti", "Root-seeking & Transformative"),
            ("Purva Ashadha (पूर्वाषाढ़ा)", "Apas (Water)", "Invincible & Fluid"),
            ("Uttara Ashadha (उत्तराषाढ़ा)", "Vishwadevas", "Universal & Undefeatable"),
            ("Shravana (श्रवण)", "Vishnu", "Listening, Wisdom & Receptive"),
            ("Dhanishta (धनिष्ठा)", "Ashta Vasus", "Rhythmic, Wealthy & Dynamic"),
            ("Shatabhisha (शतभिषा)", "Varuna", "Hundred Physicians & Healing"),
            ("Purva Bhadrapada (पूर्वभाद्रपदा)", "Aja Ekapada", "Intense, Meditative & Ascetic"),
            ("Uttara Bhadrapada (उत्तरभाद्रपदा)", "Ahirbudhnya", "Deep Oceanic Stillness"),
            ("Revati (रेवती)", "Pushan", "Gentle Guide & Nourisher")
        ]
        let idx = max(0, min(nakshatras.count - 1, index))
        return nakshatras[idx]
    }
    
    private static func getYoga(for index: Int) -> String {
        let yogas = [
            "Vishkambha", "Priti", "Ayushman", "Saubhagya", "Shobhana",
            "Atiganda", "Sukarma", "Dhriti", "Shula", "Ganda",
            "Vriddhi", "Dhruva", "Vyaghata", "Harshana", "Vajra",
            "Siddhi", "Vyatipata", "Variyan", "Parigha", "Shiva",
            "Siddha", "Sadhya", "Shubha", "Shukla", "Brahma",
            "Indra", "Vaidhriti"
        ]
        let idx = max(0, min(yogas.count - 1, index))
        return yogas[idx]
    }
    
    /// Determines the astronomical date of Caitra Śukla Pratipadā (the first sunrise after Phālguna Amāvāsyā)
    /// which marks the transition of the Vedic New Year (Ugadi / Gudi Padwa / Saṁvatsarādi).
    public static func caitraSuklaPratipada(forGregorianYear year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = 3
        components.day = 10
        components.hour = 6
        components.timeZone = TimeZone(identifier: "Asia/Kolkata")
        let calendar = Calendar.current
        guard let searchStart = calendar.date(from: components) else { return Date() }
        
        // Scan up to 45 days into April to find the New Moon in sidereal Pisces (Mīna)
        for day in 0..<45 {
            guard let checkDate = calendar.date(byAdding: .day, value: day, to: searchStart) else { continue }
            let jd = checkDate.timeIntervalSince1970 / 86400.0 + 2440587.5
            let t = (jd - 2451545.0) / 36525.0
            
            let l0 = (280.46646 + 36000.76983 * t).truncatingRemainder(dividingBy: 360.0)
            let m = (357.52911 + 35999.05029 * t).truncatingRemainder(dividingBy: 360.0)
            let c = (1.914602 - 0.004817 * t) * sin(m * .pi / 180.0)
            let sunLong = (l0 + c + 360.0).truncatingRemainder(dividingBy: 360.0)
            
            let lp = (218.3164477 + 481267.88123421 * t).truncatingRemainder(dividingBy: 360.0)
            let d = (297.8501921 + 445267.1114034 * t).truncatingRemainder(dividingBy: 360.0)
            let mp = (134.9633964 + 477198.8675055 * t).truncatingRemainder(dividingBy: 360.0)
            let moonCorr = 6.288774 * sin(mp * .pi / 180.0) + 1.274027 * sin((2.0 * d - mp) * .pi / 180.0)
            let moonLong = (lp + moonCorr + 360.0).truncatingRemainder(dividingBy: 360.0)
            
            let elongation = (moonLong - sunLong + 360.0).truncatingRemainder(dividingBy: 360.0)
            let tithiIndex = Int(elongation / 12.0) % 30
            
            // Caitra Sukla Pratipada is the first waxing tithi (tithiIndex == 0)
            if tithiIndex == 0 {
                return checkDate
            }
        }
        return searchStart
    }
    
    public static func getSamvatsaraName(for index: Int) -> String {
        let samvatsaras = [
            "Prabhava (प्रभव)", "Vibhava (विभव)", "Śukla (शुक्ल)", "Pramoda (प्रमोद)", "Prajāpati (प्रजापति)",
            "Aṅgirasa (अङ्गिरा)", "Śrīmukha (श्रीमुख)", "Bhāva (भाव)", "Yuva (युव)", "Dhātā (धाता)",
            "Īśvara (ईश्वर)", "Bahudhānya (बहुधान्य)", "Pramāthī (प्रमाथी)", "Vikrama (विक्रम)", "Vṛṣa (वृष)",
            "Citrabhānu (चित्रभानु)", "Subhānu (सुभानु)", "Tāraṇa (तारण)", "Pārthiva (पार्थिव)", "Vyaya (व्यय)",
            "Sarvajit (सर्वजित्)", "Sarvadhārī (सर्वधारी)", "Virodhī (विरोधी)", "Vikṛti (विकृति)", "Khara (खर)",
            "Nandana (नन्दन)", "Vijaya (विजय)", "Jaya (जय)", "Manmatha (मन्मथ)", "Durmukha (दुर्मुख)",
            "Hemalambī (हेमलम्बी)", "Vilambī (विलम्बी)", "Vikārī (विकारी)", "Śārvarī (शार्वरी)", "Plava (प्लव)",
            "Śubhakṛt (शुभकृत्)", "Śobhakṛt (शोभकृत्)", "Krodhī (क्रोधी)", "Viśvāvasu (विश्वावसु)", "Parābhava (पराभव)",
            "Plavaṅga (प्लवङ्ग)", "Kīlaka (कीलक)", "Saumya (सौम्य)", "Sādhāraṇa (साधारण)", "Virodhakṛt (विरोधकृत्)",
            "Parīdhāvī (परिधावी)", "Pramādī (प्रमादी)", "Ānanda (आनन्द)", "Rākṣasa (राक्षस)", "Anala (अनल)",
            "Piṅgala (पिङ्गल)", "Kālayukta (कालयुक्त)", "Siddhārthī (सिद्धार्थी)", "Raudra (रौद्र)", "Durmatī (दुर्मति)",
            "Dundubhī (दुन्दुभी)", "Rudhirodgārī (रुधिरोद्गारी)", "Raktākṣī (रक्ताक्षी)", "Krodhana (क्रोधन)", "Kṣaya (क्षय)"
        ]
        let idx = max(0, min(samvatsaras.count - 1, index))
        return samvatsaras[idx]
    }
    
    private static func getRitu(for siderealSun: Double) -> (name: String, meaning: String) {
        if siderealSun >= 330.0 || siderealSun < 30.0 {
            return ("Vasanta Ṛtu (वसन्त ऋतु)", "Spring: Awakening prana, creative renewal & clarity")
        } else if siderealSun < 90.0 {
            return ("Grīṣma Ṛtu (ग्रीष्म ऋतु)", "Summer: High radiant agni, stay cool & hydrated")
        } else if siderealSun < 150.0 {
            return ("Varṣā Ṛtu (वर्षा ऋतु)", "Monsoon: Earth replenishment, gentle digestion & grounding")
        } else if siderealSun < 210.0 {
            return ("Śarat Ṛtu (शरद् ऋतु)", "Autumn: Balance Pitta, luminous moonlit nights & spiritual stillness")
        } else if siderealSun < 270.0 {
            return ("Hemanta Ṛtu (हेमन्त ऋतु)", "Pre-Winter: Deep digestive fire, nourishing meals & vitality")
        } else {
            return ("Śiśira Ṛtu (शिशिर ऋतु)", "Winter: Inward stillness, warm teas & meditation")
        }
    }
    
    private static func getMasa(for siderealSun: Double) -> (name: String, sanskrit: String, meaning: String) {
        let masaZones = [
            ("Vaiśākha", "वैशाख मास", "Auspicious solar entry, devotion & charity"),
            ("Jyeṣṭha", "ज्येष्ठ मास", "Peak solar illumination, surrender & wisdom"),
            ("Āṣāḍha", "आषाढ़ मास", "Guru Purnima, start of holy Chaturmasya"),
            ("Śrāvaṇa", "श्रावण मास", "Devotion to Shiva, rain of spiritual grace"),
            ("Bhādrapada", "भाद्रपद मास", "Ganesha Chaturthi, dissolving obstacles"),
            ("Āśvina", "आश्विन मास", "Navaratri, divine feminine shakti & spiritual victory"),
            ("Kārtika", "कार्तिक मास", "Deepavali, supreme festival of light & lamps"),
            ("Mārgaśīrṣa", "मार्गशीर्ष मास", "Supreme spiritual month (Gita 10.35: 'Among months I am Mārgaśīrṣa')"),
            ("Pauṣa", "पौष मास", "Inward tapasya, sun entering Makara Sankranti"),
            ("Māgha", "माघ मास", "Maha Shivaratri, sacred holy river baths"),
            ("Phālguna", "फाल्गुन मास", "Holi, celebration of divine joy and love"),
            ("Caitra", "चैत्र मास", "Vedic New Year, cosmic creation begins afresh")
        ]
        let idx = max(0, min(11, Int(siderealSun / 30.0)))
        return masaZones[idx]
    }
    
    /// Provides an authentic Vedic mini-summary for calendar strips
    public static func tithiMiniSummary(for date: Date, coordinate: CLLocationCoordinate2D) -> (tithiDevanagari: String, tithiNum: Int, varaDevanagari: String, isShukla: Bool) {
        let calendar = Calendar.current
        // A calendar day's canonical Tithi in Vedic tradition is the Udaya Tithi (Tithi at sunrise).
        // Normalize time-of-day to solar midday (12:00 PM) so scanning future/past calendar days evaluates that day's Udaya Tithi cleanly.
        let noonDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        let vDate = vedicDate(for: noonDate, coordinate: coordinate)
        if let panchanga = calculatePanchanga(for: vDate, coordinate: coordinate) {
            let varaDevanagari: String
            switch panchanga.vara.weekdayNumber {
            case 1: varaDevanagari = "रवि"
            case 2: varaDevanagari = "सोम"
            case 3: varaDevanagari = "मङ्गळ"
            case 4: varaDevanagari = "बुध"
            case 5: varaDevanagari = "गुरु"
            case 6: varaDevanagari = "शुक्र"
            default: varaDevanagari = "शनि"
            }
            let isShukla = panchanga.chronometry.paksha.contains("Śukla") || panchanga.chronometry.paksha.contains("Shukla")
            return (panchanga.chronometry.tithiShort, panchanga.chronometry.tithiNumber, varaDevanagari, isShukla)
        }
        
        // Dynamic astronomical fallback computed directly from date
        let jd = noonDate.timeIntervalSince1970 / 86400.0 + 2440587.5
        let t = (jd - 2451545.0) / 36525.0
        let l0 = (280.46646 + 36000.76983 * t).truncatingRemainder(dividingBy: 360.0)
        let m = (357.52911 + 35999.05029 * t).truncatingRemainder(dividingBy: 360.0)
        let c = (1.914602 - 0.004817 * t) * sin(m * .pi / 180.0)
        let sunLong = (l0 + c + 360.0).truncatingRemainder(dividingBy: 360.0)
        
        let lp = (218.3164477 + 481267.88123421 * t).truncatingRemainder(dividingBy: 360.0)
        let d = (297.8501921 + 445267.1114034 * t).truncatingRemainder(dividingBy: 360.0)
        let mp = (134.9633964 + 477198.8675055 * t).truncatingRemainder(dividingBy: 360.0)
        let moonCorr = 6.288774 * sin(mp * .pi / 180.0) + 1.274027 * sin((2.0 * d - mp) * .pi / 180.0)
        let moonLong = (lp + moonCorr + 360.0).truncatingRemainder(dividingBy: 360.0)
        
        let elongation = (moonLong - sunLong + 360.0).truncatingRemainder(dividingBy: 360.0)
        let tithiIndex = Int(elongation / 12.0) % 30
        let isShukla = tithiIndex < 15
        let tNum = (tithiIndex % 15) + 1
        
        let tithiSanskritNames = [
            "प्रतिपदा", "द्वितीया", "तृतीया", "चतुर्थी", "पञ्चमी",
            "षष्ठी", "सप्तमी", "अष्टमी", "नवमी", "दशमी",
            "एकादशी", "द्वादशी", "त्रयोदशी", "चतुर्दशी"
        ]
        let tName: String
        if tithiIndex == 14 {
            tName = "पूर्णिमा"
        } else if tithiIndex == 29 {
            tName = "अमावास्या"
        } else {
            tName = tithiSanskritNames[max(0, min(13, tNum - 1))]
        }
        
        let weekday = Calendar.current.component(.weekday, from: date)
        let varaDevanagari: String
        switch weekday {
        case 1: varaDevanagari = "रवि"
        case 2: varaDevanagari = "सोम"
        case 3: varaDevanagari = "मङ्गळ"
        case 4: varaDevanagari = "बुध"
        case 5: varaDevanagari = "गुरु"
        case 6: varaDevanagari = "शुक्र"
        default: varaDevanagari = "शनि"
        }
        return (tName, tNum, varaDevanagari, isShukla)
    }
}
