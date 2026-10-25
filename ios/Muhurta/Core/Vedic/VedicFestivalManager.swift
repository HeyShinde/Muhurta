//
//  VedicFestivalManager.swift
//  Muhurta
//
//  Authentic Vedic Festival & Vrata Engine.
//  Accurately identifies major annual festivals (Deepavali, Navaratri, Janmashtami, etc.)
//  and recurring monthly spiritual vratas (Ekadashi, Pradosham, Sankashti Chaturthi, Shivaratri, Purnima, Amavasya).
//

import Foundation
import CoreLocation

public enum FestivalCategory: String, CaseIterable, Sendable {
    case majorFestival = "Major Festivals"
    case monthlyVrata = "Monthly Vratas"
    case solarTransit = "Sūrya Saṅkrānti"
}

public struct VedicFestival: Identifiable, Sendable {
    public let id: String
    public let nameEnglish: String
    public let nameSanskrit: String
    public let date: Date
    public let iconSymbol: String // SF Symbol or Emoji
    public let category: FestivalCategory
    public let deity: String
    public let description: String
    public let colorHex: String
}

public enum VedicFestivalManager {
    
    /// Detects all festivals and holy observances for a given date and location.
    public static func festivals(for date: Date, coordinate: CLLocationCoordinate2D) -> [VedicFestival] {
        var results: [VedicFestival] = []
        
        let calendar = Calendar.current
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        let vDate = PanchangaEngine.vedicDate(for: noon, coordinate: coordinate)
        
        guard let p = PanchangaEngine.calculatePanchanga(for: vDate, coordinate: coordinate) else {
            return []
        }
        
        let tithiNum = p.chronometry.tithiNumber // 1..15
        let isShukla = p.chronometry.paksha.contains("Śukla") || p.chronometry.paksha.contains("Shukla")
        let masa = p.chronometry.masa
        let weekday = p.vara.weekdayNumber // 1=Sun, 2=Mon... 7=Sat
        
        // 1. Recurring Monthly Vratas
        
        // Ekādaśī (11th Tithi)
        if tithiNum == 11 {
            let ekadashiName = getEkadashiName(masa: masa, isShukla: isShukla)
            results.append(VedicFestival(
                id: "ekadashi_\(date.timeIntervalSince1970)",
                nameEnglish: "\(ekadashiName) Ekādaśī",
                nameSanskrit: "\(ekadashiName) एकादशी",
                date: date,
                iconSymbol: "🌿",
                category: .monthlyVrata,
                deity: "Śrī Mahāviṣṇu",
                description: "Sacred day of fasting and meditation dedicated to Lord Vishnu. Calms the mind and purifies prana.",
                colorHex: "#52B788"
            ))
        }
        
        // Pradoṣam (13th Tithi)
        if tithiNum == 13 {
            let pradoshamPrefix = (weekday == 7) ? "Śani " : ((weekday == 2) ? "Soma " : "")
            results.append(VedicFestival(
                id: "pradosham_\(date.timeIntervalSince1970)",
                nameEnglish: "\(pradoshamPrefix)Pradoṣa Vratam",
                nameSanskrit: "\(pradoshamPrefix)प्रदोष व्रत",
                date: date,
                iconSymbol: "🔱",
                category: .monthlyVrata,
                deity: "Bhagavān Śiva",
                description: "Twilight window of supreme auspiciousness when Lord Shiva dances the Ananda Tandava. Ideal for bilva leaf offering.",
                colorHex: "#FF9F1C"
            ))
        }
        
        // Saṅkaṣṭa Caturthī (Krishna 4th) & Vināyaka Caturthī (Shukla 4th)
        if tithiNum == 4 {
            if !isShukla {
                results.append(VedicFestival(
                    id: "sankashti_\(date.timeIntervalSince1970)",
                    nameEnglish: "Saṅkaṣṭa Caturthī",
                    nameSanskrit: "संकष्ट चतुर्थी",
                    date: date,
                    iconSymbol: "🐘",
                    category: .monthlyVrata,
                    deity: "Lord Gaṇeśa",
                    description: "Fasting day for overcoming all life hurdles and obstacles, concluded with moonrise darshanam.",
                    colorHex: "#F77F00"
                ))
            } else if masa != "Bhādrapada" { // Vinayaka Chaturthi in general months
                results.append(VedicFestival(
                    id: "vinayaka_chaturthi_\(date.timeIntervalSince1970)",
                    nameEnglish: "Māsa Vināyaka Caturthī",
                    nameSanskrit: "विनायक चतुर्थी",
                    date: date,
                    iconSymbol: "🐘",
                    category: .monthlyVrata,
                    deity: "Lord Gaṇeśa",
                    description: "Monthly celebration invoking Lord Ganesha's blessings for auspicious wisdom and intellect.",
                    colorHex: "#F77F00"
                ))
            }
        }
        
        // Māsa Śivarātri (Krishna 14th)
        if tithiNum == 14 && !isShukla && masa != "Māgha" {
            results.append(VedicFestival(
                id: "masa_shivaratri_\(date.timeIntervalSince1970)",
                nameEnglish: "Māsa Śivarātri",
                nameSanskrit: "मास शिवरात्रि",
                date: date,
                iconSymbol: "🔱",
                category: .monthlyVrata,
                deity: "Lord Śiva",
                description: "Monthly vigil honoring Shiva consciousness before the new moon. Auspicious for chanting Om Namah Shivaya.",
                colorHex: "#7209B7"
            ))
        }
        
        // Pūrṇimā (15th Tithi Shukla)
        if tithiNum == 15 && isShukla {
            let purnimaName = getPurnimaTitle(masa: masa)
            results.append(VedicFestival(
                id: "purnima_\(date.timeIntervalSince1970)",
                nameEnglish: "\(purnimaName) Pūrṇimā",
                nameSanskrit: "पूर्णिमा (सत्यनारायण पूजा)",
                date: date,
                iconSymbol: "🌕",
                category: .monthlyVrata,
                deity: "Śrī Satyanārāyaṇa / Goddess Lakṣmī",
                description: "Full moon illumination. Summit of prana and cosmic clarity, ideal for Satyanarayana Vrata.",
                colorHex: "#E0AAFF"
            ))
        }
        
        // Amāvāsyā (30th Tithi / Krishna 15th)
        if tithiNum == 15 && !isShukla && masa != "Kārtika" {
            results.append(VedicFestival(
                id: "amavasya_\(date.timeIntervalSince1970)",
                nameEnglish: "Amāvāsyā (New Moon)",
                nameSanskrit: "दर्श अमावस्या",
                date: date,
                iconSymbol: "🌑",
                category: .monthlyVrata,
                deity: "Pitṛ Devatās",
                description: "Deep inward stillness and ancestral thanksgiving (Pitru Tarpana). Avoid worldly beginnings; practice meditation.",
                colorHex: "#6C757D"
            ))
        }
        
        // 2. Major Annual Festivals based on Masa & Tithi
        
        // Kārtika Month
        if masa == "Kārtika" {
            if !isShukla && tithiNum == 4 {
                results.append(VedicFestival(
                    id: "karwa_chauth",
                    nameEnglish: "Karwa Chauth",
                    nameSanskrit: "करवा चौथ (करक चतुर्थी)",
                    date: date,
                    iconSymbol: "🌙",
                    category: .majorFestival,
                    deity: "Śrī Gaurī & Gaṇeśa",
                    description: "Sacred fast observed by spouses for health, longevity, and family harmony.",
                    colorHex: "#E63946"
                ))
            } else if !isShukla && tithiNum == 13 {
                results.append(VedicFestival(
                    id: "dhanteras",
                    nameEnglish: "Dhanteras (Dhana Trayodaśī)",
                    nameSanskrit: "धन्तेरास् (धन त्रयोदशी)",
                    date: date,
                    iconSymbol: "🪙",
                    category: .majorFestival,
                    deity: "Lord Dhanvantari & Kubera",
                    description: "Invocation of Lord Dhanvantari for radiant health, and Kubera/Lakshmi for prosperity.",
                    colorHex: "#FFD166"
                ))
            } else if !isShukla && tithiNum == 14 {
                results.append(VedicFestival(
                    id: "naraka_chaturdashi",
                    nameEnglish: "Naraka Caturdaśī (Choti Diwali)",
                    nameSanskrit: "नरक चतुर्दशी (रूप चौदस)",
                    date: date,
                    iconSymbol: "🪔",
                    category: .majorFestival,
                    deity: "Lord Kṛṣṇa & Kālī",
                    description: "Victory of Divine Light over darkness and ignorance. Auspicious Abhyanga snana (herbal oil bath) before dawn.",
                    colorHex: "#F77F00"
                ))
            } else if !isShukla && tithiNum == 15 {
                results.append(VedicFestival(
                    id: "diwali",
                    nameEnglish: "Dīpāvalī (Lakṣmī Pūjā)",
                    nameSanskrit: "दीपावली (महालक्ष्मी पूजनम्)",
                    date: date,
                    iconSymbol: "🪔",
                    category: .majorFestival,
                    deity: "Mahālakṣmī & Gaṇeśa",
                    description: "Supreme festival of lights illuminating inner consciousness, welcomed with earthen lamps (diyas) and joy.",
                    colorHex: "#FFB703"
                ))
            } else if isShukla && tithiNum == 1 {
                results.append(VedicFestival(
                    id: "govardhan_puja",
                    nameEnglish: "Govardhana Pūjā / Annakūṭa",
                    nameSanskrit: "गोवर्धन पूजा / अन्नकूट",
                    date: date,
                    iconSymbol: "🏔️",
                    category: .majorFestival,
                    deity: "Śrī Kṛṣṇa",
                    description: "Gratitude to Mother Nature, cows, and the holy Govardhana hill.",
                    colorHex: "#06D6A0"
                ))
            } else if isShukla && tithiNum == 2 {
                results.append(VedicFestival(
                    id: "bhai_dooj",
                    nameEnglish: "Bhrātṛ Dvitīyā (Bhai Dooj)",
                    nameSanskrit: "भाई दूज (यम द्वितीया)",
                    date: date,
                    iconSymbol: "🌸",
                    category: .majorFestival,
                    deity: "Yama & Yamunā",
                    description: "Affectionate bond between sisters and brothers, celebrating protection and longevity.",
                    colorHex: "#EF476F"
                ))
            } else if isShukla && tithiNum == 11 {
                results.append(VedicFestival(
                    id: "tulsi_vivah",
                    nameEnglish: "Devutthāna Ekādaśī & Tulasī Vivāha",
                    nameSanskrit: "देवोत्थान एकादशी / तुलसी विवाह",
                    date: date,
                    iconSymbol: "🌿",
                    category: .majorFestival,
                    deity: "Tulasī Devī & Śālagrāma",
                    description: "Awakening of Lord Vishnu from yoga-nidra and the ceremonial wedding of sacred Tulasi.",
                    colorHex: "#2A9D8F"
                ))
            }
        }
        
        // Āśvina Month
        if masa == "Āśvina" {
            if isShukla && tithiNum >= 1 && tithiNum <= 9 {
                let dayNum = tithiNum
                results.append(VedicFestival(
                    id: "navaratri_day_\(dayNum)",
                    nameEnglish: "Śāradīya Navarātri (Day \(dayNum))",
                    nameSanskrit: "शारदीय नवरात्रि (दिवस \(dayNum))",
                    date: date,
                    iconSymbol: "🌺",
                    category: .majorFestival,
                    deity: "Navadurgā",
                    description: "Nine nights honoring Supreme Shakti, invoking strength, inner victory, and spiritual purity.",
                    colorHex: "#D90429"
                ))
            } else if isShukla && tithiNum == 10 {
                results.append(VedicFestival(
                    id: "vijayadashami",
                    nameEnglish: "Vijayadaśamī / Dussehra",
                    nameSanskrit: "विजयादशमी / दशहरा",
                    date: date,
                    iconSymbol: "🏹",
                    category: .majorFestival,
                    deity: "Śrī Rāma & Devī Durgā",
                    description: "Triumph of Dharma over adharma. Unmatched day to begin studies, new instruments, and auspicious ventures.",
                    colorHex: "#F77F00"
                ))
            }
        }
        
        // Bhādrapada Month
        if masa == "Bhādrapada" {
            if isShukla && tithiNum == 4 {
                results.append(VedicFestival(
                    id: "ganesh_chaturthi",
                    nameEnglish: "Śrī Gaṇeśa Caturthī",
                    nameSanskrit: "श्री गणेश चतुर्थी",
                    date: date,
                    iconSymbol: "🐘",
                    category: .majorFestival,
                    deity: "Lord Gaṇapati",
                    description: "Grand appearance day of Lord Ganesha, embodiment of divine wisdom, intellect, and remover of obstacles.",
                    colorHex: "#E76F51"
                ))
            }
        }
        
        // Śrāvaṇa Month
        if masa == "Śrāvaṇa" {
            if !isShukla && tithiNum == 8 {
                results.append(VedicFestival(
                    id: "janmashtami",
                    nameEnglish: "Śrī Kṛṣṇa Janmāṣṭamī",
                    nameSanskrit: "श्रीकृष्ण जन्माष्टमी",
                    date: date,
                    iconSymbol: "🦚",
                    category: .majorFestival,
                    deity: "Bhagavān Śrī Kṛṣṇa",
                    description: "Midnight advent of Lord Sri Krishna, supreme teacher of the Bhagavad Gita and lord of divine love.",
                    colorHex: "#457B9D"
                ))
            } else if isShukla && tithiNum == 15 {
                results.append(VedicFestival(
                    id: "raksha_bandhan",
                    nameEnglish: "Rakṣā Bandhan & Upākarma",
                    nameSanskrit: "रक्षा बन्धन / श्रावणी उपाकर्म",
                    date: date,
                    iconSymbol: "🧵",
                    category: .majorFestival,
                    deity: "Indra & Śacī",
                    description: "Sacred thread of protection and renewal of Vedic study (Upakarma).",
                    colorHex: "#E9C46A"
                ))
            }
        }
        
        // Caitra Month
        if masa == "Caitra" {
            if isShukla && tithiNum == 1 {
                results.append(VedicFestival(
                    id: "yugadi_gudi_padwa",
                    nameEnglish: "Yugādi / Guḍhī Pāḍvā (Vedic New Year)",
                    nameSanskrit: "युगादि / गुढीपाडवा (नवसंवत्सर)",
                    date: date,
                    iconSymbol: "☀️",
                    category: .majorFestival,
                    deity: "Brahmā & Sūrya",
                    description: "Cosmic beginning of the new Vedic Samvatsara. Welcomed with Neem and Jaggery symbolizing balance.",
                    colorHex: "#F4A261"
                ))
            } else if isShukla && tithiNum == 9 {
                results.append(VedicFestival(
                    id: "rama_navami",
                    nameEnglish: "Śrī Rāma Navamī",
                    nameSanskrit: "श्रीराम नवमी",
                    date: date,
                    iconSymbol: "🏹",
                    category: .majorFestival,
                    deity: "Maryādā Puruṣottama Śrī Rāma",
                    description: "Advent of Sri Rama at midday in Abhijit Muhurta, establishing righteous dharma and compassion.",
                    colorHex: "#E76F51"
                ))
            }
        }
        
        // Vaiśākha Month
        if masa == "Vaiśākha" {
            if isShukla && tithiNum == 3 {
                results.append(VedicFestival(
                    id: "akshaya_tritiya",
                    nameEnglish: "Akṣaya Tṛtīyā",
                    nameSanskrit: "अक्षय तृतीया",
                    date: date,
                    iconSymbol: "✨",
                    category: .majorFestival,
                    deity: "Śrī Mahāviṣṇu & Lakṣmī",
                    description: "Day of imperishable fortune and merit. Any spiritual sadhana or virtuous deed performed today yields eternal blessings.",
                    colorHex: "#F39C12"
                ))
            }
        }
        
        // Māgha Month
        if masa == "Māgha" {
            if !isShukla && tithiNum == 14 {
                results.append(VedicFestival(
                    id: "maha_shivaratri",
                    nameEnglish: "Mahā Śivarātri",
                    nameSanskrit: "महा शिवरात्रि",
                    date: date,
                    iconSymbol: "🔱",
                    category: .majorFestival,
                    deity: "Sadāśiva",
                    description: "Supreme night of Shiva's Lingodbhava. Vigil and meditation through the 4 Prahāras dissolve karmic residues.",
                    colorHex: "#5A189A"
                ))
            }
        }
        
        // Phālguna Month
        if masa == "Phālguna" {
            if isShukla && tithiNum == 15 {
                results.append(VedicFestival(
                    id: "holi",
                    nameEnglish: "Holikā Dahan & Holī",
                    nameSanskrit: "होलिका दहन / होली",
                    date: date,
                    iconSymbol: "🎨",
                    category: .majorFestival,
                    deity: "Bhagavān Narasiṁha & Prahlāda",
                    description: "Victory of innocent devotion over tyranny, celebrated with holy bonfire and vibrant joyful colors.",
                    colorHex: "#D90429"
                ))
            }
        }
        
        // Makara Sankranti (around Jan 14-15)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        if month == 1 && (day == 14 || day == 15) {
            results.append(VedicFestival(
                id: "makara_sankranti",
                nameEnglish: "Makara Saṅkrānti / Pongal",
                nameSanskrit: "मकर संक्रान्ति / उत्तरायण",
                date: date,
                iconSymbol: "☀️",
                category: .solarTransit,
                deity: "Sūrya Nārāyaṇa",
                description: "Sun begins its northern celestial trajectory (Uttarāyaṇa). Auspicious for Surya upasana, sesame offerings, and gratitude.",
                colorHex: "#FFB703"
            ))
        }
        
        return results
    }
    
    /// Returns the badge symbol for a date cell in the monthly calendar grid.
    public static func badgeSymbol(for date: Date, coordinate: CLLocationCoordinate2D) -> String? {
        let f = festivals(for: date, coordinate: coordinate)
        if let first = f.first {
            return first.iconSymbol
        }
        return nil
    }
    
    private static func getEkadashiName(masa: String, isShukla: Bool) -> String {
        switch masa {
        case "Kārtika": return isShukla ? "Prabodhini" : "Rama"
        case "Āśvina": return isShukla ? "Papankusha" : "Indira"
        case "Bhādrapada": return isShukla ? "Parivartini" : "Aja"
        case "Śrāvaṇa": return isShukla ? "Pavitropana" : "Kamada"
        case "Āṣāḍha": return isShukla ? "Devshayani" : "Yogini"
        case "Jyeṣṭha": return isShukla ? "Nirjala" : "Apara"
        case "Vaiśākha": return isShukla ? "Mohini" : "Varuthini"
        case "Caitra": return isShukla ? "Kamada" : "Papmochani"
        case "Phālguna": return isShukla ? "Amalaki" : "Vijaya"
        case "Māgha": return isShukla ? "Jaya" : "Shattila"
        case "Pauṣa": return isShukla ? "Putrada" : "Saphala"
        case "Mārgaśīrṣa": return isShukla ? "Mokshada (Gita Jayanti)" : "Utpanna"
        default: return isShukla ? "Śukla" : "Kṛṣṇa"
        }
    }
    
    private static func getPurnimaTitle(masa: String) -> String {
        switch masa {
        case "Āśvina": return "Śarad"
        case "Kārtika": return "Tripurāri (Dev Diwali)"
        case "Āṣāḍha": return "Guru"
        case "Śrāvaṇa": return "Śrāvaṇī"
        case "Mārgaśīrṣa": return "Dattātreya"
        case "Phālguna": return "Holikā"
        case "Vaiśākha": return "Buddha"
        default: return masa
        }
    }
}
