//
//  AllSacredMilestonesView.swift
//  Muhurta
//
//  Comprehensive directory for all consecrated Vedic Milestones (Birthdays, Anniversaries, Samskaras).
//  Supports search, type filtering, chronological recurrence sorting, and full CRUD operations.
//

import SwiftUI

struct AllSacredMilestonesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var lifeEventManager = VedicLifeEventManager.shared
    
    @State private var searchText = ""
    @State private var selectedFilter: MilestoneFilter = .all
    @State private var showingAddMilestone = false
    @State private var eventToEdit: UserLifeEvent? = nil
    @State private var eventToDelete: UserLifeEvent? = nil
    @State private var showingDeleteConfirmation = false
    @State private var expandedEventIds: Set<String> = []
    
    private let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
    
    enum MilestoneFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case birthdays = "Birthdays"
        case anniversaries = "Anniversaries"
        case samskaras = "Samskāras"
        
        var id: String { rawValue }
        
        func matches(event: UserLifeEvent) -> Bool {
            switch self {
            case .all:
                return true
            case .birthdays:
                return event.type == .birthday
            case .anniversaries:
                return event.type == .anniversary
            case .samskaras:
                return event.type == .samskara || event.type == .memorial || event.type == .custom
            }
        }
    }
    
    private var sortedEvents: [UserLifeEvent] {
        lifeEventManager.events.sorted {
            lifeEventManager.nextRecurrence(for: $0).daysRemaining < lifeEventManager.nextRecurrence(for: $1).daysRemaining
        }
    }
    
    private var filteredEvents: [UserLifeEvent] {
        sortedEvents.filter { event in
            let matchesType = selectedFilter.matches(event: event)
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return matchesType
            } else {
                let q = searchText.lowercased()
                let matchesSearch = event.title.lowercased().contains(q) ||
                                    event.personName.lowercased().contains(q) ||
                                    event.vedicMasaName.lowercased().contains(q) ||
                                    event.vedicTithiName.lowercased().contains(q)
                return matchesType && matchesSearch
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search & Filter Bar
                    filterBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    
                    if filteredEvents.isEmpty {
                        emptyFilterView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredEvents) { event in
                                    milestoneRowCard(event: event, isNextUpcoming: event.id == sortedEvents.first?.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle("Sacred Milestones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(gold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddMilestone = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("Add")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(gold)
                        .clipShape(Capsule())
                    }
                }
            }
            .sheet(isPresented: $showingAddMilestone) {
                AddLifeEventView()
            }
            .sheet(item: $eventToEdit) { event in
                AddLifeEventView(eventToEdit: event)
            }
            .alert("Delete Milestone?", isPresented: $showingDeleteConfirmation, presenting: eventToDelete) { event in
                Button("Delete", role: .destructive) {
                    withAnimation {
                        lifeEventManager.deleteEvent(id: event.id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { event in
                Text("Are you sure you want to remove \"\(event.title)\"?")
            }
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        VStack(spacing: 10) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 13))
                
                TextField("Search by name, person, or Tithi...", text: $searchText)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.4))
                            .font(.system(size: 13))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Segmented Filter Pills
            HStack(spacing: 6) {
                ForEach(MilestoneFilter.allCases) { filter in
                    let isSelected = selectedFilter == filter
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .black : .white.opacity(0.75))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? gold : Color.white.opacity(0.05))
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }
        }
    }
    
    // MARK: - Row Card
    
    private func milestoneRowCard(event: UserLifeEvent, isNextUpcoming: Bool) -> some View {
        let recurrence = lifeEventManager.nextRecurrence(for: event)
        let isExpanded = expandedEventIds.contains(event.id)
        
        return VStack(alignment: .leading, spacing: 10) {
            if isNextUpcoming {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(gold)
                    Text(recurrence.isToday ? "CELEBRATING TODAY!" : "NEXT UPCOMING CELEBRATION")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundColor(gold)
                    
                    Spacer()
                    
                    Text(recurrence.isToday ? "TODAY" : "in \(recurrence.daysRemaining) days")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(gold)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 2)
            }
            
            HStack(alignment: .top, spacing: 14) {
                // Sacred Date Tile
                VStack(spacing: 2) {
                    Text(monthAbbrev(recurrence.date))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundColor(isNextUpcoming ? gold : .white.opacity(0.8))
                    
                    Text(dayNumber(recurrence.date))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(yearNumber(recurrence.date))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.55))
                }
                .frame(width: 58, height: 68)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isNextUpcoming ? gold.opacity(0.14) : Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isNextUpcoming ? gold.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                
                // Information Column
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .center, spacing: 6) {
                        Image(systemName: event.type.iconName)
                            .font(.system(size: 13))
                            .foregroundColor(event.type.tintColor)
                        
                        Text(event.title)
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if !event.personName.isEmpty {
                            Text(event.personName)
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundColor(.white.opacity(0.75))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Capsule())
                        }
                        
                        if !isNextUpcoming {
                            Text("in \(recurrence.daysRemaining)d")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(gold.opacity(0.9))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(gold.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        
                        Menu {
                            Button {
                                eventToEdit = event
                            } label: {
                                Label("Edit Milestone", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                eventToDelete = event
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Milestone", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.65))
                                .frame(width: 26, height: 26)
                                .background(Color.white.opacity(0.05))
                                .clipShape(Circle())
                        }
                    }
                    
                    Text(cleanVedicTitle(masa: event.vedicMasaName, paksha: event.vedicPaksha, tithi: event.vedicTithiName))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(gold.opacity(0.95))
                    
                    HStack(spacing: 5) {
                        Text("Nakshatra: \(cleanWord(event.vedicNakshatra))")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.65))
                        
                        Text("•")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("Born: \(formattedDate(event.originalDate))")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Divider().background(Color.white.opacity(0.08))
                    
                    HStack {
                        Text("SACRED VEDIC RECURRENCE • YEAR \(recurrence.celebrationYear)")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(gold)
                        Spacer()
                        Text("Tap to collapse")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    Text(event.type.blessingGreeting)
                        .font(.system(size: 11.5, design: .serif))
                        .italic()
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(2)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isNextUpcoming
                    ? LinearGradient(
                        colors: [Color(red: 0.13, green: 0.11, blue: 0.08), Color(red: 0.08, green: 0.09, blue: 0.13)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color(red: 0.08, green: 0.09, blue: 0.13), Color(red: 0.07, green: 0.08, blue: 0.11)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isNextUpcoming ? gold.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                if expandedEventIds.contains(event.id) {
                    expandedEventIds.remove(event.id)
                } else {
                    expandedEventIds.insert(event.id)
                }
            }
        }
    }
    
    private var emptyFilterView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 34))
                .foregroundColor(gold.opacity(0.7))
            Text("No Milestones Match")
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundColor(.white)
            Text("Try clearing your search or filter to see all consecrated dates.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Formatters
    
    private func cleanWord(_ str: String) -> String {
        str.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? str
    }
    
    private func cleanPaksha(_ paksha: String) -> String {
        let lower = paksha.lowercased()
        if lower.contains("sukla") || lower.contains("śukla") || lower.contains("waxing") {
            return "Śukla"
        } else {
            return "Kṛṣṇa"
        }
    }
    
    private func cleanVedicTitle(masa: String, paksha: String, tithi: String) -> String {
        let m = cleanWord(masa)
        let p = cleanPaksha(paksha)
        let t = cleanWord(tithi)
        return "\(m) \(p) \(t)"
    }
    
    private func monthAbbrev(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: date).uppercased()
    }
    
    private func dayNumber(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
    
    private func yearNumber(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f.string(from: date)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }
}
