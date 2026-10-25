//
//  SpiritualIdentityView.swift
//  Muhurta
//
//  Spiritual Identity Sanctuary Card (वैदिक परिचय) displaying Gotra,
//  Janma Nakshatra, Janma Rāśi, and Iṣṭa Devatā with a sacred edit sheet.
//

import SwiftUI

public enum VedicConstants {
    public static let gotras = [
        "Bhāradvāja (भारद्वाज)",
        "Kaśyapa (कश्यप)",
        "Vasiṣṭha (वसिष्ठ)",
        "Viśvāmitra (विश्वामित्र)",
        "Garga (गर्ग)",
        "Jamadagni (जमदग्नि)",
        "Gautama (गौतम)",
        "Atri (अत्रि)",
        "Agastya (अगस्त्य)",
        "Harita (हारीत)",
        "Śrīvatsa (श्रीवत्स)",
        "Parāśara (पराशर)",
        "Mudgala (मुद्गल)",
        "Kauṇḍinya (कौण्डिन्य)",
        "Sandilya (शाण्डिल्य)",
        "Not Specified"
    ]
    
    public static let nakshatras = [
        "Aśvinī (अश्विनी)", "Bharaṇī (भरणी)", "Kṛttikā (कृत्तिका)",
        "Rohiṇī (रोहिणी)", "Mṛgaśīrṣā (मृगशीर्षा)", "Ārdrā (आर्द्रा)",
        "Punarvasu (पुनर्वसु)", "Puṣya (पुष्य)", "Āśleṣā (आश्लेषा)",
        "Maghā (मघा)", "Pūrvaphālgunī (पूर्वफाल्गुनी)", "Uttaraphālgunī (उत्तरफाल्गुनी)",
        "Hasta (हस्त)", "Citrā (चित्रा)", "Svātī (स्वाती)",
        "Viśākhā (विशाखा)", "Anurādhā (अनुराधा)", "Jyeṣṭhā (ज्येष्ठा)",
        "Mūla (मूल)", "Pūrvāṣāḍhā (पूर्वाषाढा)", "Uttarāṣāḍhā (उत्तराषाढा)",
        "Śravaṇa (श्रवण)", "Dhaniṣṭhā (धनिष्ठा)", "Śatabhiṣaj (शतभिषज्)",
        "Pūrvabhādrapadā (पूर्वभाद्रपदा)", "Uttarabhādrapadā (उत्तरभाद्रपदा)", "Revatī (रेवती)"
    ]
    
    public static let rashis = [
        "Meṣa (Aries • मेष)",
        "Vṛṣabha (Taurus • वृषभ)",
        "Mithuna (Gemini • मिथुन)",
        "Karka (Cancer • कर्क)",
        "Siṁha (Leo • सिंह)",
        "Kanyā (Virgo • कन्या)",
        "Tulā (Libra • तुला)",
        "Vṛścika (Scorpio • वृश्चिक)",
        "Dhanu (Sagittarius • धनु)",
        "Makara (Capricorn • मकर)",
        "Kumbha (Aquarius • कुम्भ)",
        "Mīna (Pisces • मीन)"
    ]
    
    public static let ishtaDevatas = [
        "Śrī Kṛṣṇa (श्रीकृष्ण)",
        "Śiva Mahādeva (शिव महादेव)",
        "Śrī Rāma (श्रीराम)",
        "Devī Durgā (देवी दुर्गा)",
        "Bhagavān Gaṇeśa (भगवान गणेश)",
        "Śrī Hanumān (श्रीहनुमान)",
        "Mahāviṣṇu (महाविष्णु)",
        "Devī Lakṣmī (देवी लक्ष्मी)",
        "Devī Sarasvatī (देवी सरस्वती)",
        "Śrī Subrahmaṇya / Kārtikeya (श्री सुब्रह्मण्य)",
        "Sūrya Nārāyaṇa (सूर्यनारायण)",
        "Śrī Dattātreya (श्री दत्तात्रेय)"
    ]
}

public struct SpiritualIdentityCard: View {
    @AppStorage("vedic_seeker_name") private var seekerName: String = "Seeker"
    @AppStorage("vedic_gotra") private var gotra: String = "Bhāradvāja (भारद्वाज)"
    @AppStorage("vedic_nakshatra") private var nakshatra: String = "Rohiṇī (रोहिणी)"
    @AppStorage("vedic_rashi") private var rashi: String = "Vṛṣabha (Taurus • वृषभ)"
    @AppStorage("vedic_ishta_devata") private var ishtaDevata: String = "Śrī Kṛṣṇa (श्रीकृष्ण)"
    
    @State private var showingEditSheet = false
    
    private let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
    private let darkGold = Color(red: 0.82, green: 0.60, blue: 0.22)
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with Sacred Om & Edit Button
            HStack {
                HStack(spacing: 8) {
                    Text("ॐ")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(gold)
                    
                    Text("SPIRITUAL IDENTITY (वैदिक परिचय)")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundColor(gold)
                }
                
                Spacer()
                
                Button {
                    showingEditSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                        Text("Edit")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(gold.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(gold.opacity(0.3), lineWidth: 1))
                }
            }
            
            // Seeker Name & Cosmic Lineage
            VStack(alignment: .leading, spacing: 3) {
                Text(seekerName.isEmpty ? "Seeker" : seekerName)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                Text("Gotra: \(gotra)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(gold.opacity(0.9))
            }
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // 3-Column Attributes Grid
            HStack(spacing: 8) {
                // Nakshatra Pill
                VStack(alignment: .leading, spacing: 3) {
                    Text("NAKSHATRA")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundColor(.secondary)
                    
                    Text(cleanName(nakshatra))
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // Rāśi Pill
                VStack(alignment: .leading, spacing: 3) {
                    Text("JANMA RĀŚI")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundColor(.secondary)
                    
                    Text(cleanName(rashi))
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // Iṣṭa Devatā Pill
                VStack(alignment: .leading, spacing: 3) {
                    Text("IṢṬA DEVATĀ")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundColor(.secondary)
                    
                    Text(cleanName(ishtaDevata))
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundColor(gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(gold.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.10, green: 0.11, blue: 0.16), Color(red: 0.07, green: 0.08, blue: 0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [gold.opacity(0.4), darkGold.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .sheet(isPresented: $showingEditSheet) {
            EditSpiritualIdentitySheet()
        }
    }
    
    private func cleanName(_ raw: String) -> String {
        raw.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespaces) ?? raw
    }
}

public struct EditSpiritualIdentitySheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("vedic_seeker_name") private var seekerName: String = "Seeker"
    @AppStorage("vedic_gotra") private var gotra: String = "Bhāradvāja (भारद्वाज)"
    @AppStorage("vedic_nakshatra") private var nakshatra: String = "Rohiṇī (रोहिणी)"
    @AppStorage("vedic_rashi") private var rashi: String = "Vṛṣabha (Taurus • वृषभ)"
    @AppStorage("vedic_ishta_devata") private var ishtaDevata: String = "Śrī Kṛṣṇa (श्रीकृष्ण)"
    
    private let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Explanatory note
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                                .foregroundColor(gold)
                            Text("Your spiritual identity aligns personalized Sankalpas, Muhūrta calculations, and sacred life milestones.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.75))
                        }
                        .padding(14)
                        .background(gold.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(gold.opacity(0.2), lineWidth: 1))
                        
                        // Name Input Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SPIRITUAL / GIVEN NAME")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(1.2)
                                .foregroundColor(gold)
                            
                            TextField("Enter your name", text: $seekerName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        .padding(16)
                        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        
                        // Gotra Picker Card
                        pickerSection(title: "VEDIC GOTRA (गोत्र ऋषि)", selection: $gotra, options: VedicConstants.gotras)
                        
                        // Nakshatra Picker Card
                        pickerSection(title: "JANMA NAKSHATRA (जन्म नक्षत्र)", selection: $nakshatra, options: VedicConstants.nakshatras)
                        
                        // Rāśi Picker Card
                        pickerSection(title: "JANMA RĀŚI (जन्म राशि)", selection: $rashi, options: VedicConstants.rashis)
                        
                        // Iṣṭa Devatā Picker Card
                        pickerSection(title: "IṢṬA DEVATĀ (इष्ट देवता)", selection: $ishtaDevata, options: VedicConstants.ishtaDevatas)
                        
                        // Save Button
                        Button {
                            dismiss()
                        } label: {
                            Text("Save Spiritual Identity")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(gold)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Spiritual Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(gold)
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func pickerSection(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(gold)
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        HStack {
                            Text(option)
                            if selection.wrappedValue == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(gold)
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
