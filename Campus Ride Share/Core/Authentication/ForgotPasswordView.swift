//
//  ForgotPasswordView.swift
//  Cupid
//
//  Created by Yaduraj Singh on 09/04/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var isAnimating = false
    @State private var showSuccessMessage = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Content
            VStack(alignment: .center, spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 24)
                    
                    Spacer()
                }
                .padding(.top, 16)
                
                // Logo area
                VStack(spacing: 8) {
                    Text("cupid")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundColor(.white)
                        .tracking(1)
                        .padding(.top, 30)
                        .opacity(isAnimating ? 1 : 0)
                    
                    Text("Reset Password")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1 : 0)
                        .padding(.bottom, 8)
                    
                    Text("Enter your email and we'll send you a\nlink to reset your password")
                        .font(.system(size: 15))
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                        .opacity(isAnimating ? 1 : 0)
                        .padding(.bottom, 40)
                }
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 0.6), value: isAnimating)
                
                // Form field
                VStack(spacing: 16) {
                    // Email field
                    VStack(alignment: .leading) {
                        Text("EMAIL")
                            .font(.system(size: 12))
                            .foregroundColor(Color.gray)
                            .padding(.leading, 4)
                            .padding(.bottom, 8)
                        
                        HStack(spacing: 16) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(Color.white)
                                .frame(width: 20)
                            
                            TextField("", text: $email)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .textContentType(.emailAddress)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(Color.black)
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                // Error message
                if let error = authViewModel.error {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(Color.red.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .transition(.opacity)
                }
                
                // Success message
                if showSuccessMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                        
                        Text("Password reset email sent!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Please check your inbox")
                            .font(.system(size: 14))
                            .foregroundColor(Color.gray)
                    }
                    .padding(.vertical, 24)
                    .transition(.opacity)
                }
                
                Spacer()
                
                // Reset Password button
                Button(action: {
                    resetPassword()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(isFormValid ? Color.white : Color.gray.opacity(0.3))
                        
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(1.2)
                        } else {
                            Text("Reset Password")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.black)
                        }
                    }
                    .frame(height: 56)
                }
                .disabled(authViewModel.isLoading || !isFormValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                // Back to login
                Button("Back to Login") {
                    dismiss()
                }
                .font(.system(size: 15))
                .foregroundColor(Color.gray)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isAnimating = true
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        return !email.isEmpty && email.contains("@") && email.contains(".")
    }
    
    private func resetPassword() {
        authViewModel.resetPassword(email: email)
        
        // Show success message after a slight delay if no error occurred
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if authViewModel.error == nil {
                withAnimation {
                    showSuccessMessage = true
                }
                
                // Dismiss screen after a few seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthViewModel())
} 