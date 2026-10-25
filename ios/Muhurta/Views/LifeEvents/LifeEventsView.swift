//
//  LifeEventsView.swift
//  Muhurta
//
//  Vedic Life Milestones (Janmadina & Vivāha) Dashboard.
//  Users view and celebrate life events strictly according to the Vedic calendar.
//  Interactive feature: Tap any card to reveal the Roman/Gregorian date for 3.5 seconds,
//  after which it smoothly returns to authentic Vedic Chronometry.
//

import SwiftUI
import FirebaseAuth

struct LifeEventsView: View {
    @ObservedObject var manager = VedicLifeEventManager.shared
    @ObservedObject var authService = FirebaseAuthService.shared
    
    @State private var showingAddSheet = false
    @State private var showingAuthSheet = false
    @State private var temporaryRomanRevealedEventId: String? = nil
    @State private var romanCountdownSeconds: Double = 3.5
    @State private var countdownTask: Task<Void, Never>? = nil
    
    private let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // User Profile & Firebase Sync Header
                        authStatusBar
                        
                        // Next Upcoming Vedic Celebration Hero Banner
                        if let nextEvent = closestUpcomingEvent() {
                            upcomingHeroBanner(for: nextEvent)
                        }
                        
                        // Milestones List Section Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SACRED MILESTONES (जन्म-संस्कार)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(gold)
                                Text("Tithi Recurrences in Kali Yuga 5,128")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            
                            Button {
                                showingAddSheet = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add")
                                }
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(gold)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        // Milestone Cards
                        if manager.events.isEmpty {
                            emptyStateView
                        } else {
                            VStack(spacing: 14) {
                                ForEach(manager.events) { event in
                                    milestoneCard(event: event)
                                }
                            }
                        }
                        
                        // Educational Note
                        educationalFootnote
                            .padding(.top, 10)
                            .padding(.bottom, 60)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Vedic Milestones")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddSheet) {
                AddLifeEventView()
            }
            .sheet(isPresented: $showingAuthSheet) {
                FirebaseAuthModalView()
            }
        }
    }
    
    // MARK: - Auth Status Bar
    
    private var authStatusBar: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(authService.isAuthenticated ? Color.green.opacity(0.2) : gold.opacity(0.15))
                    .frame(width: 38, height: 38)
                
                Image(systemName: authService.isAuthenticated ? "icloud.fill" : "person.crop.circle")
                    .foregroundColor(authService.isAuthenticated ? Color.green : gold)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(authService.isAuthenticated ? (authService.isAnonymous ? "Anonymous Guest Account" : (authService.user?.email ?? "Cloud Synced")) : "Offline Local Account")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if authService.isAuthenticated {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                }
                
                Text(authService.isAuthenticated ? "Milestones securely preserved in Firebase" : "Tap to sign in and back up to cloud")
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.55))
            }
            
            Spacer()
            
            Button {
                showingAuthSheet = true
            } label: {
                Text(authService.isAuthenticated ? "Account" : "Sign In")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(gold.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(gold.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }
    
    // MARK: - Upcoming Hero Banner
    
    private func upcomingHeroBanner(for item: (event: UserLifeEvent, recurrence: (date: Date, daysRemaining: Int, isToday: Bool, celebrationYear: Int))) -> some View {
        let event = item.event
        let rec = item.recurrence
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(gold)
                    Text(rec.isToday ? "CELEBRATING TODAY! • अद्योत्सवः" : "NEXT UPCOMING VEDIC CELEBRATION")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(gold)
                }
                Spacer()
                
                Text(rec.isToday ? "TODAY" : "in \(rec.daysRemaining) days")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(gold)
                    .clipShape(Capsule())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                Text("\(event.personName) • \(event.vedicMasaName) \(event.vedicPaksha) \(event.vedicTithiName)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(gold.opacity(0.9))
                
                Text("Celebrated in Kali Yuga \(rec.celebrationYear) on \(formattedDate(rec.date))")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Sanskrit Blessing
            Text(event.type.blessingGreeting)
                .font(.system(size: 12, design: .serif))
                .italic()
                .foregroundColor(.white.opacity(0.75))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.16, green: 0.13, blue: 0.08),
                                Color(red: 0.09, green: 0.10, blue: 0.14)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 20)
                    .stroke(gold.opacity(0.35), lineWidth: 1)
            }
        )
        .shadow(color: gold.opacity(0.12), radius: 16, y: 6)
    }
    
    // MARK: - Milestone Card with Tap-to-Reveal Roman Feature
    
    private func milestoneCard(event: UserLifeEvent) -> some View {
        let isRevealed = (temporaryRomanRevealedEventId == event.id)
        let recurrence = manager.nextRecurrence(for: event)
        
        return Button {
            revealRomanDateTemporarily(for: event.id)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Card Top Line
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: event.type.iconName)
                            .foregroundColor(event.type.tintColor)
                            .font(.system(size: 15))
                        
                        Text(event.title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(event.personName)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Capsule())
                }
                
                // MAIN DISPLAY AREA: Vedic (default) vs Roman (temporary revealed)
                ZStack {
                    if isRevealed {
                        // REVEALED TEMPORARY ROMAN VIEW
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(Color.cyan)
                                Text("ROMAN / GREGORIAN REFERENCE")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.cyan)
                                Spacer()
                                Text("Reverting in \(String(format: "%.1f", romanCountdownSeconds))s")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.cyan.opacity(0.8))
                            }
                            
                            Text(event.formattedRomanDate)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            // Animated countdown bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.15))
                                    Capsule().fill(Color.cyan)
                                        .frame(width: geo.size.width * CGFloat(romanCountdownSeconds / 3.5))
                                }
                            }
                            .frame(height: 3)
                        }
                        .padding(12)
                        .background(Color.cyan.opacity(0.12))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan.opacity(0.4), lineWidth: 1))
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    } else {
                        // DEFAULT AUTHENTIC VEDIC CHRONOMETRY VIEW
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "sun.max.fill")
                                    .foregroundColor(gold)
                                Text("VEDIC CALENDAR")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(gold)
                                Spacer()
                                Text("Kali Yuga \(event.vedicYear)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Text("\(event.vedicMasaName) • \(event.vedicPaksha) \(event.vedicTithiName)")
                                .font(.system(size: 16, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Text("Nakshatra: \(event.vedicNakshatra)")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.white.opacity(0.6))
                                
                                Spacer()
                                
                                Text("Tap to view Roman date ⏱️")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(gold.opacity(0.8))
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
                
                // Recurrence in current Vedic Year (5128)
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "repeat")
                            .font(.system(size: 11))
                            .foregroundColor(gold)
                        Text("Current Vedic Year Recurrence:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    
                    Spacer()
                    
                    Text("\(formattedDate(recurrence.date)) (\(recurrence.daysRemaining == 0 ? "Today" : "in \(recurrence.daysRemaining)d"))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(gold)
                }
                
                if !event.notes.isEmpty {
                    Text(event.notes)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isRevealed ? Color.cyan.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .contextMenu {
                Button(role: .destructive) {
                    manager.deleteEvent(id: event.id)
                } label: {
                    Label("Delete Milestone", systemImage: "trash")
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Tap to Reveal Logic
    
    private func revealRomanDateTemporarily(for eventId: String) {
        countdownTask?.cancel()
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            temporaryRomanRevealedEventId = eventId
            romanCountdownSeconds = 3.5
        }
        
        countdownTask = Task { @MainActor in
            while romanCountdownSeconds > 0.05 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                if Task.isCancelled { return }
                romanCountdownSeconds -= 0.1
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                temporaryRomanRevealedEventId = nil
            }
        }
    }
    
    // MARK: - Helpers
    
    private func closestUpcomingEvent() -> (event: UserLifeEvent, recurrence: (date: Date, daysRemaining: Int, isToday: Bool, celebrationYear: Int))? {
        guard !manager.events.isEmpty else { return nil }
        
        let allWithRec = manager.events.map { event in
            (event: event, recurrence: manager.nextRecurrence(for: event))
        }
        
        return allWithRec.min { $0.recurrence.daysRemaining < $1.recurrence.daysRemaining }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundColor(gold.opacity(0.7))
                .padding(.top, 20)
            
            Text("No Milestones Consecrated Yet")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text("Add your Birthday, Wedding Anniversary, or Sacred Vow. The app will calculate your exact Vedic Tithi and wish you every year according to cosmic time.")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 30)
            
            Button {
                showingAddSheet = true
            } label: {
                Text("Add Your First Milestone")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(gold)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.02))
        .cornerRadius(18)
    }
    
    private var educationalFootnote: some View {
        VStack(spacing: 6) {
            Text("WHY CELEBRATE ON VEDIC TITHI?")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(gold.opacity(0.8))
            
            Text("A solar-lunar Tithi marks the exact celestial angle of the Moon relative to the Sun at your birth. Celebrating on your Tithi synchronizes your subtle prānic body with the original cosmic vibration under which you took human birth.")
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.55))
                .lineSpacing(3)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Firebase Auth Modal View

struct FirebaseAuthModalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authService = FirebaseAuthService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    
    private let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "icloud.and.arrow.up.fill")
                            .font(.system(size: 40))
                            .foregroundColor(gold)
                        
                        Text(authService.isAuthenticated ? "Sacred Cloud Account" : "Connect to Firebase")
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        
                        Text("Sync your Vedic birthdays, anniversaries, and personal alarms across all your Apple devices.")
                            .font(.system(size: 13))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.65))
                            .padding(.horizontal, 20)
                    }
                    
                    if let user = authService.user {
                        // Already Authenticated view
                        VStack(spacing: 16) {
                            VStack(spacing: 6) {
                                Text("Signed In As")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                                Text(user.isAnonymous ? "Anonymous Guest" : (user.email ?? "User"))
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Text("User ID: \(user.uid.prefix(12))...")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Color.white.opacity(0.4))
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(16)
                            
                            Button(role: .destructive) {
                                try? authService.signOut()
                            } label: {
                                Text("Sign Out of Firebase")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.red.opacity(0.12))
                                    .cornerRadius(14)
                            }
                        }
                    } else {
                        // Sign In Form
                        VStack(spacing: 14) {
                            TextField("Email Address", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(14)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                            
                            SecureField("Password", text: $password)
                                .padding(14)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                            
                            if let error = authService.errorMessage {
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                            
                            Button {
                                Task {
                                    if isSignUpMode {
                                        try? await authService.signUp(email: email, password: password)
                                    } else {
                                        try? await authService.signIn(email: email, password: password)
                                    }
                                    if authService.isAuthenticated {
                                        dismiss()
                                    }
                                }
                            } label: {
                                HStack {
                                    if authService.isLoading {
                                        ProgressView().tint(.black)
                                    } else {
                                        Text(isSignUpMode ? "Create Account" : "Sign In with Email")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                    }
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(gold)
                                .cornerRadius(14)
                            }
                            
                            Button {
                                isSignUpMode.toggle()
                            } label: {
                                Text(isSignUpMode ? "Already have an account? Sign In" : "New here? Create Account")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(gold)
                            }
                            
                            Divider().background(Color.white.opacity(0.1)).padding(.vertical, 6)
                            
                            // Anonymous Sign In (Zero Friction)
                            Button {
                                Task {
                                    try? await authService.signInAnonymously()
                                    if authService.isAuthenticated {
                                        dismiss()
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.fill.badge.shield.checkmark")
                                    Text("Continue as Guest (Instant 1-Tap)")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(14)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.white.opacity(0.7))
                }
            }
        }
    }
}
