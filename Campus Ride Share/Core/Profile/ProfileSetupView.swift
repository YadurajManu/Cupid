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
                                university: $university
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
                        }
                        .disabled(!isStepValid || authViewModel.isLoading || isUploading)
                        .frame(maxWidth: .infinity)
                    } else {
                        // Center aligned continue button for first step
                        Spacer()
                        
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
                            .frame(width: UIScreen.main.bounds.width - 48) // Adjust width with proper margins
                        }
                        .disabled(!isStepValid || authViewModel.isLoading || isUploading)
                        
                        Spacer()
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
        
        // Upload photo to Firebase Storage
        uploadProfileImage(profileImage, userId: currentUser.id) { result in
            switch result {
            case .success(let photoUrl):
                // Add the photo URL to the user's photos array
                updatedUser.photos = [photoUrl]
                
                // Update user profile in Firestore
                self.authViewModel.updateUserProfile(updatedUser: updatedUser)
                
                DispatchQueue.main.async {
                    self.isUploading = false
                    self.showConfirmation = true
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isUploading = false
                    self.uploadError = "Failed to upload profile image: \(error.localizedDescription)"
                }
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
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            DispatchQueue.main.async {
                self.uploadProgress = percentComplete
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
            .onChange(of: selectedItem) { newItem in
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
    
    private let bioMaxLength = 150
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("BIO")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(bio.count)/\(bioMaxLength)")
                        .font(.system(size: 12))
                        .foregroundColor(bioLengthColor)
                }
                
                TextEditor(text: Binding(
                    get: { bio },
                    set: { bio = String($0.prefix(bioMaxLength)) }
                ))
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(12)
                .frame(height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .background(Color.black)
                )
                
                Text("Tell others about yourself")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("GENDER")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Picker("", selection: $gender) {
                    ForEach(Gender.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .colorInvert()
                .colorMultiply(Color.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("BIRTHDATE")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                DatePicker(
                    "",
                    selection: $birthdate,
                    in: Calendar.current.date(byAdding: .year, value: -80, to: Date())!...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .colorInvert()
                .colorMultiply(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .background(Color.black)
                )
                
                Text("You must be at least 18 years old")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            SimpleInputField(text: $occupation, label: "OCCUPATION (OPTIONAL)")
            SimpleInputField(text: $university, label: "UNIVERSITY (OPTIONAL)")
        }
    }
    
    private var bioLengthColor: Color {
        if bio.count > bioMaxLength - 20 {
            return bio.count >= bioMaxLength ? .red : .orange
        }
        return .gray
    }
}

struct SimpleInputField: View {
    @Binding var text: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            TextField("", text: $text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .background(Color.black)
                )
        }
    }
}

struct PreferencesView: View {
    @Binding var interestedIn: [Gender]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("I'm interested in")
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Text("Select all that apply")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.bottom, 8)
            
            VStack(spacing: 12) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    PreferenceToggleButton(
                        title: gender.rawValue,
                        isSelected: interestedIn.contains(gender),
                        action: {
                            if interestedIn.contains(gender) {
                                interestedIn.removeAll { $0 == gender }
                            } else {
                                interestedIn.append(gender)
                            }
                        }
                    )
                }
            }
        }
    }
}

struct InterestsView: View {
    @Binding var selectedInterests: [String]
    private let minInterests = 3
    
    private let allInterests = [
        "Photography", "Music", "Cooking", "Travel", 
        "Reading", "Fitness", "Art", "Gaming", 
        "Movies", "Hiking", "Dancing", "Yoga", 
        "Fashion", "Technology", "Sports", "Writing",
        "Pets", "Nature", "Food", "Coffee"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Select what you're into")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Text("Choose at least \(minInterests) interests")
                    .font(.system(size: 14))
                    .foregroundColor(selectedInterests.count >= minInterests ? .gray : .orange)
            }
            
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
            
            if selectedInterests.count >= minInterests {
                Text("Great choices! You can select more if you'd like.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.top, 16)
            }
        }
    }
}

struct PreferenceToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

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