//
//  PersonalizationAuthView.swift
//  Muhurta
//
//  Authentication Gate for Personalization.
//  Supports Google OAuth and Email/Password Sign Up & Sign In with Firebase Auth.
//

import SwiftUI
import FirebaseAuth

struct PersonalizationAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authService = FirebaseAuthService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var onAuthenticated: (() -> Void)? = nil
    
    private let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Cosmic Emblem
                        cosmicHeader
                            .padding(.top, 16)
                        
                        // Google OAuth Button (High Priority)
                        googleSignInButton
                        
                        // Or Divider
                        HStack(spacing: 12) {
                            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                            Text("OR WITH EMAIL")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.45))
                            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                        }
                        .padding(.horizontal, 10)
                        
                        // Email/Password Form
                        emailAuthCard
                        
                        // Value Proposition Highlights
                        personalizationBenefitsCard
                        
                        // Continue as Guest Option
                        Button {
                            Task {
                                try? await authService.signInAnonymously()
                                onAuthenticated?()
                                dismiss()
                            }
                        } label: {
                            Text("Continue as Guest Seeker")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.55))
                                .underline()
                        }
                        .padding(.top, 6)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") { dismiss() }
                        .foregroundColor(gold)
                }
            }
            .alert("Authentication Notice", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Cosmic Header
    
    private var cosmicHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [gold.opacity(0.25), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 90, height: 90)
                
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 42))
                    .foregroundColor(gold)
            }
            
            Text("Personalize Your Sacred Time")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Sign in or create an account to celebrate your Birthdays & Anniversaries strictly on authentic Vedic Tithis, synchronized with Kali Yuga 5,128.")
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.65))
                .lineSpacing(3)
                .padding(.horizontal, 10)
        }
    }
    
    // MARK: - Google OAuth Button
    
    private var googleSignInButton: some View {
        Button {
            signInWithGoogleAction()
        } label: {
            HStack(spacing: 12) {
                // Actual official Google 4-color G logo
                Image("GoogleLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                
                Text("Continue with Google")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.white.opacity(0.12), radius: 10, y: 3)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Email Auth Card
    
    private var emailAuthCard: some View {
        VStack(spacing: 14) {
            Picker("Mode", selection: $isSignUpMode) {
                Text("Sign In").tag(false)
                Text("Create Account").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 4)
            
            VStack(spacing: 10) {
                TextField("Email address", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(13)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                
                SecureField("Password (min 6 characters)", text: $password)
                    .padding(13)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                    .foregroundColor(.white)
            }
            
            Button {
                submitEmailAuth()
            } label: {
                HStack {
                    if authService.isLoading {
                        ProgressView().tint(.black)
                    } else {
                        Text(isSignUpMode ? "Create Sacred Account" : "Sign In with Email")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(gold)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(email.isEmpty || password.count < 6 || authService.isLoading)
            .opacity((email.isEmpty || password.count < 6) ? 0.5 : 1.0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }
    
    // MARK: - Personalization Benefits
    
    private var personalizationBenefitsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHY SIGN IN?")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(gold)
            
            benefitRow(
                icon: "sparkles",
                title: "Vedic Birthday (Janmadina) Wishes",
                desc: "Wished on your exact solar-lunar Tithi each Vedic year, not arbitrary Roman dates."
            )
            benefitRow(
                icon: "heart.fill",
                title: "Wedding Anniversary (Vivāha Divasa)",
                desc: "Track sacred anniversaries with countdowns in the current Kali Yuga year."
            )
            benefitRow(
                icon: "icloud.fill",
                title: "End-to-End Firebase Cloud Sync",
                desc: "Never lose your consecrated dates; safely synced across your devices."
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }
    
    private func benefitRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(gold)
                .font(.system(size: 13))
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
                    .lineSpacing(2)
            }
        }
    }
    
    // MARK: - Actions
    
    private func signInWithGoogleAction() {
        Task {
            do {
                try await authService.signInWithGoogle()
                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.success)
                onAuthenticated?()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func submitEmailAuth() {
        Task {
            do {
                if isSignUpMode {
                    try await authService.signUp(email: email, password: password)
                } else {
                    try await authService.signIn(email: email, password: password)
                }
                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.success)
                onAuthenticated?()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}
