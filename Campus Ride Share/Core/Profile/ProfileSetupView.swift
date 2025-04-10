//
//  ProfileSetupView.swift
//  Cupid
//
//  Created by Yaduraj Singh on 09/04/25.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseStorage
import AVFoundation
import UIKit

struct ProfileSetupView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var profileImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var bio = ""
    @State private var gender: Gender = .other
    @State private var interestedIn: [Gender] = []
    @State private var birthdate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var interests: [String] = []
    @State private var occupation = ""
    @State private var university = ""
    @State private var voiceIntroRecording: URL? = nil
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var showConfirmation = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var uploadError: String?
    @State private var showSuccess = false
    @State private var errorMessage = ""
    
    private let steps = ["Add Photo", "About You", "Preferences", "Interests"]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    // Back to Login button
                    Button(action: {
                        // Navigate back to authentication
                        withAnimation {
                            coordinator.goToAuthScreen()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color.black)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.trailing, 8)
                    
                    Text("Complete Your Profile")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(currentStep + 1)/\(steps.count)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Step indicator
                HStack(spacing: 4) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Rectangle()
                            .frame(height: 4)
                            .foregroundColor(index <= currentStep ? .white : Color.gray.opacity(0.3))
                            .animation(.easeInOut, value: currentStep)
                    }
                }
                .padding(.horizontal, 24)
                
                // Step title
                Text(steps[currentStep])
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 30)
                    .padding(.bottom, 20)
                
                // Step content
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case 0:
                            // Profile Photo
                            PhotoSelectionView(profileImage: $profileImage, selectedItem: $selectedItem)
                        case 1:
                            // About You
                            AboutYouView(
                                bio: $bio,
                                gender: $gender,
                                birthdate: $birthdate,
                                occupation: $occupation,
                                university: $university,
                                voiceIntroRecording: $voiceIntroRecording
                            )
                        case 2:
                            // Preferences
                            PreferencesView(interestedIn: $interestedIn)
                        case 3:
                            // Interests
                            InterestsView(selectedInterests: $interests)
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100) // Extra space for button
                }
                
                Spacer()
                
                // Upload progress (only show when uploading)
                if isUploading {
                    VStack(spacing: 8) {
                        ProgressView(value: uploadProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .frame(height: 4)
                            .padding(.horizontal, 24)
                        
                        Text("Saving profile... \(Int(uploadProgress * 100))%")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 16)
                }
                
                // Error message
                if let error = uploadError {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(Color.red.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }
                
                // Navigation buttons
                HStack(spacing: 12) {
                    // Back button (only show if not on first step)
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Next/Complete button
                        Button(action: {
                            if currentStep < steps.count - 1 {
                                withAnimation {
                                    currentStep += 1
                                }
                            } else {
                                saveProfile()
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(isStepValid ? Color.white : Color.gray.opacity(0.3))
                                
                                if authViewModel.isLoading || isUploading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(1.2)
                                } else {
                                    Text(currentStep < steps.count - 1 ? "Continue" : "Complete Profile")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.black)
                                }
                            }
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(!isStepValid || authViewModel.isLoading || isUploading)
                    } else {
                        // For first step, we maintain the same layout with an invisible spacer of fixed width
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 56, height: 56)
                        
                        // Next/Complete button
                        Button(action: {
                            if currentStep < steps.count - 1 {
                                withAnimation {
                                    currentStep += 1
                                }
                            } else {
                                saveProfile()
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(isStepValid ? Color.white : Color.gray.opacity(0.3))
                                
                                if authViewModel.isLoading || isUploading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(1.2)
                                } else {
                                    Text(currentStep < steps.count - 1 ? "Continue" : "Complete Profile")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.black)
                                }
                            }
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(!isStepValid || authViewModel.isLoading || isUploading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            
            // Confirmation overlay
            if showConfirmation {
                ConfirmationOverlay(message: "Profile created successfully!") {
                    // Navigate to main tab view
                    coordinator.completeProfileSetup()
                }
            }
            
            // Success overlay
            if showSuccess {
                successOverlay
            }
        }
        .alert(item: Binding<AlertItem?>(
            get: { 
                if let error = authViewModel.error {
                    return AlertItem(message: error)
                }
                return nil
            },
            set: { _ in authViewModel.error = nil }
        )) { alert in
            Alert(
                title: Text("Error"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var isStepValid: Bool {
        switch currentStep {
        case 0:
            return profileImage != nil
        case 1:
            return !bio.isEmpty && bio.count >= 10
        case 2:
            return !interestedIn.isEmpty
        case 3:
            return !interests.isEmpty && interests.count >= 3
        default:
            return false
        }
    }
    
    private func saveProfile() {
        guard let currentUser = authViewModel.currentUser else { return }
        guard let profileImage = profileImage else { return }
        
        isUploading = true
        uploadError = nil
        
        // Calculate age from birthdate
        let age = Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year ?? 0
        
        // Create updated user object
        var updatedUser = currentUser
        updatedUser.bio = bio
        updatedUser.gender = gender
        updatedUser.interestedIn = interestedIn
        updatedUser.age = age
        updatedUser.interests = interests
        updatedUser.occupation = occupation.isEmpty ? nil : occupation
        updatedUser.university = university.isEmpty ? nil : university
        
        let dispatchGroup = DispatchGroup()
        
        // Upload photo to Firebase Storage
        dispatchGroup.enter()
        uploadProfileImage(profileImage, userId: currentUser.id) { result in
            switch result {
            case .success(let photoUrl):
                // Add the photo URL to the user's photos array
                updatedUser.photos = [photoUrl]
                dispatchGroup.leave()
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isUploading = false
                    self.uploadError = "Failed to upload profile image: \(error.localizedDescription)"
                }
                dispatchGroup.leave()
                return
            }
        }
        
        // Upload voice intro if available
        if let voiceIntroRecording = voiceIntroRecording {
            dispatchGroup.enter()
            uploadVoiceIntro(voiceIntroRecording, userId: currentUser.id) { result in
                switch result {
                case .success(let voiceUrl):
                    updatedUser.voiceIntroURL = voiceUrl
                    dispatchGroup.leave()
                    
                case .failure(let error):
                    print("Voice intro upload failed: \(error.localizedDescription)")
                    // We continue even if voice upload fails
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            // Update user profile in Firestore
            self.authViewModel.updateUserProfile(updatedUser: updatedUser)
            
            DispatchQueue.main.async {
                self.isUploading = false
                self.showConfirmation = true
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Significantly reduce image size and quality before upload
        let maxDimension: CGFloat = 800
        let scaledImage = resizeImage(image, targetSize: CGSize(width: maxDimension, height: maxDimension))
        
        // Use much lower compression quality
        guard let imageData = scaledImage.jpegData(compressionQuality: 0.5) else {
            completion(.failure(NSError(domain: "ProfileSetup", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
            return
        }
        
        // Check if file size is reasonable (less than 1MB)
        let fileSize = imageData.count / 1024 / 1024
        print("Image size after compression: \(fileSize)MB")
        
        // Create a storage reference with a simpler path to avoid characters that might cause issues
        let fileName = "profile_\(Date().timeIntervalSince1970).jpg"
        let storageRef = Storage.storage().reference().child("profiles/\(userId)/\(fileName)")
        
        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload with explicit completion
        let uploadTask = storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("Upload complete, metadata: \(String(describing: metadata))")
            
            // Use a longer delay to ensure Firebase has fully processed the upload
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.getDownloadURL(storageRef: storageRef, attempts: 3) { result in
                    switch result {
                    case .success(let url):
                        print("Successfully got download URL: \(url)")
                        completion(.success(url))
                    case .failure(let error):
                        print("Failed to get download URL: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            }
        }
        
        // Monitor upload progress
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            DispatchQueue.main.async {
                self.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            }
        }
    }
    
    private func uploadVoiceIntro(_ audioURL: URL, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        // Create a unique file name
        let timestamp = Int(Date().timeIntervalSince1970)
        let audioRef = storageRef.child("voice_intros/\(userId)/intro_\(timestamp).m4a")
        
        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"
        
        // Upload the file
        let uploadTask = audioRef.putFile(from: audioURL, metadata: metadata)
        
        // Monitor upload progress
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            DispatchQueue.main.async {
                self.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            }
        }
        
        // Handle upload completion
        uploadTask.observe(.success) { _ in
            // Get download URL
            audioRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "VoiceIntroError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                completion(.success(downloadURL.absoluteString))
            }
        }
        
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "VoiceIntroError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])))
            }
        }
    }
    
    // Helper function to get download URL with retry mechanism
    private func getDownloadURL(storageRef: StorageReference, attempts: Int, completion: @escaping (Result<String, Error>) -> Void) {
        guard attempts > 0 else {
            completion(.failure(NSError(domain: "ProfileSetup", code: 2, userInfo: [NSLocalizedDescriptionKey: "Maximum retry attempts reached"])))
            return
        }
        
        storageRef.downloadURL { url, error in
            if let error = error {
                print("Download URL error (attempts left: \(attempts-1)): \(error.localizedDescription)")
                
                // Wait and retry
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.getDownloadURL(storageRef: storageRef, attempts: attempts - 1, completion: completion)
                }
                return
            }
            
            guard let downloadURL = url else {
                let error = NSError(domain: "ProfileSetup", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])
                
                // Wait and retry
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.getDownloadURL(storageRef: storageRef, attempts: attempts - 1, completion: completion)
                }
                return
            }
            
            completion(.success(downloadURL.absoluteString))
        }
    }
    
    // Helper function to resize image
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Use the smaller ratio to ensure the image fits within the target size
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.green)
                
                Text("Profile Created!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Your profile has been successfully created.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                
                Button(action: {
                    // Navigate to the main view
                    coordinator.completeProfileSetup()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(25)
                }
                .padding(.top, 10)
                .padding(.horizontal, 30)
            }
            .padding(30)
            .background(Color.black)
            .cornerRadius(20)
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }
}

struct PhotoSelectionView: View {
    @Binding var profileImage: UIImage?
    @Binding var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose a profile photo that clearly shows your face")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .padding(.vertical, 16)
                    .shadow(color: Color.white.opacity(0.1), radius: 10)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                    )
                    .padding(.vertical, 16)
            }
            
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    Image(systemName: "photo")
                        .font(.system(size: 16))
                    Text("Select Photo")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white, lineWidth: 1)
                )
            }
            .onChange(of: selectedItem) { oldValue, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.profileImage = image
                        }
                    }
                }
            }
            
            if profileImage != nil {
                Button(action: {
                    profileImage = nil
                    selectedItem = nil
                }) {
                    Text("Remove Photo")
                        .font(.system(size: 16))
                        .foregroundColor(Color.red.opacity(0.8))
                        .padding(.top, 8)
                }
            }
            
            Text("This will be visible to other users")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.top, 24)
        }
        .padding(.vertical, 20)
    }
}

struct AboutYouView: View {
    @Binding var bio: String
    @Binding var gender: Gender
    @Binding var birthdate: Date
    @Binding var occupation: String
    @Binding var university: String
    @Binding var voiceIntroRecording: URL?
    @State private var isRecording = false
    @State private var isPlaying = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var playbackProgress: TimeInterval = 0
    @State private var audioDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var playerObserver: AVPlayerObserver?
    @State private var audioLevels: [CGFloat] = Array(repeating: 0.05, count: 30)
    @State private var playbackTimer: Timer?
    
    @State private var activeField: Field? = nil
    @State private var isGenderExpanded = false
    @State private var showDatePicker = false
    
    enum Field: Hashable {
        case bio, occupation, university
    }
    
    private let bioMaxLength = 150
    private let maxRecordingDuration: TimeInterval = 30 // 30 seconds max recording
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Bio section with more elegant styling
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("About You")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(bio.count)/\(bioMaxLength)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(bioLengthColor)
                        .opacity(bio.isEmpty ? 0 : 1)
                        .animation(.easeInOut(duration: 0.2), value: bio.isEmpty)
                }
                .padding(.horizontal, 4)
                
                ZStack(alignment: .topLeading) {
                    // Decorative elements
                    HStack {
                        VStack {
                            Circle()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 8, height: 8)
                            
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(6)
                    
                    // Placeholder
                    if bio.isEmpty {
                        VStack {
                            HStack {
                                Text("Tell us about yourself...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray.opacity(0.7))
                                    .padding(.top, 12)
                                    .padding(.leading, 16)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                    
                    // Actual text editor
                    TextEditor(text: Binding(
                        get: { bio },
                        set: { bio = String($0.prefix(bioMaxLength)) }
                    ))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(12)
                    .onTapGesture {
                        activeField = .bio
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.5), Color.black.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            activeField == .bio 
                                ? LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                                : LinearGradient(
                                    gradient: Gradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.2)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  ),
                            lineWidth: activeField == .bio ? 1.5 : 1
                        )
                        .animation(.easeInOut(duration: 0.3), value: activeField == .bio)
                )
                .frame(height: 150)
                // Subtle animation when tapped
                .scaleEffect(activeField == .bio ? 1.01 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: activeField == .bio)
            }
            
            // Voice Intro section with improved visualization
            VStack(alignment: .leading, spacing: 12) {
                Text("Voice Introduction")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.5), Color.black.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.2)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    VStack(spacing: 20) {
                        // Audio waveform visualization
                        ZStack {
                            // Main circle background
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            isRecording ? Color.white.opacity(0.2) : Color.white.opacity(0.1),
                                            isRecording ? Color.white.opacity(0.1) : Color.white.opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                            
                            // Waveform visualization
                            HStack(spacing: 2) {
                                ForEach(0..<audioLevels.count, id: \.self) { index in
                                    RoundedRectangle(cornerRadius: 1.5)
                                        .fill(
                                            isRecording 
                                                ? Color.white.opacity(0.8)
                                                : (isPlaying 
                                                   ? Color.white.opacity(0.8) 
                                                   : Color.white.opacity(0.3))
                                        )
                                        .frame(width: 3, height: audioLevels[index] * 50)
                                        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: audioLevels[index])
                                }
                            }
                            .frame(width: 140)
                            .opacity(isRecording || isPlaying ? 1 : 0.6)
                            
                            // Main action button
                            Button(action: {
                                if isRecording {
                                    stopRecording()
                                    triggerHapticFeedback(.medium)
                                } else if let _ = voiceIntroRecording {
                                    togglePlayback()
                                    triggerHapticFeedback(.light)
                                } else {
                                    startRecording()
                                    triggerHapticFeedback(.medium)
                                }
                            }) {
                                Circle()
                                    .fill(
                                        isRecording ? Color.white.opacity(0.5) : Color.white.opacity(0.1)
                                    )
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: 
                                              isRecording ? "stop.fill" :
                                                (voiceIntroRecording != nil ? 
                                                 (isPlaying ? "pause.fill" : "play.fill") : 
                                                    "mic.fill")
                                        )
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white)
                                    )
                                    .shadow(color: isRecording ? Color.white.opacity(0.3) : Color.clear, radius: 8)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        
                        // Status and timing
                        VStack(spacing: 8) {
                            if isRecording {
                                // Recording time with animated indicator
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(Color.white.opacity(0.8))
                                        .frame(width: 8, height: 8)
                                        .opacity(isRecording ? 1 : 0)
                                        .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isRecording)
                                    
                                    Text(formattedDuration)
                                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                            } else if voiceIntroRecording != nil {
                                if isPlaying {
                                    // Playback progress
                                    VStack(spacing: 6) {
                                        Text("\(formattedTimeInterval(playbackProgress)) / \(formattedTimeInterval(audioDuration))")
                                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                                            .foregroundColor(.white)
                                        
                                        // Progress bar
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(height: 4)
                                                
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.white.opacity(0.8))
                                                    .frame(width: max(0, min(geometry.size.width * CGFloat(playbackProgress / max(audioDuration, 1)), geometry.size.width)), height: 4)
                                            }
                                        }
                                        .frame(height: 4)
                                    }
                                } else {
                                    Text("Voice intro recorded (\(formattedTimeInterval(audioDuration)))")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                }
                            } else {
                                Text("Add a voice intro to stand out")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(height: 40)
                        
                        // Control buttons with improved layout
                        HStack(spacing: 20) {
                            if voiceIntroRecording != nil && !isRecording {
                                // Delete button with confirmation
                                Button(action: {
                                    triggerHapticFeedback(.medium)
                                    deleteRecording()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14))
                                        Text("Delete")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.6))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                            )
                                    )
                                }
                                
                                // Re-record button
                                Button(action: {
                                    deleteRecording()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        startRecording()
                                    }
                                    triggerHapticFeedback(.light)
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 14))
                                        Text("Re-record")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.2))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                            )
                                    )
                                }
                            } else if isRecording {
                                Spacer()
                                
                                // Recording time remaining indicator
                                Text("\(Int(maxRecordingDuration - recordingDuration))s remaining")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                Spacer()
                            } else {
                                Spacer()
                                
                                // Record button
                                Button(action: {
                                    startRecording()
                                    triggerHapticFeedback(.medium)
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "mic.fill")
                                            .font(.system(size: 14))
                                        Text("Start Recording")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.2)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                }
                                
                                Spacer()
                            }
                        }
                        
                        // Help text
                        if !isRecording && voiceIntroRecording == nil {
                            Text("Add a short voice introduction (30s max)")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                    }
                    .padding(20)
                }
                .frame(height: 270)
            }
            
            // Gender selection with improved UI
            VStack(alignment: .leading, spacing: 10) {
                Text("Gender Identity")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                // Updated gender selection layout with fixed width
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Gender.allCases, id: \.self) { genderOption in
                        EnhancedGenderButton(
                            title: genderOption.rawValue,
                            isSelected: gender == genderOption,
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    gender = genderOption
                                }
                            }
                        )
                    }
                }
            }
            
            // Birthdate with stylish picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Birthdate")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showDatePicker.toggle()
                    }
                }) {
                    HStack {
                        Text(formattedBirthdate)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                if showDatePicker {
                    DatePicker(
                        "",
                        selection: $birthdate,
                        in: Calendar.current.date(byAdding: .year, value: -80, to: Date())!...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorInvert()
                    .colorMultiply(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Text("You must be at least 18 years old")
                    .font(.system(size: 13))
                    .foregroundColor(.gray.opacity(0.7))
                    .padding(.top, 4)
            }
            
            // Optional fields
            VStack(alignment: .leading, spacing: 16) {
                EnhancedInputField(
                    text: $occupation,
                    placeholder: "What do you do?",
                    label: "Occupation",
                    icon: "briefcase",
                    isOptional: true,
                    isActive: activeField == .occupation,
                    onTap: { activeField = .occupation }
                )
                
                EnhancedInputField(
                    text: $university,
                    placeholder: "Where do you study?",
                    label: "University",
                    icon: "book",
                    isOptional: true,
                    isActive: activeField == .university,
                    onTap: { activeField = .university }
                )
            }
        }
        .onAppear {
            setupAudioSession()
        }
        .onTapGesture {
            // Dismiss active fields when tapping outside
            activeField = nil
            showDatePicker = false
        }
    }
    
    private var bioLengthColor: Color {
        let ratio = Double(bio.count) / Double(bioMaxLength)
        if ratio < 0.7 {
            return .gray
        } else if ratio < 0.9 {
            return .yellow
        } else {
            return .red
        }
    }
    
    var formattedBirthdate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: birthdate)
    }
    
    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Audio Recording Functions
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    private func startRecording() {
        // Create a temporary file URL
        let audioFilename = getDocumentsDirectory().appendingPathComponent("voice_intro.m4a")
        
        // Recording settings
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            // Create and start the recorder
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            // Start the timer to track recording duration and update audio levels
            recordingDuration = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                recordingDuration += 0.1
                
                // Update audio visualization
                self.updateAudioLevels()
                
                // Stop recording when max duration is reached
                if recordingDuration >= maxRecordingDuration {
                    stopRecording()
                }
            }
            
            isRecording = true
        } catch {
            print("Could not start recording: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false
        
        // Reset audio levels to idle state
        for i in 0..<audioLevels.count {
            audioLevels[i] = 0.05 + CGFloat.random(in: 0...0.1)
        }
        
        // Save the recording URL
        if let url = audioRecorder?.url, FileManager.default.fileExists(atPath: url.path) {
            voiceIntroRecording = url
            
            // Get the duration of the recorded audio
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                audioDuration = player.duration
            } catch {
                print("Could not determine audio duration: \(error)")
            }
        }
    }
    
    private func togglePlayback() {
        guard let url = voiceIntroRecording else { return }
        
        if isPlaying {
            // Stop playback
            audioPlayer?.stop()
            isPlaying = false
            playbackTimer?.invalidate()
            playbackTimer = nil
        } else {
            // Start playback
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioDuration = audioPlayer?.duration ?? 0
                playerObserver = AVPlayerObserver(onComplete: {
                    self.isPlaying = false
                    self.playbackProgress = 0
                    self.playbackTimer?.invalidate()
                    self.playbackTimer = nil
                    self.regenerateIdleWaveform()
                })
                audioPlayer?.delegate = playerObserver
                audioPlayer?.play()
                isPlaying = true
                
                // Start tracking playback progress
                playbackProgress = 0
                playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    if let player = self.audioPlayer, player.isPlaying {
                        self.playbackProgress = player.currentTime
                        self.updatePlaybackWaveform()
                    }
                }
                
                // Create initial playback waveform
                createRandomWaveform(animated: true)
            } catch {
                print("Could not play recording: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteRecording() {
        if let url = voiceIntroRecording, FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
                voiceIntroRecording = nil
            } catch {
                print("Could not delete recording: \(error.localizedDescription)")
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // Function for formatted time intervals
    private func formattedTimeInterval(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Update audio visualization levels during recording
    private func updateAudioLevels() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        
        recorder.updateMeters()
        
        // Shift values to the left
        audioLevels.removeFirst()
        
        // Add new value at the end
        let normalizedValue = max(0.05, min(1.0, CGFloat(1.0 + recorder.averagePower(forChannel: 0) / 50)))
        audioLevels.append(normalizedValue)
    }
    
    // Generate random waveform for playback visualization
    private func createRandomWaveform(animated: Bool = false) {
        for i in 0..<audioLevels.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + (animated ? Double(i) * 0.02 : 0)) {
                self.audioLevels[i] = CGFloat.random(in: 0.2...0.8)
            }
        }
    }
    
    // Update waveform during playback
    private func updatePlaybackWaveform() {
        // Create a bouncing effect for playback
        if isPlaying {
            for i in 0..<audioLevels.count {
                if i % 3 == Int(playbackProgress * 10) % 3 {
                    audioLevels[i] = CGFloat.random(in: 0.6...0.9)
                } else {
                    audioLevels[i] = CGFloat.random(in: 0.2...0.5)
                }
            }
        }
    }
    
    // Generate idle waveform when not playing
    private func regenerateIdleWaveform() {
        for i in 0..<audioLevels.count {
            audioLevels[i] = 0.05 + CGFloat.random(in: 0...0.1)
        }
    }
    
    // Add haptic feedback
    private func triggerHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// Helper class for audio playback completion
class AVPlayerObserver: NSObject, AVAudioPlayerDelegate {
    private let onComplete: () -> Void
    
    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        super.init()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onComplete()
    }
}

struct EnhancedGenderButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? .black : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: 46)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.white : Color.black.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.white : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct EnhancedInputField: View {
    @Binding var text: String
    let placeholder: String
    let label: String
    let icon: String
    let isOptional: Bool
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                if isOptional {
                    Text("(optional)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isActive || !text.isEmpty ? .white.opacity(0.8) : .gray.opacity(0.5))
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isActive ? Color.white : Color.gray.opacity(0.3),
                                lineWidth: isActive ? 1.5 : 1
                            )
                            .animation(.easeInOut(duration: 0.2), value: isActive)
                    )
            )
            .onTapGesture {
                onTap()
            }
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct PreferencesView: View {
    @Binding var interestedIn: [Gender]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("I'm interested in")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Select all that apply")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(.bottom, 12)
            
            VStack(spacing: 16) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    EnhancedPreferenceButton(
                        gender: gender,
                        isSelected: interestedIn.contains(gender),
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if interestedIn.contains(gender) {
                                    interestedIn.removeAll { $0 == gender }
                                } else {
                                    interestedIn.append(gender)
                                }
                            }
                        }
                    )
                }
            }
        }
    }
}

// New enhanced preference button with icons
struct EnhancedPreferenceButton: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void
    
    // Get icon based on gender
    private var genderIcon: String {
        switch gender {
        case .male:
            return "person.fill"
        case .female:
            return "figure.dress"
        case .nonBinary:
            return "person.3.fill"
        case .other:
            return "person.fill.questionmark"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with background circle
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.2) : Color.black.opacity(0.3))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: genderIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? .white : .gray)
                }
                
                Text(gender.rawValue)
                    .font(.system(size: 16, weight: isSelected ? .medium : .regular))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Animated checkmark
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.white : Color.gray.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 18, height: 18)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? 
                          LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.15)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ) : 
                          LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? 
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.white.opacity(0.5), Color.white.opacity(0.2)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) : 
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InterestsView: View {
    @Binding var selectedInterests: [String]
    private let minInterests = 3
    
    // Organize interests into categories for better visual grouping
    private let allInterests = [
        "Photography", "Music", "Cooking", "Travel", 
        "Reading", "Fitness", "Art", "Gaming", 
        "Movies", "Hiking", "Dancing", "Yoga", 
        "Fashion", "Technology", "Sports", "Writing",
        "Pets", "Nature", "Food", "Coffee"
    ]
    
    // Define consistent column layout
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            // Header section
            VStack(alignment: .leading, spacing: 6) {
                Text("Select what you're into")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Choose at least \(minInterests) interests")
                    .font(.system(size: 16))
                    .foregroundColor(selectedInterests.count >= minInterests ? .gray : .orange)
            }
            
            // Interest buttons in a clean grid layout
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(allInterests, id: \.self) { interest in
                    EnhancedInterestButton(
                        title: interest,
                        isSelected: selectedInterests.contains(interest),
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedInterests.contains(interest) {
                                    selectedInterests.removeAll { $0 == interest }
                                } else {
                                    selectedInterests.append(interest)
                                }
                            }
                        }
                    )
                }
            }
            
            // Feedback message
            if selectedInterests.count >= minInterests {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                    
                    Text("Great choices! You can select more if you'd like.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.top, 8)
                .transition(.opacity)
                .animation(.easeIn, value: selectedInterests.count >= minInterests)
            }
        }
    }
}

struct EnhancedInterestButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    // Get icon based on the interest
    private var interestIcon: String {
        switch title.lowercased() {
        case "photography": return "camera.fill"
        case "music": return "music.note"
        case "cooking": return "flame.fill"
        case "travel": return "airplane"
        case "reading": return "book.fill"
        case "fitness": return "figure.run"
        case "art": return "paintbrush.fill"
        case "gaming": return "gamecontroller.fill"
        case "movies": return "film.fill"
        case "hiking": return "mountain.2.fill"
        case "dancing": return "music.quarternote.3"
        case "yoga": return "figure.yoga"
        case "fashion": return "tshirt.fill"
        case "technology": return "desktopcomputer"
        case "sports": return "sportscourt.fill"
        case "writing": return "pencil"
        case "pets": return "pawprint.fill"
        case "nature": return "leaf.fill"
        case "food": return "fork.knife"
        case "coffee": return "cup.and.saucer.fill"
        default: return "tag.fill"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: interestIcon)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .black : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 44)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .fill(isSelected ? 
                          Color.white :
                          Color.black.opacity(0.3))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? 
                            Color.white :
                            Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .contentShape(Capsule())
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .shadow(color: isSelected ? Color.white.opacity(0.2) : Color.clear, radius: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }
}

struct ConfirmationOverlay: View {
    let message: String
    let action: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Button(action: action) {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.white)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
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
            .shadow(color: Color.white.opacity(0.1), radius: 20)
            .padding(32)
        }
    }
}

struct AlertItem: Identifiable {
    var id = UUID()
    var message: String
}

#Preview {
    ProfileSetupView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppCoordinator())
} 