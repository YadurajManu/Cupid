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
    @State private var selectedPhotoIndex = 0
    @State private var isEditMode = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let user = authViewModel.currentUser {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Profile Photo Gallery
                        PhotoGalleryView(photos: user.photos, selectedIndex: $selectedPhotoIndex)
                            .frame(height: 450)
                        
                        // User Info Card - Floating above the gallery
                        VStack(alignment: .leading, spacing: 24) {
                            // Name, Age and Occupation
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(user.name)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("\(user.age)")
                                        .font(.system(size: 26, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.leading, 4)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        isEditMode = true
                                    }) {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                
                                if let occupation = user.occupation {
                                    Text(occupation)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                if let university = user.university {
                                    Text(university)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            // Bio Section
                            if !user.bio.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("About Me")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Text(user.bio)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineSpacing(4)
                                }
                                .padding(.top, 8)
                            }
                            
                            // Voice Intro Section
                            if let _ = user.voiceIntroURL {
                                VoiceIntroPlayerView(voiceIntroURL: user.voiceIntroURL)
                                    .padding(.top, 8)
                            }
                            
                            // Interests Section
                            if !user.interests.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Interests")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    // Interest tags in a wrapped layout
                                    FlowLayout(spacing: 8) {
                                        ForEach(user.interests, id: \.self) { interest in
                                            Text(interest)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.white)
                                                )
                                        }
                                    }
                                }
                                .padding(.top, 16)
                            }
                            
                            // Preferences Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Preferences")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                HStack(spacing: 16) {
                                    // Gender Preference
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Interested in")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.6))
                                        
                                        Text(user.interestedIn.map { $0.rawValue }.joined(separator: ", "))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.2))
                                        .frame(height: 36)
                                    
                                    // Age Range
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Age range")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.6))
                                        
                                        Text("\(user.ageRange[0])-\(user.ageRange[1])")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                )
                            }
                            .padding(.top, 16)
                            
                            Spacer(minLength: 40)
                            
                            // Account Management Buttons
                            VStack(spacing: 16) {
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
                                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                
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
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.top, 16)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                        .padding(.bottom, 36)
                        .background(
                            Rectangle()
                                .fill(Color.black)
                                .cornerRadius(30, corners: [.topLeft, .topRight])
                                .edgesIgnoringSafeArea(.bottom)
                                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: -10)
                        )
                        .offset(y: -30)
                    }
                }
                .sheet(isPresented: $isEditMode) {
                    EditProfileView(isPresented: $isEditMode, user: user)
                        .environmentObject(authViewModel)
                }
            } else {
                // Loading or no user state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .foregroundColor(.white)
                    
                    Text("Loading profile...")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            
            // Error message
            if let error = authViewModel.error {
                VStack {
                    Spacer()
                    
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(Color.red.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    
                    Spacer()
                }
            }
            
            // Delete confirmation overlay
            if showDeleteAccountConfirmation {
                deleteAccountConfirmationOverlay
            }
            
            // Delete success overlay
            if showDeleteAccountSuccess {
                deleteAccountSuccessOverlay
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

// Photo Gallery Component
struct PhotoGalleryView: View {
    let photos: [String]
    @Binding var selectedIndex: Int
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if photos.isEmpty {
                // Placeholder when no photos
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    VStack(spacing: 16) {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("No photos yet")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            } else {
                // Photo gallery
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        // Photos
                        TabView(selection: $selectedIndex) {
                            ForEach(0..<photos.count, id: \.self) { index in
                                AsyncImage(url: URL(string: photos[index])) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else if phase.error != nil {
                                        Color.gray.opacity(0.3)
                                            .overlay(
                                                Image(systemName: "exclamationmark.triangle")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.white.opacity(0.6))
                                            )
                                    } else {
                                        ZStack {
                                            Color.black
                                            ProgressView()
                                                .scaleEffect(1.5)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        
                        // Custom page indicators
                        HStack(spacing: 8) {
                            ForEach(0..<photos.count, id: \.self) { index in
                                Circle()
                                    .fill(index == selectedIndex ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(index == selectedIndex ? 1.2 : 1.0)
                                    .animation(.spring(), value: selectedIndex)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .clipped()
    }
}

// Voice Intro Player Component
struct VoiceIntroPlayerView: View {
    let voiceIntroURL: String?
    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Voice Introduction")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 16) {
                // Play/Pause Button
                Button(action: {
                    isPlaying.toggle()
                    // Audio player logic would go here
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                
                // Progress bar and timing
                VStack(alignment: .leading, spacing: 6) {
                    // Player progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 4)
                            
                            // Progress indicator
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: geometry.size.width * playbackProgress, height: 4)
                        }
                        .cornerRadius(2)
                    }
                    .frame(height: 4)
                    
                    // Timing text
                    HStack {
                        Text(formatTime(playbackProgress * 30)) // Assuming 30 sec max
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text(formatTime(30)) // Max duration
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// Flexible Flow Layout for Interest Tags
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var width: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if rowWidth + size.width > containerWidth {
                // New row
                width = max(width, rowWidth)
                height += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                // Same row
                rowWidth += size.width + (rowWidth > 0 ? spacing : 0)
                rowHeight = max(rowHeight, size.height)
            }
        }
        
        // Add the last row
        height += rowHeight
        width = max(width, rowWidth)
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var rowX: CGFloat = bounds.minX
        var rowY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if rowX + size.width > bounds.maxX {
                // New row
                rowX = bounds.minX
                rowY += rowHeight + spacing
                rowHeight = 0
            }
            
            subview.place(
                at: CGPoint(x: rowX, y: rowY),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            
            rowHeight = max(rowHeight, size.height)
            rowX += size.width + spacing
        }
    }
}

// Helper for rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct MainAppView: View {
    var body: some View {
        AppCoordinatorView()
    }
}

// Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Binding var isPresented: Bool
    
    let user: User
    
    @State private var name: String
    @State private var bio: String
    @State private var occupation: String
    @State private var university: String
    @State private var selectedInterests: [String]
    @State private var interestedIn: [Gender]
    @State private var minAge: Double
    @State private var maxAge: Double
    @State private var isSaving = false
    @State private var showPhotoOptions = false
    
    // Available interests for selection
    private let allInterests = [
        "Photography", "Music", "Cooking", "Travel", 
        "Reading", "Fitness", "Art", "Gaming", 
        "Movies", "Hiking", "Dancing", "Yoga", 
        "Fashion", "Technology", "Sports", "Writing",
        "Pets", "Nature", "Food", "Coffee"
    ]
    
    // Initialize with user data
    init(isPresented: Binding<Bool>, user: User) {
        self._isPresented = isPresented
        self.user = user
        
        // Initialize state variables with user data
        self._name = State(initialValue: user.name)
        self._bio = State(initialValue: user.bio)
        self._occupation = State(initialValue: user.occupation ?? "")
        self._university = State(initialValue: user.university ?? "")
        self._selectedInterests = State(initialValue: user.interests)
        self._interestedIn = State(initialValue: user.interestedIn)
        self._minAge = State(initialValue: Double(user.ageRange[0]))
        self._maxAge = State(initialValue: Double(user.ageRange[1]))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Image
                        Button(action: {
                            showPhotoOptions = true
                        }) {
                            if let photoUrl = user.photos.first, !photoUrl.isEmpty {
                                AsyncImage(url: URL(string: photoUrl)) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                            .overlay(editImageOverlay)
                                    } else {
                                        placeholderImage
                                    }
                                }
                            } else {
                                placeholderImage
                            }
                        }
                        .padding(.top, 20)
                        
                        // Edit Form
                        VStack(spacing: 24) {
                            // Name
                            FormField(title: "Name", text: $name)
                            
                            // Bio
                            FormTextEditor(title: "About me", text: $bio, minHeight: 120)
                            
                            // Occupation
                            FormField(title: "Occupation (optional)", text: $occupation)
                            
                            // University
                            FormField(title: "University (optional)", text: $university)
                            
                            // Interest selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Interests")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Select at least 3 interests")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                // Interest tags
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                                    ForEach(allInterests, id: \.self) { interest in
                                        InterestToggleButton(
                                            title: interest,
                                            isSelected: selectedInterests.contains(interest),
                                            action: {
                                                if selectedInterests.contains(interest) {
                                                    selectedInterests.removeAll { $0 == interest }
                                                } else {
                                                    selectedInterests.append(interest)
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.top, 8)
                            }
                            
                            // Gender interest selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("I'm interested in")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                VStack(spacing: 12) {
                                    ForEach(Gender.allCases, id: \.self) { gender in
                                        Button(action: {
                                            if interestedIn.contains(gender) {
                                                if interestedIn.count > 1 {
                                                    interestedIn.removeAll { $0 == gender }
                                                }
                                            } else {
                                                interestedIn.append(gender)
                                            }
                                        }) {
                                            HStack {
                                                Text(gender.rawValue)
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.white)
                                                
                                                Spacer()
                                                
                                                Image(systemName: interestedIn.contains(gender) ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(interestedIn.contains(gender) ? .white : .gray)
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(interestedIn.contains(gender) ? Color.white.opacity(0.1) : Color.black)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                        }
                                    }
                                }
                            }
                            
                            // Age Range Slider
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Age Range")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("\(Int(minAge)) - \(Int(maxAge)) years")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                RangeSlider(minValue: $minAge, maxValue: $maxAge, minLimit: 18, maxLimit: 80)
                                    .frame(height: 30)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 100)
                }
                
                // Save button at the bottom
                VStack {
                    Spacer()
                    
                    Button(action: saveProfile) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.white)
                            
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .scaleEffect(1.2)
                            } else {
                                Text("Save Changes")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(height: 56)
                        .padding(.horizontal, 24)
                    }
                    .disabled(isSaving || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.5)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Edit Profile")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.white)
                    }
                }
            }
            .alert(isPresented: $showPhotoOptions) {
                Alert(
                    title: Text("Photo Options"),
                    message: Text("This would normally open a photo picker to update your profile photo."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && 
        bio.count >= 10 && 
        selectedInterests.count >= 3 &&
        !interestedIn.isEmpty
    }
    
    private var placeholderImage: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 120, height: 120)
            .overlay(
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
            )
            .overlay(editImageOverlay)
    }
    
    private var editImageOverlay: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(8)
    }
    
    private func saveProfile() {
        isSaving = true
        
        // Create updated user object
        var updatedUser = user
        updatedUser.name = name
        updatedUser.bio = bio
        updatedUser.occupation = occupation.isEmpty ? nil : occupation
        updatedUser.university = university.isEmpty ? nil : university
        updatedUser.interests = selectedInterests
        updatedUser.interestedIn = interestedIn
        updatedUser.ageRange = [Int(minAge), Int(maxAge)]
        
        // Update user profile in Firestore
        authViewModel.updateUserProfile(updatedUser: updatedUser)
        
        // Add a small delay to show progress
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSaving = false
            isPresented = false
        }
    }
}

// Reusable form field component
struct FormField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            TextField("", text: $text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
        }
    }
}

// Reusable text editor component
struct FormTextEditor: View {
    let title: String
    @Binding var text: String
    let minHeight: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Tell us about yourself...")
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.top, 16)
                        .padding(.leading, 16)
                }
                
                TextEditor(text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(4)
            }
            .frame(minHeight: minHeight)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
}

// Range slider component for age selection
struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let minLimit: Double
    let maxLimit: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                
                // Selected range
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: width(for: maxValue, in: geometry) - width(for: minValue, in: geometry), height: 4)
                    .offset(x: width(for: minValue, in: geometry))
                
                // Min thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .position(x: width(for: minValue, in: geometry), y: geometry.size.height / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { dragValue in
                                let newValue = calculateValue(for: dragValue.location.x, in: geometry)
                                if newValue >= minLimit && newValue <= maxValue - 1 {
                                    minValue = newValue
                                }
                            }
                    )
                
                // Max thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .position(x: width(for: maxValue, in: geometry), y: geometry.size.height / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { dragValue in
                                let newValue = calculateValue(for: dragValue.location.x, in: geometry)
                                if newValue <= maxLimit && newValue >= minValue + 1 {
                                    maxValue = newValue
                                }
                            }
                    )
            }
        }
    }
    
    private func width(for value: Double, in geometry: GeometryProxy) -> CGFloat {
        let range = maxLimit - minLimit
        let relativeValue = value - minLimit
        let ratio = relativeValue / range
        return geometry.size.width * CGFloat(ratio)
    }
    
    private func calculateValue(for position: CGFloat, in geometry: GeometryProxy) -> Double {
        let range = maxLimit - minLimit
        let ratio = min(max(position / geometry.size.width, 0), 1)
        return minLimit + (range * Double(ratio))
    }
}

// Add the missing InterestToggleButton component
struct InterestToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white : Color.black)
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.white : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
} 