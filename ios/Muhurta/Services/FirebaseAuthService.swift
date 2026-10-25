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
                self?.user = user
                self?.isAuthenticated = user != nil
                self?.isAnonymous = user?.isAnonymous ?? false
                
                if user != nil {
                    Task {
                        await VedicLifeEventManager.shared.syncWithFirestore()
                    }
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
    
    /// Creates a new user account with email and password.
    public func signUp(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
            self.isAnonymous = false
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Signs out the current user and clears active session.
    public func signOut() throws {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isAuthenticated = false
            self.isAnonymous = false
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
}
