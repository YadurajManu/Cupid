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
        }
    }
}

struct MainAppView: View {
    var body: some View {
        AppCoordinatorView()
    }
} 