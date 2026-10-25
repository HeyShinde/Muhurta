//
//  AddLifeEventView.swift
//  Muhurta
//
//  Sheet to enter Life Events (Birthdays, Anniversaries, Samskaras)
//  either via standard Roman/Gregorian date or direct Vedic Tithi & Lunar Māsa picker.
//

import SwiftUI

struct AddLifeEventView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager = VedicLifeEventManager.shared
    
    var eventToEdit: UserLifeEvent? = nil
    
    @State private var title: String
    @State private var personName: String
    @State private var selectedType: LifeEventType
    @State private var inputMode: InputMode
    
    // Gregorian Mode State
    @State private var selectedDate: Date
    
    // Vedic Direct Mode State
    @State private var selectedMasaIndex: Int
    @State private var selectedPaksha: String
    @State private var selectedTithiNumber: Int
    @State private var notes: String
    
    public init(eventToEdit: UserLifeEvent? = nil) {
        self.eventToEdit = eventToEdit
        if let event = eventToEdit {
            _title = State(initialValue: event.title)
            _personName = State(initialValue: event.personName)
            _selectedType = State(initialValue: event.type)
            _selectedDate = State(initialValue: event.originalDate)
            _selectedMasaIndex = State(initialValue: event.vedicMasaIndex)
            _selectedPaksha = State(initialValue: event.vedicPaksha)
            _selectedTithiNumber = State(initialValue: event.vedicTithiNumber)
            _notes = State(initialValue: event.notes)
            _inputMode = State(initialValue: .gregorian)
        } else {
            _title = State(initialValue: "")
            _personName = State(initialValue: "")
            _selectedType = State(initialValue: .birthday)
            _selectedDate = State(initialValue: Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date())
            _selectedMasaIndex = State(initialValue: 8)
            _selectedPaksha = State(initialValue: "Śukla")
            _selectedTithiNumber = State(initialValue: 13)
            _notes = State(initialValue: "")
            _inputMode = State(initialValue: .gregorian)
        }
    }
    
    enum InputMode: String, CaseIterable {
        case gregorian = "Roman / Gregorian Date"
        case vedic = "Vedic Tithi & Māsa"
    }
    
    private let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
    private let masaNames = [
        "Caitra (चैत्र)", "Vaiśākha (वैशाख)", "Jyeṣṭha (ज्येष्ठ)",
        "Āṣāḍha (आषाढ)", "Śrāvaṇa (श्रावण)", "Bhādrapada (भाद्रपद)",
        "Āśvina (आश्विन)", "Kārtika (कार्तिक)", "Mārgaśīrṣa (मार्गशीर्ष)",
        "Pauṣa (पौष)", "Māgha (माघ)", "Phālguna (फाल्गुन)"
    ]
    
    private let tithiNames = [
        "Pratipadā (प्रतिपदा)", "Dvitīyā (द्वितीया)", "Tṛtīyā (तृतीया)",
        "Caturthī (चतुर्थी)", "Pañcamī (पञ्चमी)", "Ṣaṣṭhī (षष्ठी)",
        "Saptamī (सप्तमी)", "Aṣṭamī (अष्टमी)", "Navamī (नवमी)",
        "Daśamī (दशमी)", "Ekādaśī (एकादशी)", "Dvādaśī (द्वादशी)",
        "Trayodaśī (त्रयोदशी)", "Caturdaśī (चतुर्दशी)", "Pūrṇimā / Amāvāsyā"
    ]
    
    private var computedVedicPreview: (kaliYear: Int, masaIndex: Int, masaName: String, paksha: String, tithiNumber: Int, tithiName: String, nakshatra: String) {
        manager.computeVedicCoordinates(for: selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Type Selector
                        typeSelectorSection
                        
                        // Details Input
                        detailsSection
                        
                        // Input Mode Toggle
                        inputModeSection
                        
                        if inputMode == .gregorian {
                            gregorianInputSection
                        } else {
                            vedicInputSection
                        }
                        
                        // Notes Section
                        notesSection
                        
                        // Save Button
                        saveButton
                            .padding(.top, 10)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(eventToEdit != nil ? "Edit Sacred Milestone" : "Add Sacred Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.white.opacity(0.6))
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var typeSelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LifeEventType.allCases) { type in
                    let isSelected = selectedType == type
                    Button {
                        selectedType = type
                        if title.isEmpty || LifeEventType.allCases.map({ $0.rawValue }).contains(title) {
                            title = type.rawValue
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type.iconName)
                            Text(type.sanskritTitle)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(isSelected ? .black : Color.white.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            isSelected ? type.tintColor : Color.white.opacity(0.06)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(isSelected ? type.tintColor : Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(spacing: 12) {
            TextField("Event Title (e.g. My Vedic Birthday)", text: $title)
                .padding(14)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .foregroundColor(.white)
            
            TextField("Person / Deity Name (e.g. Self, Spouse, Child)", text: $personName)
                .padding(14)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .foregroundColor(.white)
        }
    }
    
    private var inputModeSection: some View {
        Picker("Input Mode", selection: $inputMode) {
            ForEach(InputMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 4)
    }
    
    private var gregorianInputSection: some View {
        VStack(spacing: 14) {
            DatePicker(
                "Birth / Milestone Date",
                selection: $selectedDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .colorScheme(.dark)
            .padding(12)
            .background(Color.white.opacity(0.04))
            .cornerRadius(16)
            
            // Real-Time Vedic Chronometry Translation Card
            let v = computedVedicPreview
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(gold)
                    Text("DYNAMIC VEDIC CHRONOMETRY")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(gold)
                    Spacer()
                    Text("Kali Yuga \(v.kaliYear)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text("\(v.masaName) • \(v.paksha) \(v.tithiName)")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                Text("This milestone will be celebrated every year on the sacred \(v.paksha) \(v.tithiName) of \(v.masaName), synchronized with the solar-lunar cosmos.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.6))
                    .lineSpacing(3)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.10, green: 0.11, blue: 0.16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(gold.opacity(0.3), lineWidth: 1))
            )
        }
    }
    
    private var vedicInputSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("LUNAR MONTH (MĀSA)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(gold)
                
                Picker("Lunar Month", selection: $selectedMasaIndex) {
                    ForEach(1...12, id: \.self) { idx in
                        Text(masaNames[idx - 1]).tag(idx)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 110)
                .clipped()
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .cornerRadius(14)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PAKSHA (MOON PHASE)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(gold)
                    
                    Picker("Paksha", selection: $selectedPaksha) {
                        Text("Śukla (Waxing)").tag("Śukla")
                        Text("Kṛṣṇa (Waning)").tag("Kṛṣṇa")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .cornerRadius(14)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("TITHI (LUNAR DAY)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(gold)
                
                Picker("Tithi", selection: $selectedTithiNumber) {
                    ForEach(1...15, id: \.self) { num in
                        Text("\(num). \(tithiNames[num - 1])").tag(num)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 110)
                .clipped()
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .cornerRadius(14)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SACRED INTENTION / SANKALPA NOTES")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.45))
            
            TextField("e.g. Perform Abhishekam, Chant Gayatri Mantra 108x", text: $notes)
                .padding(14)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .foregroundColor(.white)
        }
    }
    
    private var saveButton: some View {
        Button {
            saveEvent()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text(eventToEdit != nil ? "Save Changes" : "Consecrate Sacred Milestone")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(gold)
            .cornerRadius(16)
            .shadow(color: gold.opacity(0.3), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
        .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
    }
    
    private func saveEvent() {
        let finalTitle = title.trimmingCharacters(in: .whitespaces)
        let finalPerson = personName.trimmingCharacters(in: .whitespaces).isEmpty ? "Self" : personName
        
        let newEvent: UserLifeEvent
        
        if inputMode == .gregorian {
            let v = computedVedicPreview
            newEvent = UserLifeEvent(
                id: eventToEdit?.id ?? UUID().uuidString,
                userId: eventToEdit?.userId ?? "",
                title: finalTitle,
                personName: finalPerson,
                type: selectedType,
                originalDate: selectedDate,
                vedicYear: v.kaliYear,
                vedicMasaIndex: v.masaIndex,
                vedicMasaName: v.masaName,
                vedicPaksha: v.paksha,
                vedicTithiNumber: v.tithiNumber,
                vedicTithiName: v.tithiName,
                vedicNakshatra: v.nakshatra,
                notes: notes,
                createdAt: eventToEdit?.createdAt ?? Date()
            )
        } else {
            let masaName = masaNames[selectedMasaIndex - 1]
            let tithiName = tithiNames[selectedTithiNumber - 1].split(separator: " ")[0].description
            newEvent = UserLifeEvent(
                id: eventToEdit?.id ?? UUID().uuidString,
                userId: eventToEdit?.userId ?? "",
                title: finalTitle,
                personName: finalPerson,
                type: selectedType,
                originalDate: selectedDate,
                vedicYear: 5128,
                vedicMasaIndex: selectedMasaIndex,
                vedicMasaName: masaName,
                vedicPaksha: selectedPaksha,
                vedicTithiNumber: selectedTithiNumber,
                vedicTithiName: tithiName,
                vedicNakshatra: "Svātī",
                notes: notes,
                createdAt: eventToEdit?.createdAt ?? Date()
            )
        }
        
        if eventToEdit != nil {
            manager.updateEvent(newEvent)
        } else {
            manager.addEvent(newEvent)
        }
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        dismiss()
    }
}
