//
//  AppCoordinator.swift
//  Cupid
//
//  Created by Yaduraj Singh on 09/04/25.
//

import SwiftUI
import FirebaseAuth

enum AppState {
    case onboarding
    case authentication
    case profileSetup
    case main
}

class AppCoordinator: ObservableObject {
    @Published var appState: AppState = .authentication
    private var authViewModel: AuthViewModel
    
    init() {
        // Init auth view model
        self.authViewModel = AuthViewModel()
        
        // Add callback to handle auth state changes
        self.authViewModel.onAuthStateChanged = { [weak self] in
            self?.handleAuthStateChange()
        }
        
        // Check initial state
        checkInitialState()
    }
    
    private func checkInitialState() {
        // Check if user is already logged in
        if let currentUser = Auth.auth().currentUser {
            if isNewUser(currentUser) {
                // New user needs to complete profile
                appState = .profileSetup
            } else {
                // Existing user goes to main
                appState = .main
            }
        } else {
            // Not logged in, go to authentication
            appState = .authentication
        }
    }
    
    private func isNewUser(_ user: FirebaseAuth.User) -> Bool {
        // A user is considered "new" if they've just created their account
        // and have not completed their profile setup yet
        return user.metadata.creationDate?.timeIntervalSinceNow ?? 0 > -300 // within last 5 minutes
    }
    
    private func handleAuthStateChange() {
        if authViewModel.isAuthenticated {
            if let currentUser = authViewModel.currentUser, 
               currentUser.photos.isEmpty || currentUser.bio.isEmpty {
                // User hasn't completed their profile
                appState = .profileSetup
            } else {
                // User has a complete profile, go to main app
                appState = .main
            }
        } else {
            // Not authenticated, go to auth
            appState = .authentication
        }
    }
    
    // Expose view model to views
    func getAuthViewModel() -> AuthViewModel {
        return authViewModel
    }
    
    // Navigation actions
    func completeProfileSetup() {
        appState = .main
    }
    
    // Navigate back to authentication screen
    func goToAuthScreen() {
        // If the user is authenticated, sign them out
        if authViewModel.isAuthenticated {
            authViewModel.signOut()
        }
        
        // Set app state to authentication
        appState = .authentication
    }
}

struct AppCoordinatorView: View {
    @StateObject private var coordinator = AppCoordinator()
    
    var body: some View {
        ZStack {
            // Base background
            Color.black.ignoresSafeArea()
            
            // App container
            switch coordinator.appState {
            case .onboarding:
                Text("Onboarding")
                    .environmentObject(coordinator.getAuthViewModel())
                    .environmentObject(coordinator)
            case .authentication:
                AuthView()
                    .environmentObject(coordinator.getAuthViewModel())
                    .environmentObject(coordinator)
            case .profileSetup:
                ProfileSetupView()
                    .environmentObject(coordinator.getAuthViewModel())
                    .environmentObject(coordinator)
            case .main:
                MainTabView()
                    .environmentObject(coordinator.getAuthViewModel())
                    .environmentObject(coordinator)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Empty Dashboard Tab
            DashboardView()
                .tabItem {
                    Label("Explore", systemImage: "flame.fill")
                }
                .tag(0)
            
            // Empty Matches Tab
            MatchesView()
                .tabItem {
                    Label("Matches", systemImage: "heart.fill")
                }
                .tag(1)
            
            // Empty Profile Tab
            UserProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .accentColor(.white)
    }
}

// Empty placeholder views for the tabs
struct DashboardView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Dashboard Coming Soon")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                Text("This is where you'll discover new connections")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

struct MatchesView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Matches Coming Soon")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Connect with your matches here")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

struct UserProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showDeleteAccountConfirmation = false
    @State private var showDeleteAccountSuccess = false
    @State private var isDeleting = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Profile")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                if let user = authViewModel.currentUser {
                    VStack(spacing: 8) {
                        Text(user.name)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                        
                        if let occupation = user.occupation {
                            Text(occupation)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 16)
                }
                
                Spacer()
                
                // Error message
                if let error = authViewModel.error {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(Color.red.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }
                
                // Delete account button
                Button(action: {
                    showDeleteAccountConfirmation = true
                }) {
                    Text("Delete Account")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color.red.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.red.opacity(0.8), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                
                // Sign out button
                Button(action: {
                    authViewModel.signOut()
                }) {
                    Text("Sign Out")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .padding(.top, 20)
            
            // Confirmation dialog overlay
            if showDeleteAccountConfirmation {
                deleteAccountConfirmationOverlay
            }
            
            // Success overlay
            if showDeleteAccountSuccess {
                deleteAccountSuccessOverlay
            }
            
            // Loading overlay
            if isDeleting {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Deleting account...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .transition(.opacity)
            }
        }
    }
    
    private var deleteAccountConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.red)
                
                Text("Delete Account")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("This action cannot be undone. All your data will be permanently deleted.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    // Cancel button
                    Button(action: {
                        showDeleteAccountConfirmation = false
                    }) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    }
                    
                    // Confirm delete button
                    Button(action: {
                        showDeleteAccountConfirmation = false
                        isDeleting = true
                        
                        // Call delete account method
                        authViewModel.deleteAccount { success in
                            isDeleting = false
                            if success {
                                showDeleteAccountSuccess = true
                            }
                            // Error will be shown from the error binding
                        }
                    }) {
                        Text("Delete")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.red.opacity(0.8))
                            )
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(32)
            .transition(.opacity)
        }
    }
    
    private var deleteAccountSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.green)
                
                Text("Account Deleted")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your account has been successfully deleted. Thank you for using our app.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                // This will be dismissed automatically through the app coordinator
                // when the auth state changes
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(32)
            .transition(.opacity)
        }
    }
}

struct MainAppView: View {
    var body: some View {
        AppCoordinatorView()
    }
} 