//
//  VedicProfileSettingsView.swift
//  Muhurta
//
//  Dedicated Profile, Milestones & Settings Sanctuary.
//  Includes Firebase Auth Cloud Account, Sacred Life Milestones (Birthdays & Anniversaries),
//  upcoming Vedic year wishes, tap-to-reveal Roman dates, and Vedic Calendar preferences.
//

import SwiftUI
import FirebaseAuth

struct VedicProfileSettingsView: View {
    @ObservedObject var authService = FirebaseAuthService.shared
    @ObservedObject var lifeEventManager = VedicLifeEventManager.shared
    
    @AppStorage("vedicCalendarSystem") private var calendarSystem: String = "Amanta"
    @AppStorage("meridianAnchor") private var meridianAnchor: String = "Ujjain"
    
    @State private var showingAddMilestone = false
    @State private var showingAuthModal = false
    @State private var showingAccountModal = false
    @State private var showingGuideModal = false
    @State private var showingSupportModal = false
    @State private var showingAllMilestones = false
    @State private var eventToEdit: UserLifeEvent? = nil
    @State private var eventToDelete: UserLifeEvent? = nil
    @State private var showingDeleteConfirmation = false
    
    // Expanded cards state
    @State private var expandedEventIds: Set<String> = []
    
    private let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Custom Sanctuary Header
                        profileHeader
                        
                        // User Profile & Firebase Cloud Sync Card
                        userProfileCard
                        
                        // Spiritual Identity Card (Gotra, Nakshatra, Rashi, Ishta Devata)
                        SpiritualIdentityCard()
                        
                        // Sacred Milestones Section Header
                        milestonesHeader
                        
                        // Clean, Chronologically Ordered Milestone Cards (Top 3 on Profile, Scalable for 50+)
                        if sortedEvents.isEmpty {
                            emptyMilestonesCard
                        } else {
                            VStack(spacing: 12) {
                                ForEach(sortedEvents.prefix(3)) { event in
                                    milestoneCard(event: event, isNextUpcoming: event.id == sortedEvents.first?.id)
                                }
                                
                                if sortedEvents.count > 3 {
                                    Button {
                                        showingAllMilestones = true
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "calendar")
                                                .foregroundColor(gold)
                                            Text("View All Sacred Milestones (\(sortedEvents.count))")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(gold.opacity(0.8))
                                        }
                                        .padding(14)
                                        .background(Color.white.opacity(0.04))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(gold.opacity(0.25), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Vedic Calendar System & Calculation Preferences
                        calendarPreferencesCard
                        
                        // Cosmic Masterclass Educational Banner
                        educationalMasterclassBanner
                        
                        // Contribute & Seva (Funds & Open Source Code)
                        contributeAndSevaCard
                        
                        // Tradition & Ephemeris Credentials
                        ephemerisCredentialsCard
                            .padding(.bottom, 100) // Clearance for floating dock
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddMilestone) {
                AddLifeEventView()
            }
            .sheet(isPresented: $showingAuthModal) {
                PersonalizationAuthView()
            }
            .sheet(isPresented: $showingAccountModal) {
                AccountManagementSheet()
            }
            .sheet(isPresented: $showingGuideModal) {
                VedicCalendarFullGuideView()
            }
            .sheet(item: $eventToEdit) { event in
                AddLifeEventView(eventToEdit: event)
            }
            .sheet(isPresented: $showingSupportModal) {
                SupportSanctuaryView()
            }
            .sheet(isPresented: $showingAllMilestones) {
                AllSacredMilestonesView()
            }
            .alert("Delete Milestone?", isPresented: $showingDeleteConfirmation, presenting: eventToDelete) { event in
                Button("Delete", role: .destructive) {
                    withAnimation {
                        lifeEventManager.deleteEvent(id: event.id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { event in
                Text("Are you sure you want to remove \"\(event.title)\"? This will remove it from your device and cloud backup.")
            }
        }
    }
    
    // MARK: - 1. User Profile Card
    
    private var userProfileCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [gold.opacity(0.25), gold.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                
                if let photoURL = authService.photoURL {
                    AsyncImage(url: photoURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(Circle())
                        default:
                            Image(systemName: authService.isAuthenticated ? "person.crop.circle.badge.checkmark" : "person.crop.circle")
                                .foregroundColor(gold)
                                .font(.system(size: 26))
                        }
                    }
                } else {
                    Image(systemName: authService.isAuthenticated ? "person.crop.circle.badge.checkmark" : "person.crop.circle")
                        .foregroundColor(gold)
                        .font(.system(size: 26))
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(authService.isAuthenticated ? (authService.isAnonymous ? "Guest Seeker" : (authService.displayName ?? authService.user?.email ?? "Seeker")) : "Local Vedic Sanctuary")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    if authService.isAuthenticated {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 7, height: 7)
                    }
                }
                
                Text(authService.isAuthenticated ? (authService.user?.email ?? "Synced with Firebase Cloud") : "Offline Mode • Tap to back up")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Button {
                if authService.isAuthenticated {
                    showingAccountModal = true
                } else {
                    showingAuthModal = true
                }
            } label: {
                Text(authService.isAuthenticated ? "Manage" : "Sign In")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(gold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(gold.opacity(0.14))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(gold.opacity(0.35), lineWidth: 1))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }
    
    // MARK: - 2. Milestones Header
    
    private var milestonesHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("ॐ")
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(gold)
                    Text("जन्म-संस्कार")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(1.3)
                        .foregroundColor(gold)
                }
                Text("Annual Tithi Celebrations")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if sortedEvents.count > 3 {
                    Button {
                        showingAllMilestones = true
                    } label: {
                        Text("All (\(sortedEvents.count))")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(gold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(gold.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(gold.opacity(0.3), lineWidth: 1))
                    }
                }
                
                Button {
                    if authService.isAuthenticated {
                        showingAddMilestone = true
                    } else {
                        showingAuthModal = true
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add Date")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .background(gold)
                    .clipShape(Capsule())
                    .shadow(color: gold.opacity(0.25), radius: 6, y: 2)
                }
            }
        }
        .padding(.horizontal, 2)
    }
    
    // MARK: - 3. Clean Milestone Card
    
    private var sortedEvents: [UserLifeEvent] {
        lifeEventManager.events.sorted {
            lifeEventManager.nextRecurrence(for: $0).daysRemaining < lifeEventManager.nextRecurrence(for: $1).daysRemaining
        }
    }
    
    private func milestoneCard(event: UserLifeEvent, isNextUpcoming: Bool) -> some View {
        let recurrence = lifeEventManager.nextRecurrence(for: event)
        let isExpanded = expandedEventIds.contains(event.id)
        
        return VStack(alignment: .leading, spacing: 10) {
            // Next celebration spotlight badge (only on the closest upcoming event)
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
            
            // Main card row: Date badge on left + Details on right
            HStack(alignment: .top, spacing: 14) {
                // Sacred Date Badge Tile
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
                
                // Content Information
                VStack(alignment: .leading, spacing: 5) {
                    // Header Row: Type icon + Title + Person pill + Context Menu
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
                    
                    // Clean Vedic Tithi line
                    Text(cleanVedicTitle(masa: event.vedicMasaName, paksha: event.vedicPaksha, tithi: event.vedicTithiName))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(gold.opacity(0.95))
                    
                    // Metadata: Nakshatra and Born Gregorian Reference
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
            
            // Expandable Blessing & Vedic Year Details
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
                        colors: [
                            Color(red: 0.13, green: 0.11, blue: 0.08),
                            Color(red: 0.08, green: 0.09, blue: 0.13)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.09, blue: 0.13),
                            Color(red: 0.07, green: 0.08, blue: 0.11)
                        ],
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
        .contextMenu {
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
        }
    }
    
    // MARK: - Formatters & Cleaners
    
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
    
    // MARK: - 5. Calendar System Preferences
    
    private var calendarPreferencesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("VEDIC CALENDAR PREFERENCES")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(gold)
            
            VStack(spacing: 14) {
                // Month System Dropdown
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Month System")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text(calendarSystem == "Amanta" ? "Amānta: Month ends on New Moon (Amāvāsyā)" : "Pūrṇimānta: Month ends on Full Moon (Pūrṇimā)")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                calendarSystem = "Amanta"
                            }
                        } label: {
                            HStack {
                                Text("Amānta (New Moon)")
                                if calendarSystem == "Amanta" {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                calendarSystem = "Purnimanta"
                            }
                        } label: {
                            HStack {
                                Text("Pūrṇimānta (Full Moon)")
                                if calendarSystem == "Purnimanta" {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(calendarSystem == "Amanta" ? "Amānta" : "Pūrṇimānta")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(gold)
                            
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(gold.opacity(0.8))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(gold.opacity(0.35), lineWidth: 1)
                        )
                    }
                }
                
                Divider().background(Color.white.opacity(0.08))
                
                // Prime Meridian Anchor Dropdown
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Prime Meridian Anchor")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text(meridianAnchor == "Ujjain" ? "Ujjain (Avantika 0° longitude Prime Meridian)" : "Local GPS Coordinates (Topocentric Sidereal)")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                meridianAnchor = "Ujjain"
                            }
                        } label: {
                            HStack {
                                Text("Ujjain (Avantika 0°)")
                                if meridianAnchor == "Ujjain" {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                meridianAnchor = "GPS"
                            }
                        } label: {
                            HStack {
                                Text("Local GPS Coordinates")
                                if meridianAnchor == "GPS" {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(meridianAnchor == "Ujjain" ? "Ujjain (0°)" : "Local GPS")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(gold)
                            
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(gold.opacity(0.8))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(gold.opacity(0.35), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }
    
    // MARK: - 6. Educational Masterclass Banner
    
    private var educationalMasterclassBanner: some View {
        Button {
            showingGuideModal = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(gold.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "book.pages.fill")
                        .foregroundColor(gold)
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Vedic Calendar Masterclass")
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    Text("Learn why Vedic time begins at sunrise, why the year is 5,128, and how Tithis function.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(gold.opacity(0.8))
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.09, green: 0.10, blue: 0.15))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(gold.opacity(0.25), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 7. Contribute & Seva Card
    
    private var contributeAndSevaCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Text("ॐ")
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundColor(gold)
                    Text("CONTRIBUTE & SEVA (सहयोग एवं सेवा)")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundColor(gold)
                }
                Spacer()
                Text("100% Free & Open")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }
            
            Text("Muhūrta is an open-source, ad-free sacred offering. You can support the continuous preservation of Vedic chronometry through code or voluntary Dakṣiṇā.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(2)
            
            HStack(spacing: 10) {
                // Support with Code (GitHub)
                Link(destination: URL(string: "https://github.com/heyshinde/Muhurta")!) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(gold)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Open Source")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("GitHub Repo")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(11)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                
                // Support with Funds (Offerings & Dakshina)
                Button {
                    showingSupportModal = true
                } label: {
                    HStack(spacing: 8) {
                        Text("🪔")
                            .font(.system(size: 14))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Dakṣiṇā")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                            Text("Offer Support")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color.black.opacity(0.75))
                        }
                        Spacer()
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.black.opacity(0.6))
                    }
                    .padding(11)
                    .frame(maxWidth: .infinity)
                    .background(gold)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: gold.opacity(0.25), radius: 6, y: 2)
                }
            }
        }
        .padding(18)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(gold.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - 8. Ephemeris Credentials
    
    private var ephemerisCredentialsCard: some View {
        VStack(spacing: 6) {
            Text("MATHEMATICAL CHRONOMETRY")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(gold.opacity(0.7))
            
            Text("Muhurta Ephemeris is powered by continuous Julian Day astronomical solvers, Sūrya Siddhānta celestial longitudes, and Sidereal Chitra-Paksha Ayanamsa. Pure sidereal timekeeping with zero Gregorian assumptions.")
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.45))
                .lineSpacing(3)
        }
        .padding(.horizontal, 10)
    }
    
    private var profileHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("SEEKER'S SANCTUARY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(2.0)
                    .foregroundColor(gold)
                
                Text("Profile & Settings")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(.top, 14)
    }
    
    // MARK: - Helpers
    
    private var emptyMilestonesCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 30))
                .foregroundColor(gold.opacity(0.8))
            
            Text("No Milestones Consecrated Yet")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundColor(.white)
            
            Text("Add your Birthday (Janmadina) or Wedding Anniversary to receive auspicious blessings on your exact lunar Tithi recurrence.")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(2)
                .padding(.horizontal, 10)
            
            Button {
                if authService.isAuthenticated {
                    showingAddMilestone = true
                } else {
                    showingAuthModal = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Milestone")
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(gold)
                .clipShape(Capsule())
                .shadow(color: gold.opacity(0.2), radius: 6, y: 2)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }
    
    private func closestUpcomingEvent() -> (event: UserLifeEvent, recurrence: (date: Date, daysRemaining: Int, isToday: Bool, celebrationYear: Int))? {
        guard !lifeEventManager.events.isEmpty else { return nil }
        let all = lifeEventManager.events.map { ($0, lifeEventManager.nextRecurrence(for: $0)) }
        return all.min { $0.1.daysRemaining < $1.1.daysRemaining }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }
}

// MARK: - Account Management Sheet

struct AccountManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authService = FirebaseAuthService.shared
    @ObservedObject var lifeEventManager = VedicLifeEventManager.shared
    @State private var isSyncingCloud: Bool = false
    @State private var syncSuccess: Bool = false
    @State private var showingSignOutAlert: Bool = false
    
    private let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.07, blue: 0.10).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 22) {
                        // User Avatar & Email
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [gold.opacity(0.3), gold.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 76, height: 76)
                                    .overlay(Circle().stroke(gold.opacity(0.4), lineWidth: 1.5))
                                
                                if let photoURL = authService.photoURL {
                                    AsyncImage(url: photoURL) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 76, height: 76)
                                                .clipShape(Circle())
                                        default:
                                            Image(systemName: "person.crop.circle.fill")
                                                .font(.system(size: 48))
                                                .foregroundColor(gold)
                                        }
                                    }
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(gold)
                                }
                            }
                            .padding(.top, 10)
                            
                            VStack(spacing: 4) {
                                Text(authService.isAnonymous ? "Guest Seeker" : (authService.displayName ?? "Vedic Practitioner"))
                                    .font(.system(size: 19, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                
                                Text(authService.user?.email ?? (authService.isAnonymous ? "Anonymous Cloud Session" : "Authenticated Seeker"))
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.65))
                            }
                        }
                        
                        // Cloud Sync Status Card
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "icloud.fill")
                                    .foregroundColor(Color.cyan)
                                    .font(.system(size: 16))
                                Text("FIREBASE CLOUD SANCTUARY")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.cyan)
                                Spacer()
                                HStack(spacing: 5) {
                                    Circle().fill(Color.green).frame(width: 6, height: 6)
                                    Text("Connected")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color.green)
                                }
                            }
                            
                            Text("Your consecrated birthdays, anniversaries, and sacred samskaras are backed up securely and synchronized in real time.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(2)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(lifeEventManager.events.count)")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(gold)
                                    Text("Consecrated Milestones")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                Button {
                                    Task {
                                        isSyncingCloud = true
                                        await lifeEventManager.syncWithFirestore()
                                        isSyncingCloud = false
                                        syncSuccess = true
                                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                                        syncSuccess = false
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        if isSyncingCloud {
                                            ProgressView()
                                                .tint(.black)
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: syncSuccess ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                                        }
                                        Text(syncSuccess ? "Synced!" : (isSyncingCloud ? "Syncing..." : "Sync Now"))
                                    }
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(syncSuccess ? Color.green : gold)
                                    .clipShape(Capsule())
                                }
                                .disabled(isSyncingCloud)
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(red: 0.08, green: 0.10, blue: 0.14))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        )
                        
                        // User Account ID & Metadata
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ACCOUNT CREDENTIALS")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(gold.opacity(0.8))
                            
                            HStack {
                                Text("Auth Provider")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text(authService.isAnonymous ? "Guest Session" : "Google")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            Divider().background(Color.white.opacity(0.08))
                            
                            HStack {
                                Text("Seeker UID")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text(authService.user?.uid.prefix(12).appending("...") ?? "—")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06), lineWidth: 1))
                        )
                        
                        // Sign Out Button
                        Button(role: .destructive) {
                            showingSignOutAlert = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out of Sanctuary")
                            }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.red.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.25), lineWidth: 1))
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Seeker Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(gold)
                }
            }
            .alert("Sign Out of Muhurta?", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    try? authService.signOut()
                    dismiss()
                }
            } message: {
                Text("Your milestones will remain safely saved in the cloud. You can sign back in anytime to restore them.")
            }
        }
    }
}
