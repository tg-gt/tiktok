//
//  AuthView.swift
//  tiktok
//
//  Created by gt on 2/5/25.
//

import SwiftUI

// MARK: - Auth View Mode
enum AuthViewMode {
    case login
    case register
}

// MARK: - Auth View
struct AuthView: View {
    // MARK: - Properties
    @StateObject private var viewModel = AuthViewModel()
    @State private var mode: AuthViewMode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Content
                VStack(spacing: 20) {
                    // Logo or App Name
                    Text("TikTok Clone")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Form Fields
                    VStack(spacing: 15) {
                        if mode == .register {
                            // Display Name Field (Register only)
                            TextField("Display Name", text: $displayName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                        }
                        
                        // Email Field
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        // Password Field
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // Error Message
                    if let error = viewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // Action Button
                    Button(action: {
                        Task {
                            if mode == .login {
                                await viewModel.signIn(email: email, password: password)
                            } else {
                                await viewModel.register(email: email, password: password, displayName: displayName)
                            }
                        }
                    }) {
                        Text(mode == .login ? "Sign In" : "Register")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal)
                    
                    // Mode Switch Button
                    Button(action: {
                        mode = mode == .login ? .register : .login
                        // Clear fields when switching modes
                        email = ""
                        password = ""
                        displayName = ""
                        viewModel.error = nil
                    }) {
                        Text(mode == .login ? "Need an account? Register" : "Already have an account? Sign In")
                            .foregroundColor(.blue)
                    }
                    
                    // Loading Indicator
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Preview Provider
struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}

