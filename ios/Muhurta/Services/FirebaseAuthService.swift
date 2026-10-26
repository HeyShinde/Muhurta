//
//  FirebaseAuthService.swift
//  Muhurta
//
//  Manages Firebase Authentication (Anonymous, Email/Password, and Session State)
//  with automatic persistence and clean SwiftUI integration.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
public final class FirebaseAuthService: ObservableObject {
    public static let shared = FirebaseAuthService()
    
    @Published public private(set) var user: User?
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var isAnonymous: Bool = false
    @Published public var errorMessage: String?
    @Published public var isLoading: Bool = false
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    private init() {
        self.user = Auth.auth().currentUser
        self.isAuthenticated = Auth.auth().currentUser != nil
        self.isAnonymous = Auth.auth().currentUser?.isAnonymous ?? false
        
        setupAuthListener()
    }
    
    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func setupAuthListener() {
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                let previousUid = self?.user?.uid
                let newUid = user?.uid
                
                // If user changed to a different account, wipe local state immediately
                if let p = previousUid, let n = newUid, p != n {
                    self?.clearLocalUserData()
                }
                
                self?.user = user
                self?.isAuthenticated = user != nil
                self?.isAnonymous = user?.isAnonymous ?? false
                
                if let user = user {
                    if let name = user.displayName, !name.trimmingCharacters(in: .whitespaces).isEmpty {
                        UserDefaults.standard.set(name, forKey: "vedic_seeker_name")
                    }
                    Task {
                        await VedicLifeEventManager.shared.syncWithFirestore()
                    }
                } else {
                    self?.clearLocalUserData()
                }
            }
        }
    }
    
    public var displayName: String? {
        if let name = user?.displayName, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            return name
        }
        for info in user?.providerData ?? [] {
            if let name = info.displayName, !name.trimmingCharacters(in: .whitespaces).isEmpty {
                return name
            }
        }
        return nil
    }
    
    public var photoURL: URL? {
        if let url = user?.photoURL {
            return url
        }
        for info in user?.providerData ?? [] {
            if let url = info.photoURL {
                return url
            }
        }
        return nil
    }
    
    // MARK: - Authentication Actions
    
    /// Signs in using Google OAuth via Firebase OAuthProvider.
    public func signInWithGoogle() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        clearLocalUserData()
        
        let provider = OAuthProvider(providerID: "google.com")
        provider.scopes = ["email", "profile"]
        provider.customParameters = [
            "prompt": "select_account"
        ]
        
        do {
            let credential = try await provider.credential(with: nil)
            let result = try await Auth.auth().signIn(with: credential)
            try? await result.user.reload()
            self.user = Auth.auth().currentUser ?? result.user
            self.isAuthenticated = true
            self.isAnonymous = false
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Signs in anonymously for seamless immediate onboarding without barriers.
    public func signInAnonymously() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().signInAnonymously()
            self.user = result.user
            self.isAuthenticated = true
            self.isAnonymous = true
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Signs in with existing email and password.
    public func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        clearLocalUserData()
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
            self.isAnonymous = false
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Creates a new user account with email, password, and full name.
    /// Also sends a verification email to the user.
    public func signUp(email: String, password: String, fullName: String? = nil) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        clearLocalUserData()
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            if let name = fullName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
                let changeReq = result.user.createProfileChangeRequest()
                changeReq.displayName = name
                try? await changeReq.commitChanges()
                
                UserDefaults.standard.set(name, forKey: "vedic_seeker_name")
            }
            
            // Dispatch verification email to user
            try? await result.user.sendEmailVerification()
            
            // Reload user to ensure profile changes are reflected
            try? await result.user.reload()
            
            self.user = Auth.auth().currentUser ?? result.user
            self.isAuthenticated = true
            self.isAnonymous = false
            
            // Sync with Firestore for newly registered user
            await VedicLifeEventManager.shared.syncWithFirestore()
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Dispatches email verification to the authenticated user's email.
    public func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.sendEmailVerification()
    }
    
    /// Updates the seeker's display name across Firebase Auth, Firestore, and local state.
    public func updateDisplayName(name: String) async throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        guard let currentUser = Auth.auth().currentUser else { return }
        let changeReq = currentUser.createProfileChangeRequest()
        changeReq.displayName = trimmed
        try await changeReq.commitChanges()
        try await currentUser.reload()
        
        self.user = Auth.auth().currentUser
        UserDefaults.standard.set(trimmed, forKey: "vedic_seeker_name")
        
        // Synchronize display name with Firestore user document
        let userDoc = Firestore.firestore().collection("users").document(currentUser.uid)
        try await userDoc.setData(["displayName": trimmed], merge: true)
    }
    
    /// Reloads current user state from Firebase (to check email verification status, etc.)
    public func reloadUser() async {
        try? await Auth.auth().currentUser?.reload()
        self.user = Auth.auth().currentUser
    }
    
    /// Clears all local milestones, personal spiritual identity, and dinacharya completions on sign out.
    public func clearLocalUserData() {
        // 1. Clear consecrated milestones & events
        VedicLifeEventManager.shared.clearAllLocalData()
        
        // 2. Clear personal seeker spiritual identity
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "vedic_seeker_name")
        defaults.removeObject(forKey: "vedic_gotra")
        defaults.removeObject(forKey: "vedic_nakshatra")
        defaults.removeObject(forKey: "vedic_rashi")
        defaults.removeObject(forKey: "vedic_ishta_devata")
        defaults.removeObject(forKey: "sacredSankalpa")
        
        // 3. Clear daily dinacharya checklist completions
        let dictionary = defaults.dictionaryRepresentation()
        for key in dictionary.keys where key.hasPrefix("dinacharya_") {
            defaults.removeObject(forKey: key)
        }
        
        print("FirebaseAuthService: Cleared all local user milestones and spiritual identity.")
    }
    
    /// Signs out the current user and clears active session and local storage.
    public func signOut() throws {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isAuthenticated = false
            self.isAnonymous = false
            clearLocalUserData()
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Deletes the current user account and clears active session and all data (Required by Apple Review Guideline 5.1.1(v)).
    public func deleteAccount() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let currentUser = Auth.auth().currentUser else { return }
        let uid = currentUser.uid
        
        // Clean up Firestore documents before deleting Auth user
        let userDoc = Firestore.firestore().collection("users").document(uid)
        if let lifeEvents = try? await userDoc.collection("life_events").getDocuments() {
            for doc in lifeEvents.documents {
                try? await doc.reference.delete()
            }
        }
        try? await userDoc.delete()
        
        do {
            try await currentUser.delete()
            self.user = nil
            self.isAuthenticated = false
            self.isAnonymous = false
            clearLocalUserData()
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
}
