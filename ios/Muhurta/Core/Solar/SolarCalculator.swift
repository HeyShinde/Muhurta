//
//  SolarCalculator.swift
//  Muhurta
//
//  Astronomical Solar Calculation Engine based on NOAA / Jean Meeus algorithms.
//  Completely offline, precise to within seconds.
//

import Foundation
import CoreLocation

public struct SolarTimes: Equatable, Sendable {
    public let date: Date
    public let coordinate: CLLocationCoordinate2D
    public let astronomicalDawn: Date?
    public let nauticalDawn: Date?
    public let civilDawn: Date?
    public let sunrise: Date
    public let solarNoon: Date
    public let sunset: Date
    public let civilDusk: Date?
    public let nauticalDusk: Date?
    public let astronomicalDusk: Date?
    
    /// Length of daylight in seconds
    public var dayDuration: TimeInterval {
        sunset.timeIntervalSince(sunrise)
    }
    
    public static func == (lhs: SolarTimes, rhs: SolarTimes) -> Bool {
        lhs.date == rhs.date &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.astronomicalDawn == rhs.astronomicalDawn &&
        lhs.nauticalDawn == rhs.nauticalDawn &&
        lhs.civilDawn == rhs.civilDawn &&
        lhs.sunrise == rhs.sunrise &&
        lhs.solarNoon == rhs.solarNoon &&
        lhs.sunset == rhs.sunset &&
        lhs.civilDusk == rhs.civilDusk &&
        lhs.nauticalDusk == rhs.nauticalDusk &&
        lhs.astronomicalDusk == rhs.astronomicalDusk
    }
}

public struct SolarPosition: Equatable, Sendable {
    /// Elevation angle above horizon in degrees (-90° nadir to +90° zenith)
    public let altitude: Double
    /// Azimuth angle in degrees from North (0° = N, 90° = E, 180° = S, 270° = W)
    public let azimuth: Double
    /// True if the sun is above the geometric horizon
    public var isDaylight: Bool {
        altitude > -0.8333
    }
}

public enum SolarCalculator {
    // Atmospheric refraction and solar disc semi-diameter standard zenith
    private static let standardZenith = 90.8333
    private static let civilZenith = 96.0
    private static let nauticalZenith = 102.0
    private static let astronomicalZenith = 108.0

    // MARK: - Public API
    
    /// Calculates solar event times for a given calendar date and GPS coordinate.
    public static func calculateSolarTimes(for date: Date = Date(), coordinate: CLLocationCoordinate2D, timeZone: TimeZone = .current) -> SolarTimes? {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = timeZone
        let components = localCalendar.dateComponents([.year, .month, .day], from: date)
        
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        guard let utcMidnight = utcCalendar.date(from: components) else { return nil }
        
        let jdMidnight = julianDay(from: utcMidnight)
        
        // Solar Noon
        let noonMinutes = calculateSolarNoonUTC(jd: jdMidnight, longitude: coordinate.longitude)
        guard let solarNoon = utcCalendar.date(byAdding: .second, value: Int(noonMinutes * 60.0), to: utcMidnight) else { return nil }
        
        // Sunrise & Sunset (official disc upper edge with refraction)
        guard let (sunriseUTC, sunsetUTC) = calculateRiseSet(jd: jdMidnight, coordinate: coordinate, zenith: standardZenith),
              let sunrise = utcCalendar.date(byAdding: .second, value: Int(sunriseUTC * 60.0), to: utcMidnight),
              let sunset = utcCalendar.date(byAdding: .second, value: Int(sunsetUTC * 60.0), to: utcMidnight)
        else {
            return nil
        }
        
        // Twilights
        let civil = calculateRiseSet(jd: jdMidnight, coordinate: coordinate, zenith: civilZenith)
        let nautical = calculateRiseSet(jd: jdMidnight, coordinate: coordinate, zenith: nauticalZenith)
        let astronomical = calculateRiseSet(jd: jdMidnight, coordinate: coordinate, zenith: astronomicalZenith)
        
        let civilDawn = civil.flatMap { utcCalendar.date(byAdding: .second, value: Int($0.rise * 60.0), to: utcMidnight) }
        let civilDusk = civil.flatMap { utcCalendar.date(byAdding: .second, value: Int($0.set * 60.0), to: utcMidnight) }
        let nauticalDawn = nautical.flatMap { utcCalendar.date(byAdding: .second, value: Int($0.rise * 60.0), to: utcMidnight) }
        let nauticalDusk = nautical.flatMap { utcCalendar.date(byAdding: .second, value: Int($0.set * 60.0), to: utcMidnight) }
        let astroDawn = astronomical.flatMap { utcCalendar.date(byAdding: .second, value: Int($0.rise * 60.0), to: utcMidnight) }
        let astroDusk = astronomical.flatMap { utcCalendar.date(byAdding: .second, value: Int($0.set * 60.0), to: utcMidnight) }
        
        return SolarTimes(
            date: date,
            coordinate: coordinate,
            astronomicalDawn: astroDawn,
            nauticalDawn: nauticalDawn,
            civilDawn: civilDawn,
            sunrise: sunrise,
            solarNoon: solarNoon,
            sunset: sunset,
            civilDusk: civilDusk,
            nauticalDusk: nauticalDusk,
            astronomicalDusk: astroDusk
        )
    }
    
    /// Calculates live solar altitude and azimuth for the specified moment and coordinate.
    public static func calculatePosition(at date: Date = Date(), coordinate: CLLocationCoordinate2D) -> SolarPosition {
        let jd = julianDay(from: date)
        let t = (jd - 2451545.0) / 36525.0
        
        let geomMeanLongSun = (280.46646 + t * (36000.76983 + 0.0003032 * t)).truncatingRemainder(dividingBy: 360.0)
        let geomMeanAnomSun = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        let e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        
        let sunEqOfCtr = sin(degToRad(geomMeanAnomSun)) * (1.914602 - t * (0.004817 + 0.000014 * t))
            + sin(degToRad(2.0 * geomMeanAnomSun)) * (0.019993 - 0.000101 * t)
            + sin(degToRad(3.0 * geomMeanAnomSun)) * 0.000289
        
        let sunTrueLong = geomMeanLongSun + sunEqOfCtr
        let sunAppLong = sunTrueLong - 0.00569 - 0.00478 * sin(degToRad(125.04 - 1934.136 * t))
        
        let meanObliqEcliptic = 23.0 + (26.0 + ((21.448 - t * (46.815 + t * (0.00059 - t * 0.001813)))) / 60.0) / 60.0
        let obliqCorr = meanObliqEcliptic + 0.00256 * cos(degToRad(125.04 - 1934.136 * t))
        
        let sunDeclin = radToDeg(asin(sin(degToRad(obliqCorr)) * sin(degToRad(sunAppLong))))
        
        let varY = tan(degToRad(obliqCorr / 2.0)) * tan(degToRad(obliqCorr / 2.0))
        let eot = 4.0 * radToDeg(
            varY * sin(2.0 * degToRad(geomMeanLongSun))
            - 2.0 * e * sin(degToRad(geomMeanAnomSun))
            + 4.0 * e * varY * sin(degToRad(geomMeanAnomSun)) * cos(2.0 * degToRad(geomMeanLongSun))
            - 0.5 * varY * varY * sin(4.0 * degToRad(geomMeanLongSun))
            - 1.25 * e * e * sin(2.0 * degToRad(geomMeanAnomSun))
        )
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let hour = Double(calendar.component(.hour, from: date))
        let minute = Double(calendar.component(.minute, from: date))
        let second = Double(calendar.component(.second, from: date))
        
        let timeOffset = eot + 4.0 * coordinate.longitude
        let trueSolarTime = (hour * 60.0 + minute + second / 60.0 + timeOffset).truncatingRemainder(dividingBy: 1440.0)
        let normalizedTST = trueSolarTime < 0 ? trueSolarTime + 1440.0 : trueSolarTime
        
        var hourAngle = normalizedTST / 4.0 - 180.0
        if hourAngle < -180.0 { hourAngle += 360.0 }
        
        let csz = sin(degToRad(coordinate.latitude)) * sin(degToRad(sunDeclin))
            + cos(degToRad(coordinate.latitude)) * cos(degToRad(sunDeclin)) * cos(degToRad(hourAngle))
        let zenith = radToDeg(acos(max(-1.0, min(1.0, csz))))
        let altitude = 90.0 - zenith
        
        // Azimuth
        let latRad = degToRad(coordinate.latitude)
        let decRad = degToRad(sunDeclin)
        let zenRad = degToRad(zenith)
        
        let azDenom = cos(latRad) * sin(zenRad)
        var azimuth: Double = 0.0
        if abs(azDenom) > 0.0001 {
            let azVal = ((sin(latRad) * cos(zenRad)) - sin(decRad)) / azDenom
            let clamped = max(-1.0, min(1.0, azVal))
            let solarAz = 180.0 - radToDeg(acos(clamped))
            azimuth = hourAngle > 0 ? (solarAz + 180.0).truncatingRemainder(dividingBy: 360.0) : (540.0 - solarAz).truncatingRemainder(dividingBy: 360.0)
        }
        
        return SolarPosition(altitude: altitude, azimuth: azimuth)
    }

    // MARK: - Internal Math Helpers
    
    private static func julianDay(from date: Date) -> Double {
        return date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }
    
    private static func calculateSolarNoonUTC(jd: Double, longitude: Double) -> Double {
        let tNoon = (jd - 2451545.0) / 36525.0
        let eqTime = equationOfTime(t: tNoon)
        let solarNoonUTC = (720.0 - 4.0 * longitude - eqTime)
        return solarNoonUTC
    }
    
    private static func calculateRiseSet(jd: Double, coordinate: CLLocationCoordinate2D, zenith: Double) -> (rise: Double, set: Double)? {
        let t = (jd - 2451545.0) / 36525.0
        let eqTime = equationOfTime(t: t)
        let solarDec = sunDeclination(t: t)
        
        let latRad = degToRad(coordinate.latitude)
        let decRad = degToRad(solarDec)
        let zenRad = degToRad(zenith)
        
        let cosHourAngle = (cos(zenRad) / (cos(latRad) * cos(decRad))) - (tan(latRad) * tan(decRad))
        
        // Polar day or polar night (sun doesn't cross zenith)
        guard cosHourAngle >= -1.0 && cosHourAngle <= 1.0 else {
            return nil
        }
        
        let hourAngleDeg = radToDeg(acos(cosHourAngle))
        let noonMinutes = 720.0 - 4.0 * coordinate.longitude - eqTime
        
        let riseMinutes = noonMinutes - hourAngleDeg * 4.0
        let setMinutes = noonMinutes + hourAngleDeg * 4.0
        
        return (riseMinutes, setMinutes)
    }
    
    private static func equationOfTime(t: Double) -> Double {
        let geomMeanLongSun = (280.46646 + t * (36000.76983 + 0.0003032 * t)).truncatingRemainder(dividingBy: 360.0)
        let geomMeanAnomSun = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        let e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        
        let meanObliq = 23.0 + (26.0 + ((21.448 - t * (46.815 + t * (0.00059 - t * 0.001813)))) / 60.0) / 60.0
        let obliqCorr = meanObliq + 0.00256 * cos(degToRad(125.04 - 1934.136 * t))
        
        let varY = tan(degToRad(obliqCorr / 2.0)) * tan(degToRad(obliqCorr / 2.0))
        let eot = 4.0 * radToDeg(
            varY * sin(2.0 * degToRad(geomMeanLongSun))
            - 2.0 * e * sin(degToRad(geomMeanAnomSun))
            + 4.0 * e * varY * sin(degToRad(geomMeanAnomSun)) * cos(2.0 * degToRad(geomMeanLongSun))
            - 0.5 * varY * varY * sin(4.0 * degToRad(geomMeanLongSun))
            - 1.25 * e * e * sin(2.0 * degToRad(geomMeanAnomSun))
        )
        return eot
    }
    
    private static func sunDeclination(t: Double) -> Double {
        let geomMeanLongSun = (280.46646 + t * (36000.76983 + 0.0003032 * t)).truncatingRemainder(dividingBy: 360.0)
        let geomMeanAnomSun = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        
        let sunEqOfCtr = sin(degToRad(geomMeanAnomSun)) * (1.914602 - t * (0.004817 + 0.000014 * t))
            + sin(degToRad(2.0 * geomMeanAnomSun)) * (0.019993 - 0.000101 * t)
            + sin(degToRad(3.0 * geomMeanAnomSun)) * 0.000289
        
        let sunTrueLong = geomMeanLongSun + sunEqOfCtr
        let sunAppLong = sunTrueLong - 0.00569 - 0.00478 * sin(degToRad(125.04 - 1934.136 * t))
        
        let meanObliq = 23.0 + (26.0 + ((21.448 - t * (46.815 + t * (0.00059 - t * 0.001813)))) / 60.0) / 60.0
        let obliqCorr = meanObliq + 0.00256 * cos(degToRad(125.04 - 1934.136 * t))
        
        return radToDeg(asin(sin(degToRad(obliqCorr)) * sin(degToRad(sunAppLong))))
    }
    
    @inline(__always) private static func degToRad(_ deg: Double) -> Double { deg * .pi / 180.0 }
    @inline(__always) private static func radToDeg(_ rad: Double) -> Double { rad * 180.0 / .pi }
}
