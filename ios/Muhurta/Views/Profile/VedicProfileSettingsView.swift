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
    @State private var eventToEdit: UserLifeEvent? = nil
    @State private var eventToDelete: UserLifeEvent? = nil
    @State private var showingDeleteConfirmation = false
    
    // Tap-to-reveal Roman state
    @State private var temporaryRevealedId: String? = nil
    @State private var countdownSeconds: Double = 3.5
    @State private var countdownTask: Task<Void, Never>? = nil
    
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
                        
                        // Life Milestones Section Header
                        milestonesHeader
                        
                        // Upcoming Celebration Hero
                        if let closest = closestUpcomingEvent() {
                            upcomingHeroBanner(for: closest)
                        }
                        
                        // Milestone Cards List
                        if lifeEventManager.events.isEmpty {
                            emptyMilestonesCard
                        } else {
                            VStack(spacing: 12) {
                                ForEach(lifeEventManager.events) { event in
                                    milestoneInteractiveCard(event: event)
                                }
                            }
                        }
                        
                        // Vedic Calendar System & Calculation Preferences
                        calendarPreferencesCard
                        
                        // Cosmic Masterclass Educational Banner
                        educationalMasterclassBanner
                        
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
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("VEDIC MILESTONES (जन्म-संस्कार)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(gold)
                Text("Annual Solar-Lunar Tithi Recurrences")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }
            
            Spacer()
            
            Button {
                if authService.isAuthenticated {
                    showingAddMilestone = true
                } else {
                    showingAuthModal = true
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Date")
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(gold)
                .clipShape(Capsule())
                .shadow(color: gold.opacity(0.25), radius: 8, y: 3)
            }
        }
        .padding(.horizontal, 2)
    }
    
    // MARK: - 3. Upcoming Hero Banner
    
    private func upcomingHeroBanner(for item: (event: UserLifeEvent, recurrence: (date: Date, daysRemaining: Int, isToday: Bool, celebrationYear: Int))) -> some View {
        let event = item.event
        let rec = item.recurrence
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(gold)
                    Text(rec.isToday ? "CELEBRATING TODAY! • अद्योत्सवः" : "NEXT UPCOMING VEDIC CELEBRATION")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(gold)
                }
                
                Spacer()
                
                Text(rec.isToday ? "TODAY" : "in \(rec.daysRemaining) days")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(gold)
                    .clipShape(Capsule())
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                Text("\(event.personName) • \(event.vedicMasaName) \(event.vedicPaksha) \(event.vedicTithiName)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(gold.opacity(0.9))
                
                Text("Vedic Year \(rec.celebrationYear) • \(formattedDate(rec.date))")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Text(event.type.blessingGreeting)
                .font(.system(size: 12, design: .serif))
                .italic()
                .foregroundColor(.white.opacity(0.8))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.16, green: 0.13, blue: 0.08),
                                Color(red: 0.08, green: 0.09, blue: 0.13)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 18)
                    .stroke(gold.opacity(0.3), lineWidth: 1)
            }
        )
    }
    
    // MARK: - 4. Milestone Interactive Card (Tap to reveal Roman date)
    
    private func milestoneInteractiveCard(event: UserLifeEvent) -> some View {
        let isRevealed = (temporaryRevealedId == event.id)
        let recurrence = lifeEventManager.nextRecurrence(for: event)
        
        return VStack(alignment: .leading, spacing: 10) {
            // Header Row: Type, Title, Person, and Options Menu
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: event.type.iconName)
                        .foregroundColor(event.type.tintColor)
                    Text(event.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(event.personName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                
                // Visible Options Dropdown Menu for Edit & Delete
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
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }
            
            // Display Area: Tap to reveal Roman date temporarily
            Button {
                revealRomanDate(for: event.id)
            } label: {
                ZStack {
                    if isRevealed {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(Color.cyan)
                                Text("ROMAN / GREGORIAN DATE")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.cyan)
                                Spacer()
                                Text("Reverting in \(String(format: "%.1f", max(0, countdownSeconds)))s")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.cyan.opacity(0.8))
                            }
                            
                            Text(event.formattedRomanDate)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.15))
                                    let progress = CGFloat(max(0.0, min(1.0, countdownSeconds / 3.5)))
                                    Capsule().fill(Color.cyan)
                                        .frame(width: max(0, min(geo.size.width, geo.size.width * progress)))
                                }
                            }
                            .frame(height: 3)
                        }
                        .padding(12)
                        .background(Color.cyan.opacity(0.12))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan.opacity(0.4), lineWidth: 1))
                    } else {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Image(systemName: "sun.max.fill")
                                    .foregroundColor(gold)
                                Text("VEDIC CALENDAR")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(gold)
                                Spacer()
                                Text("Vedic Year \(event.vedicYear)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Text("\(event.vedicMasaName) • \(event.vedicPaksha) \(event.vedicTithiName)")
                                .font(.system(size: 15, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("Nakshatra: \(event.vedicNakshatra)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text("Tap to view Roman date ⏱️")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(gold.opacity(0.85))
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Recurrence in current Vedic Year (5128)
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "repeat")
                        .font(.system(size: 11))
                        .foregroundColor(gold)
                    Text("Current Year Recurrence:")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))
                }
                Spacer()
                Text("\(formattedDate(recurrence.date)) (\(recurrence.daysRemaining == 0 ? "Today" : "in \(recurrence.daysRemaining)d"))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(gold)
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isRevealed ? Color.cyan.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
                )
        )
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
    
    private func revealRomanDate(for eventId: String) {
        countdownTask?.cancel()
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            temporaryRevealedId = eventId
            countdownSeconds = 3.5
        }
        
        countdownTask = Task { @MainActor in
            while countdownSeconds > 0.05 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                if Task.isCancelled { return }
                countdownSeconds -= 0.1
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                temporaryRevealedId = nil
            }
        }
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
    
    // MARK: - 7. Ephemeris Credentials
    
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
                                Text(authService.isAnonymous ? "Guest Session" : "Google / Firebase")
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
