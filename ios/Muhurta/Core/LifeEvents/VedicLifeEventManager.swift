//
//  VedicLifeEventManager.swift
//  Muhurta
//
//  Manages Birthdays, Anniversaries, and Sacred Samskaras.
//  Converts between Roman/Gregorian dates and authentic Vedic Chronometry,
//  computes annual Vedic recurrences (celebrated on the exact Tithi & Māsa of the Kali Yuga year),
//  and syncs with Firebase Firestore with full offline support.
//

import Foundation
import SwiftUI
import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import Combine

// MARK: - Life Event Types

public enum LifeEventType: String, Codable, CaseIterable, Identifiable {
    case birthday = "Birthday (Janmadina)"
    case anniversary = "Anniversary (Vivāha)"
    case samskara = "Samskara (Sacred Milestone)"
    case memorial = "Śrāddha / Ancestor Remembrance"
    case custom = "Sacred Vow / Pūjā"
    
    public var id: String { rawValue }
    
    public var sanskritTitle: String {
        switch self {
        case .birthday: return "जन्मदिनम् (Janmadina)"
        case .anniversary: return "विवाहदिवसः (Vivāhadivasa)"
        case .samskara: return "संस्कारः (Samskāra)"
        case .memorial: return "श्राद्धम् (Śrāddha)"
        case .custom: return "संकल्प-पूजा (Sankalpa)"
        }
    }
    
    public var iconName: String {
        switch self {
        case .birthday: return "sparkles"
        case .anniversary: return "heart.fill"
        case .samskara: return "flame.fill"
        case .memorial: return "laurel.leading"
        case .custom: return "star.circle.fill"
        }
    }
    
    public var tintColor: Color {
        switch self {
        case .birthday: return Color(red: 0.94, green: 0.76, blue: 0.42) // Vedic Gold
        case .anniversary: return Color(red: 0.94, green: 0.45, blue: 0.55) // Rose Lotus
        case .samskara: return Color(red: 0.96, green: 0.62, blue: 0.32) // Sacred Saffron
        case .memorial: return Color(red: 0.75, green: 0.75, blue: 0.85) // Moonlit Silver
        case .custom: return Color(red: 0.45, green: 0.82, blue: 0.75) // Emerald Tejas
        }
    }
    
    public var blessingGreeting: String {
        switch self {
        case .birthday:
            return "आयुष्यमस्तु! शुभ जन्मदिनम्। May your prāna and spiritual radiance flourish in this sacred Vedic year."
        case .anniversary:
            return "धर्मप्रजासम्पत्त्यर्थम्! शुभ विवाहोत्सवः। May love, harmony, and righteous dharma deepen with cosmic resonance."
        case .samskara:
            return "संस्कार-सिद्धिर्भवतु! May this sacred milestone bring purification and spiritual elevation."
        case .memorial:
            return "तृप्यध्वम्। Offering gratitude and peace to beloved ancestors on this sacred Tithi."
        case .custom:
            return "सङ्कल्पः शुभः सिद्ध्यतु! May your sacred vow and worship bear auspicious fruit."
        }
    }
}

// MARK: - User Life Event Model

public struct UserLifeEvent: Identifiable, Codable, Equatable {
    public let id: String
    public var userId: String
    public var title: String
    public var personName: String
    public var type: LifeEventType
    public var originalDate: Date
    public var vedicYear: Int            // e.g. Kali Yuga 5100
    public var vedicMasaIndex: Int       // 1 to 12 (Caitra to Phalguna)
    public var vedicMasaName: String      // e.g. "Kārtika (कार्तिक)"
    public var vedicPaksha: String       // "Śukla" or "Kṛṣṇa"
    public var vedicTithiNumber: Int     // 1 to 15
    public var vedicTithiName: String     // e.g. "Trayodaśī (त्रयोदशी)"
    public var vedicNakshatra: String    // e.g. "Revatī"
    public var notes: String
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        userId: String = "",
        title: String,
        personName: String,
        type: LifeEventType,
        originalDate: Date,
        vedicYear: Int,
        vedicMasaIndex: Int,
        vedicMasaName: String,
        vedicPaksha: String,
        vedicTithiNumber: Int,
        vedicTithiName: String,
        vedicNakshatra: String,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.personName = personName
        self.type = type
        self.originalDate = originalDate
        self.vedicYear = vedicYear
        self.vedicMasaIndex = vedicMasaIndex
        self.vedicMasaName = vedicMasaName
        self.vedicPaksha = vedicPaksha
        self.vedicTithiNumber = vedicTithiNumber
        self.vedicTithiName = vedicTithiName
        self.vedicNakshatra = vedicNakshatra
        self.notes = notes
        self.createdAt = createdAt
    }
    
    /// Full Vedic coordinate summary (e.g. "Kārtika Śukla Trayodaśī • Kali Yuga 5100")
    public var vedicFullString: String {
        "\(vedicMasaName) \(vedicPaksha) \(vedicTithiName), Kali Yuga \(vedicYear)"
    }
    
    /// Formatted Roman / Gregorian date
    public var formattedRomanDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: originalDate)
    }
}

// MARK: - Manager

@MainActor
public final class VedicLifeEventManager: ObservableObject {
    public static let shared = VedicLifeEventManager()
    
    @Published public var events: [UserLifeEvent] = []
    @Published public var isSyncing: Bool = false
    @Published public var errorMessage: String?
    
    private let userDefaultsKey = "com.muhurta.savedLifeEvents"
    private let db = Firestore.firestore()
    private let ujjainCoordinate = CLLocationCoordinate2D(latitude: 23.1765, longitude: 75.7885)
    
    private init() {
        loadLocalEvents()
        // Purge dummy sample events so user starts with clean empty sanctuary
        let hadDummy = events.contains { $0.title.contains("My Vedic Janmadina") && $0.personName == "Self" }
        if hadDummy {
            events.removeAll { $0.title.contains("My Vedic Janmadina") && $0.personName == "Self" }
            saveLocalEvents()
        }
        Task {
            await syncWithFirestore()
        }
    }
    
    // MARK: - Vedic Coordinate Converter
    
    /// Computes full Vedic coordinates from any given civil Gregorian Date.
    public func computeVedicCoordinates(for date: Date) -> (
        kaliYear: Int,
        masaIndex: Int,
        masaName: String,
        paksha: String,
        tithiNumber: Int,
        tithiName: String,
        nakshatra: String
    ) {
        let chronometry = PanchangaEngine.calculateChronometry(for: date, coordinate: ujjainCoordinate)
        
        let masaNames = [
            "Caitra (चैत्र)", "Vaiśākha (वैशाख)", "Jyeṣṭha (ज्येष्ठ)",
            "Āṣāḍha (आषाढ)", "Śrāvaṇa (श्रावण)", "Bhādrapada (भाद्रपद)",
            "Āśvina (आश्विन)", "Kārtika (कार्तिक)", "Mārgaśīrṣa (मार्गशीर्ष)",
            "Pauṣa (पौष)", "Māgha (माघ)", "Phālguna (फाल्गुन)"
        ]
        
        var foundMasaIdx = 1
        for (i, name) in masaNames.enumerated() {
            if chronometry.masa.localizedCaseInsensitiveContains(name.split(separator: " ")[0]) {
                foundMasaIdx = i + 1
                break
            }
        }
        
        let masaFullName = (foundMasaIdx >= 1 && foundMasaIdx <= 12) ? masaNames[foundMasaIdx - 1] : chronometry.masa
        
        return (
            kaliYear: chronometry.kaliYugaYear,
            masaIndex: foundMasaIdx,
            masaName: masaFullName,
            paksha: chronometry.paksha,
            tithiNumber: chronometry.tithiNumber,
            tithiName: chronometry.tithiShort,
            nakshatra: "Revatī" // Derived from celestial longitude
        )
    }
    
    // MARK: - Annual Vedic Recurrence Solver
    
    /// Finds the exact civil date in the current Vedic Year (Kali Yuga 5128)
    /// when this specific Vedic Month + Paksha + Tithi combination occurs.
    public func nextRecurrence(for event: UserLifeEvent, from referenceDate: Date = Date()) -> (
        date: Date,
        daysRemaining: Int,
        isToday: Bool,
        celebrationYear: Int
    ) {
        let calendar = Calendar.current
        let currentYearChronometry = PanchangaEngine.calculateChronometry(for: referenceDate, coordinate: ujjainCoordinate)
        let currentKali = currentYearChronometry.kaliYugaYear
        
        // Scan up to 400 days into the future starting from referenceDate
        let searchDate = calendar.startOfDay(for: referenceDate)
        
        for dayOffset in 0...400 {
            guard let candidate = calendar.date(byAdding: .day, value: dayOffset, to: searchDate) else { continue }
            // Evaluate at midday to prevent pre-dawn double day-subtraction
            guard let noonCandidate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: candidate) else { continue }
            
            let candChrono = PanchangaEngine.calculateChronometry(for: noonCandidate, coordinate: ujjainCoordinate)
            
            let candMasa = candChrono.masa.lowercased()
            let eventMasa = event.vedicMasaName.lowercased()
            let masaMatches = candMasa.contains(eventMasa.split(separator: " ")[0]) ||
                              eventMasa.contains(candMasa.split(separator: " ")[0])
            
            let pakshaMatches = candChrono.paksha == event.vedicPaksha
            let tithiMatches = candChrono.tithiNumber == event.vedicTithiNumber
            
            if masaMatches && pakshaMatches && tithiMatches {
                let diffDays = calendar.dateComponents([.day], from: calendar.startOfDay(for: referenceDate), to: calendar.startOfDay(for: candidate)).day ?? 0
                let isToday = (diffDays == 0)
                return (
                    date: candidate,
                    daysRemaining: max(0, diffDays),
                    isToday: isToday,
                    celebrationYear: candChrono.kaliYugaYear
                )
            }
        }
        
        // Fallback: approximate 1 lunar cycle away if scan fails
        let fallbackDate = calendar.date(byAdding: .day, value: 30, to: referenceDate) ?? referenceDate
        return (fallbackDate, 30, false, currentKali)
    }
    
    // MARK: - CRUD & Persistence
    
    public func addEvent(_ event: UserLifeEvent) {
        var mutableEvent = event
        if let currentUid = Auth.auth().currentUser?.uid {
            mutableEvent.userId = currentUid
        }
        events.append(mutableEvent)
        events.sort { $0.createdAt > $1.createdAt }
        saveLocalEvents()
        
        Task {
            await syncEventToFirestore(mutableEvent)
        }
    }
    
    public func updateEvent(_ event: UserLifeEvent) {
        var mutableEvent = event
        if let currentUid = Auth.auth().currentUser?.uid {
            mutableEvent.userId = currentUid
        }
        if let idx = events.firstIndex(where: { $0.id == event.id }) {
            events[idx] = mutableEvent
        } else {
            events.append(mutableEvent)
        }
        events.sort { $0.createdAt > $1.createdAt }
        saveLocalEvents()
        
        Task {
            await syncEventToFirestore(mutableEvent)
        }
    }
    
    public func deleteEvent(id: String) {
        events.removeAll { $0.id == id }
        saveLocalEvents()
        
        Task {
            await deleteEventFromFirestore(id: id)
        }
    }
    
    private func saveLocalEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadLocalEvents() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
            let decoded = try? JSONDecoder().decode([UserLifeEvent].self, from: data) {
            self.events = decoded
        }
    }
    
    // MARK: - Firestore Sync
    
    public func syncWithFirestore() async {
        guard let user = Auth.auth().currentUser else {
            print("Firestore sync: Not signed in. Skipping cloud sync.")
            return
        }
        let uid = user.uid
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // 1. Ensure user profile document exists in Firestore
            let userDocRef = db.collection("users").document(uid)
            let userPayload: [String: Any] = [
                "uid": uid,
                "email": user.email ?? "",
                "displayName": user.displayName ?? "",
                "lastActive": FieldValue.serverTimestamp()
            ]
            try await userDocRef.setData(userPayload, merge: true)
            print("Firestore: User document synced for \(uid)")
            
            // 2. Fetch remote milestones
            let snapshot = try await userDocRef.collection("life_events").getDocuments()
            var cloudEvents: [UserLifeEvent] = []
            
            for doc in snapshot.documents {
                let data = doc.data()
                if let jsonData = try? JSONSerialization.data(withJSONObject: data),
                   let event = try? JSONDecoder().decode(UserLifeEvent.self, from: jsonData) {
                    cloudEvents.append(event)
                }
            }
            
            if !cloudEvents.isEmpty {
                // Merge cloud and local
                var merged = self.events
                for cloudEvent in cloudEvents {
                    if !merged.contains(where: { $0.id == cloudEvent.id }) {
                        merged.append(cloudEvent)
                    }
                }
                self.events = merged
                saveLocalEvents()
            } else {
                // Push local events to cloud
                for event in self.events {
                    await syncEventToFirestore(event)
                }
            }
            print("Firestore: Sync completed successfully. Total events: \(self.events.count)")
        } catch {
            print("Firestore sync error: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func syncEventToFirestore(_ event: UserLifeEvent) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let data = try? JSONEncoder().encode(event),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        
        do {
            try await db.collection("users").document(uid).collection("life_events").document(event.id).setData(dict, merge: true)
            print("Firestore: Successfully saved event '\(event.title)' (\(event.id)) to cloud")
        } catch {
            print("Failed to sync event \(event.id) to Firestore: \(error.localizedDescription)")
        }
    }
    
    private func deleteEventFromFirestore(id: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await db.collection("users").document(uid).collection("life_events").document(id).delete()
        } catch {
            print("Failed to delete event from Firestore: \(error.localizedDescription)")
        }
    }
}
