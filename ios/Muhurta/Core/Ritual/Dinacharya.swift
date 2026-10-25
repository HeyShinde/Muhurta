//
//  Dinacharya.swift
//  Muhurta
//
//  Authentic Ayurvedic Morning Routine (Dinacharya) structured into three sacred stages:
//  Awakening, Sensory Cleansing, and Prāṇic Vitality.
//

import SwiftUI

public enum DinacharyaPhase: String, CaseIterable, Identifiable, Sendable {
    case awakening = "Awakening & Grounding"
    case cleansing = "Sensory Purification"
    case sadhana = "Vitality & Sadhana"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .awakening: return "sun.horizon.fill"
        case .cleansing: return "drop.fill"
        case .sadhana: return "figure.mind.and.body"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .awakening: return "Conscious pre-dawn awakening • Neurological activation"
        case .cleansing: return "Clearing nocturnal Ama (metabolic toxins) from sensory gates"
        case .sadhana: return "Circulating solar Prāna, activating Agni, and mental stillness"
        }
    }
}

public struct DinacharyaStep: Identifiable, Sendable {
    public let id: String
    public let phase: DinacharyaPhase
    public let emoji: String
    public let iconName: String
    public let titleSanskrit: String
    public let titleEnglish: String
    public let subtitle: String
    public let benefits: String
    public let instructions: String
    public let materials: String
    public let durationMinutes: Int
    public var isCompleted: Bool = false
    
    public static var standardRoutine: [DinacharyaStep] { authenticRoutine }
    
    public static let authenticRoutine: [DinacharyaStep] = [
        // MARK: - Phase 1: Awakening & Grounding
        DinacharyaStep(
            id: "kara_darshana",
            phase: .awakening,
            emoji: "🤲",
            iconName: "hand.raised.fill",
            titleSanskrit: "Kara Darshanam (करदर्शनम्)",
            titleEnglish: "Gazing Upon the Palms",
            subtitle: "Awakening the neurological motor centers",
            benefits: "Stimulates cortical representations of the hands in the brain, centering awareness into self-sovereignty before interacting with the world.",
            instructions: "Upon opening your eyes in bed, cup your palms together before your face. Recite the ancient mantra: 'Karagre Vasate Lakshmi, Karamadhye Saraswati, Karamule Tu Govinda, Prabhate Karadarshanam.'",
            materials: "None required. Complete while lying or sitting in stillness.",
            durationMinutes: 1
        ),
        DinacharyaStep(
            id: "bhumi_vandana",
            phase: .awakening,
            emoji: "🌍",
            iconName: "globe.americas.fill",
            titleSanskrit: "Bhūmi Vandanā (भूमि वन्दना)",
            titleEnglish: "Reverence to the Earth",
            subtitle: "Bio-electrical grounding and gratitude",
            benefits: "Discharges static biological tension, grounds Vata restlessness, and establishes mindful physical connection to the environment.",
            instructions: "Before stepping onto the floor, touch the ground with your right hand and bow your head gently, asking forgiveness for touching the sacred Earth with your feet throughout the day.",
            materials: "Bare floor or natural fiber rug.",
            durationMinutes: 1
        ),
        DinacharyaStep(
            id: "usha_pana",
            phase: .awakening,
            emoji: "💧",
            iconName: "drop.fill",
            titleSanskrit: "Uṣaḥ Pāna (उषःपानम्)",
            titleEnglish: "Dawn Copper Water",
            subtitle: "Peristalsis ignition and cellular hydration",
            benefits: "Washes nocturnal residues from the gastrointestinal lining, stimulates the gastrocolic reflex for natural evacuation, and supports kidney filtration.",
            instructions: "Drink 400–600ml of lukewarm water stored overnight in a pure copper vessel (Tāmra Jal). Drink while seated calmly; do not gulp standing up.",
            materials: "Pure copper cup or vessel with room-temperature water.",
            durationMinutes: 3
        ),
        
        // MARK: - Phase 2: Sensory Cleansing
        DinacharyaStep(
            id: "jihwa_nirlekhana",
            phase: .cleansing,
            emoji: "🌿",
            iconName: "mouth.fill",
            titleSanskrit: "Jihvā Nirlekhana (जिह्वा निर्लेखनम्)",
            titleEnglish: "Copper Tongue Scraping",
            subtitle: "Clearing nocturnal Ama (metabolic toxins)",
            benefits: "Removes toxic bacterial biofilm (Ama) accumulated overnight, awakens digestive enzyme secretion, and enhances taste bud sensitivity.",
            instructions: "Relax your tongue. Hold both ends of the curved copper scraper. Gently scrape from the far back of the tongue forward in 7–10 smooth strokes. Rinse thoroughly.",
            materials: "Pure copper or silver U-shaped tongue scraper.",
            durationMinutes: 2
        ),
        DinacharyaStep(
            id: "gandusha",
            phase: .cleansing,
            emoji: "✨",
            iconName: "sparkles",
            titleSanskrit: "Gaṇḍūṣa / Kavaḷa (गण्डूषम्)",
            titleEnglish: "Warm Oil Pulling",
            subtitle: "Strengthening teeth, jaw & oral microbiome",
            benefits: "Strengthens gums and jaw musculature, draws lipophilic toxins from the mucosal membrane, and reduces systemic Pitta heat.",
            instructions: "Place 1 tablespoon of warm, unrefined sesame or virgin coconut oil into your mouth. Swish and pull through your teeth gently for 5–10 minutes until milky white. Spit into trash (not plumbing).",
            materials: "Cold-pressed organic sesame oil or coconut oil.",
            durationMinutes: 6
        ),
        DinacharyaStep(
            id: "netra_prakshalana",
            phase: .cleansing,
            emoji: "👁️",
            iconName: "eye.fill",
            titleSanskrit: "Netra Prakṣālana (नेत्र प्रक्षालनम्)",
            titleEnglish: "Cool Eye Rinse",
            subtitle: "Subduing ocular Pitta (Alochaka Pitta)",
            benefits: "Soothes optic strain, pacifies morning eye dryness, and sharpens visual acuity before daylight exposure.",
            instructions: "Hold a mouthful of clean room-temperature water (which pushes optic pressure outward) while splashing cool water or pure rosewater over open eyes.",
            materials: "Cool filtered water or organic rosewater eye cups.",
            durationMinutes: 2
        ),
        DinacharyaStep(
            id: "nasya",
            phase: .cleansing,
            emoji: "👃",
            iconName: "lungs.fill",
            titleSanskrit: "Pratimarsha Nasya (प्रतिमर्श नस्यम्)",
            titleEnglish: "Nasal Herbal Drops",
            subtitle: "Lubricating the gateway to consciousness",
            benefits: "In Ayurveda, 'the nose is the direct doorway to the brain' (Nasa Hi Shirso Dvaram). Lubricates sinus mucosa and enhances mental focus.",
            instructions: "Lie back or tilt your head. Place 2 drops of warm Anu Taila or melted pure Ghee into each nostril. Inhale deeply, then gently massage the bridge of your nose.",
            materials: "Anu Taila, sesame oil, or grass-fed organic ghee.",
            durationMinutes: 2
        ),
        
        // MARK: - Phase 3: Vitality & Sadhana
        DinacharyaStep(
            id: "abhyanga",
            phase: .sadhana,
            emoji: "🧴",
            iconName: "hand.tap.fill",
            titleSanskrit: "Abhyaṅga (अभ्यङ्गम्)",
            titleEnglish: "Warm Oil Self-Massage",
            subtitle: "Calming Vata, nourishing longevity (Ojas)",
            benefits: "Deeply settles the sympathetic nervous system, lubricates joints, increases lymphatic drainage, and shields against aging.",
            instructions: "Warm 2 tablespoons of sesame oil. Use long strokes on long bones and circular motions over joints, moving rhythmically toward the heart for 5–10 minutes before your warm shower.",
            materials: "Warm sesame oil (for Vata/Kapha) or coconut oil (for Pitta).",
            durationMinutes: 10
        ),
        DinacharyaStep(
            id: "surya_namaskar",
            phase: .sadhana,
            emoji: "☀️",
            iconName: "sun.max.fill",
            titleSanskrit: "Sūrya Namaskāra (सूर्य नमस्कारः)",
            titleEnglish: "Solar Salutations",
            subtitle: "Harmonizing circadian rhythms to natural light",
            benefits: "Mobilizes all major joints, activates cardiovascular circulation, stimulates digestive Agni, and synchronizes internal biological clocks with cosmic sunrise.",
            instructions: "Face toward the eastern horizon. Perform 6 to 12 slow, breath-synchronized cycles of Sun Salutations, honoring the solar vitality of the day.",
            materials: "Yoga mat or clean natural fiber surface.",
            durationMinutes: 8
        ),
        DinacharyaStep(
            id: "pranayama_dhyana",
            phase: .sadhana,
            emoji: "🧘",
            iconName: "wind",
            titleSanskrit: "Prāṇāyāma & Dhyāna (प्राणायामः)",
            titleEnglish: "Nāḍī Śodhana & Meditation",
            subtitle: "Balancing solar (Pingala) and lunar (Ida) nadis",
            benefits: "Directly down-regulates cortisol, optimizes blood oxygen saturation, balances cerebral hemisphere activity, and cultivates unshakable Sattvic stillness.",
            instructions: "Sit upright with spine erect. Practice 5–10 minutes of Nadi Shodhana (alternate nostril breathing) followed by silent awareness in meditation.",
            materials: "Meditation cushion or steady seated chair.",
            durationMinutes: 10
        )
    ]
}
