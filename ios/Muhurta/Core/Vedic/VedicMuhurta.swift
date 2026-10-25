//
//  VedicMuhurta.swift
//  Muhurta
//
//  Complete Vedic Muhurta and Dosha Circadian models.
//

import SwiftUI

public enum MuhurtaQuality: String, Codable, Sendable {
    case auspicious
    case inauspicious
    case neutral
    case sacred // E.g., Brahma Muhurta, Abhijit
    
    public var accentColor: Color {
        switch self {
        case .sacred:
            return Color(red: 0.92, green: 0.70, blue: 0.38) // Warm Dawn Ochre
        case .auspicious:
            return Color(red: 0.40, green: 0.78, blue: 0.62) // Quiet Sage
        case .inauspicious:
            return Color(red: 0.82, green: 0.45, blue: 0.45) // Muted Clay Rose
        case .neutral:
            return Color(red: 0.55, green: 0.60, blue: 0.70) // Cool Slate
        }
    }
}

public struct MuhurtaPeriod: Identifiable, Sendable {
    public let id: String
    public let index: Int
    public let isDaytime: Bool
    public let nameSanskrit: String
    public let nameEnglish: String
    public let deity: String
    public let quality: MuhurtaQuality
    public let description: String
    public let startTime: Date
    public let endTime: Date
    
    public var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    public func contains(date: Date) -> Bool {
        date >= startTime && date < endTime
    }
    
    public func progress(at date: Date = Date()) -> Double {
        guard duration > 0 else { return 0 }
        let elapsed = date.timeIntervalSince(startTime)
        return min(max(elapsed / duration, 0.0), 1.0)
    }
    
    /// True if this Muhurta window begins before midnight and finishes after midnight
    public var crossesMidnight: Bool {
        let cal = Calendar.current
        return cal.component(.day, from: startTime) != cal.component(.day, from: endTime)
    }
    
    /// Short time range like "21:57 – 22:46" or "04:33 – 05:22"
    public var formattedTimeRange: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: startTime)) – \(f.string(from: endTime))"
    }
    
    /// 12-hour formatted time range like "4:33 AM – 5:22 AM"
    public var formatted12HourRange: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: startTime)) – \(f.string(from: endTime))"
    }
    
    /// Explicit calendar date chip to resolve Gregorian midnight vs Vedic day confusion
    public func calendarDateChip(relativeTo refDate: Date = Date()) -> String {
        let cal = Calendar.current
        let f = DateFormatter()
        f.dateFormat = "EEE, d MMM"
        
        if crossesMidnight {
            let startDay = cal.component(.day, from: startTime)
            let endDay = cal.component(.day, from: endTime)
            let monthF = DateFormatter()
            monthF.dateFormat = "MMM"
            return "\(startDay) → \(endDay) \(monthF.string(from: endTime))"
        }
        
        let dayStr = f.string(from: startTime)
        if cal.isDate(startTime, inSameDayAs: refDate) {
            return "Today • \(dayStr)"
        } else if let tom = cal.date(byAdding: .day, value: 1, to: refDate), cal.isDate(startTime, inSameDayAs: tom) {
            return "Tomorrow • \(dayStr)"
        } else {
            return dayStr
        }
    }
}

// MARK: - Dosha Circadian Cycle

public enum Dosha: String, CaseIterable, Identifiable, Sendable {
    case vata = "Vata"
    case kapha = "Kapha"
    case pitta = "Pitta"
    
    public var id: String { rawValue }
    
    public var elements: String {
        switch self {
        case .vata: return "Air & Ether (Vayu & Akasha)"
        case .kapha: return "Earth & Water (Prithvi & Jala)"
        case .pitta: return "Fire & Water (Agni & Jala)"
        }
    }
    
    public var qualities: String {
        switch self {
        case .vata: return "Subtle, Light, Moving, Intuitive"
        case .kapha: return "Grounded, Heavy, Loving, Calm"
        case .pitta: return "Sharp, Hot, Transformative, Focused"
        }
    }
    
    public var iconName: String {
        switch self {
        case .vata: return "wind"
        case .kapha: return "mountain.2.fill"
        case .pitta: return "flame.fill"
        }
    }
    
    public var themeColor: Color {
        switch self {
        case .vata: return Color(red: 0.50, green: 0.65, blue: 0.82) // Calm Ether Blue
        case .kapha: return Color(red: 0.44, green: 0.70, blue: 0.56) // Forest Sage Green
        case .pitta: return Color(red: 0.88, green: 0.58, blue: 0.36) // Terracotta Amber
        }
    }
}

public struct DoshaWindow: Identifiable, Sendable {
    public let id = UUID()
    public let dosha: Dosha
    public let label: String
    public let startHour: Int
    public let endHour: Int
    public let activityRecommendation: String
}
