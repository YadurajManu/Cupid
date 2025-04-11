//
//  AuthView.swift
//  Cupid
//
//  Created by Yaduraj Singh on 09/04/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage

struct AuthView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var isSignIn = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isAnimating = false
    @State private var selectedField: Field? = nil
    @FocusState private var focusedField: Field?
    @State private var showForgotPasswordAlert = false
    @State private var resetPasswordEmail = ""
    @State private var showForgotPasswordView = false
    @State private var showTermsOfService = false
    @State private var showPrivacyPolicy = false
    
    enum Field: Hashable {
        case email, password, name
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Fixed content with no scrolling
            VStack(alignment: .center, spacing: 0) {
                // Logo area
                VStack(spacing: 8) {
                    Text("cupid")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundColor(.white)
                        .tracking(1)
                        .padding(.top, 60)
                        .opacity(isAnimating ? 1 : 0)
                    
                    Text(isSignIn ? "Welcome back" : "Create account")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(Color.gray)
                        .opacity(isAnimating ? 1 : 0)
                        .padding(.bottom, 20)
                }
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 0.6), value: isAnimating)
                
                // Sign In/Sign Up toggle
                HStack(spacing: 0) {
                    SimpleToggleButton(
                        title: "Sign In",
                        isSelected: isSignIn,
                        action: { withAnimation { isSignIn = true } }
                    )
                    
                    SimpleToggleButton(
                        title: "Sign Up",
                        isSelected: !isSignIn,
                        action: { withAnimation { isSignIn = false } }
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                // Form fields
                VStack(spacing: 16) {
                    if !isSignIn {
                        // Name field (only for sign up)
                        SimpleTextField(
                            text: $name,
                            placeholder: "NAME",
                            icon: "person.fill",
                            isSecure: false
                        )
                        .focused($focusedField, equals: .name)
                        .onTapGesture { selectedField = .name; focusedField = .name }
                    }
                    
                    // Email field
                    SimpleTextField(
                        text: $email,
                        placeholder: "EMAIL",
                        icon: "envelope.fill",
                        isSecure: false,
                        keyboardType: .emailAddress,
                        autocapitalize: false
                    )
                    .focused($focusedField, equals: .email)
                    .onTapGesture { selectedField = .email; focusedField = .email }
                    
                    // Password field
                    SimpleTextField(
                        text: $password,
                        placeholder: "PASSWORD",
                        icon: "lock.fill",
                        isSecure: true
                    )
                    .focused($focusedField, equals: .password)
                    .onTapGesture { selectedField = .password; focusedField = .password }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Sign in/sign up button
                Button(action: {
                    focusedField = nil
                    if isSignIn {
                        viewModel.signIn(email: email, password: password)
                    } else {
                        viewModel.signUp(email: email, password: password, name: name, birthdate: Date())
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(isFormValid ? Color.white : Color.gray.opacity(0.3))
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(1.2)
                        } else {
                            Text(isSignIn ? "Sign In" : "Create Account")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .disabled(viewModel.isLoading || !isFormValid)
                .padding(.horizontal, 24)
                
                // Error message
                if let error = viewModel.error {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(Color.red.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .transition(.opacity)
                }
                
                // Forgot password (only for sign in)
                if isSignIn {
                    Button("Forgot Password?") {
                        showForgotPasswordView = true
                    }
                    .font(.system(size: 15))
                    .foregroundColor(Color.gray)
                    .padding(.top, 16)
                    .sheet(isPresented: $showForgotPasswordView) {
                        ForgotPasswordView()
                            .environmentObject(viewModel)
                    }
                }
                
                Spacer(minLength: 20)
                
                // Terms & Privacy
                VStack(spacing: 6) {
                    Text("By continuing, you agree to our")
                        .font(.system(size: 12))
                        .foregroundColor(Color.gray)
                    
                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            // Open terms
                            showTermsOfService = true
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        
                        Text("and")
                            .font(.system(size: 12))
                            .foregroundColor(Color.gray)
                        
                        Button("Privacy Policy") {
                            // Open privacy policy
                            showPrivacyPolicy = true
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
                focusedField = nil
                selectedField = nil
            }
            .sheet(isPresented: $showTermsOfService) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
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
    
    // Validation
    private var isFormValid: Bool {
        let emailIsValid = email.contains("@") && email.contains(".")
        let passwordIsValid = password.count >= 6
        
        if isSignIn {
            return emailIsValid && passwordIsValid
        } else {
            let nameIsValid = name.count >= 2
            return emailIsValid && passwordIsValid && nameIsValid
        }
    }
}

// MARK: - Component Structs
struct SimpleTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let isSecure: Bool
    var keyboardType: UIKeyboardType = .default
    var autocapitalize: Bool = true
    @State private var showPassword = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(placeholder)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color.gray)
                .padding(.leading, 4)
                .padding(.bottom, 8)
            
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(Color.white)
                    .frame(width: 20)
                
                if isSecure && !showPassword {
                    SecureField("", text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .textContentType(.none)
                } else {
                    TextField("", text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .keyboardType(keyboardType)
                        .autocapitalization(autocapitalize ? .words : .none)
                        .textContentType(.none)
                        .autocorrectionDisabled()
                }
                
                if isSecure {
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(Color.gray)
                            .frame(width: 20)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(Color.black)
            )
        }
    }
}

struct SimpleToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(isSelected ? .white : Color.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            
            Rectangle()
                .frame(height: 2)
                .foregroundColor(isSelected ? .white : Color.clear)
                .animation(.easeInOut, value: isSelected)
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}