//
//  tiktokApp.swift
//  tiktok
//
//  Created by gt on 2/3/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAnalytics

@main
struct tiktokApp: App {
    // MARK: - Properties
    @StateObject private var authViewModel = AuthViewModel()
    
    // MARK: - Initialization
    init() {
        // Debug log for tracking app initialization
        print("DEBUG: Configuring Firebase...")
        
        // Configure Firebase when app launches
        FirebaseApp.configure()
        
        // Debug log to confirm Firebase configuration
        print("DEBUG: Firebase configuration complete")
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch authViewModel.authState {
                case .signedIn:
                    // TODO: Replace with FeedView when implemented
                    Text("Welcome \(authViewModel.user?.displayName ?? "User")!")
                        .environmentObject(authViewModel)
                case .signedOut:
                    AuthView()
                        .environmentObject(authViewModel)
                }
            }
        }
    }
}
