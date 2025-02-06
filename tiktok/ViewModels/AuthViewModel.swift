//
//  AuthViewModel.swift
//  tiktok
//
//  Created by gt on 2/5/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Auth State
enum AuthState {
    case signedIn
    case signedOut
}

// MARK: - Auth View Model
@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Properties
    @Published var user: User?
    @Published var authState: AuthState = .signedOut
    @Published var isLoading = false
    @Published var error: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    // MARK: - Init
    init() {
        // Setup auth state listener
        auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.authState = user != nil ? .signedIn : .signedOut
            if let user = user {
                Task {
                    await self.fetchUserProfile(userId: user.uid)
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async {
        do {
            isLoading = true
            error = nil
            let result = try await auth.signIn(withEmail: email, password: password)
            await fetchUserProfile(userId: result.user.uid)
        } catch {
            self.error = error.localizedDescription
            print("DEBUG: Sign in error: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    /// Register with email and password
    func register(email: String, password: String, displayName: String?) async {
        do {
            isLoading = true
            error = nil
            // Create auth user
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Create user profile
            let user = User(
                email: email,
                displayName: displayName,
                interests: nil,
                avatarURL: nil,
                createdAt: Date()
            )
            
            // Store in Firestore
            try await storeUserProfile(user: user, userId: result.user.uid)
            
            // Fetch the stored profile
            await fetchUserProfile(userId: result.user.uid)
        } catch {
            self.error = error.localizedDescription
            print("DEBUG: Registration error: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    /// Sign out the current user
    func signOut() {
        do {
            try auth.signOut()
            user = nil
            authState = .signedOut
        } catch {
            self.error = error.localizedDescription
            print("DEBUG: Sign out error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Fetch user profile from Firestore
    private func fetchUserProfile(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let user = try? document.data(as: User.self) {
                self.user = user
            }
        } catch {
            print("DEBUG: Error fetching user profile: \(error.localizedDescription)")
        }
    }
    
    /// Store user profile in Firestore
    private func storeUserProfile(user: User, userId: String) async throws {
        try await db.collection("users").document(userId).setData([
            "email": user.email,
            "displayName": user.displayName as Any,
            "interests": user.interests as Any,
            "avatarURL": user.avatarURL as Any,
            "createdAt": Timestamp(date: user.createdAt)
        ])
    }
}

