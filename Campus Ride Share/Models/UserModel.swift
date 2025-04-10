//
//  UserModel.swift
//  Cupid
//
//  Created by Yaduraj Singh on 09/04/25.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct User: Identifiable, Codable {
    var id: String
    var name: String
    var age: Int
    var gender: Gender
    var interestedIn: [Gender]
    var bio: String
    var photos: [String] // URLs to photos
    var location: Location?
    var interests: [String]
    var university: String?
    var occupation: String?
    var lastActive: Date
    var createdAt: Date
    
    // Dating preferences
    var maxDistance: Double // in kilometers
    var ageRange: [Int] // [min, max]
    
    // Create a minimal user with just the necessary fields for sign-up
    static func createNewUser(id: String, name: String, email: String) -> User {
        return User(
            id: id,
            name: name,
            age: 0,
            gender: .other,
            interestedIn: [.other],
            bio: "",
            photos: [],
            location: nil,
            interests: [],
            lastActive: Date(),
            createdAt: Date(),
            maxDistance: 50,
            ageRange: [18, 35]
        )
    }
}

struct Location: Codable {
    var latitude: Double
    var longitude: Double
    var city: String
    var country: String
}

enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case nonBinary = "Non-binary"
    case other = "Other"
}

// Authentication state
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    // Callback to notify app coordinator when auth state changes
    var onAuthStateChanged: (() -> Void)?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        // Check if user is already logged in
        if let currentUser = auth.currentUser {
            self.isLoading = true
            fetchUserData(userId: currentUser.uid)
        }
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) {
        isLoading = true
        error = nil
        
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    // Provide user-friendly error messages
                    let authError = error as NSError
                    switch authError.code {
                    case AuthErrorCode.wrongPassword.rawValue:
                        self.error = "Incorrect password. Please try again."
                    case AuthErrorCode.userNotFound.rawValue:
                        self.error = "No account found with this email."
                    case AuthErrorCode.invalidEmail.rawValue:
                        self.error = "Please enter a valid email address."
                    case AuthErrorCode.networkError.rawValue:
                        self.error = "Network error. Please check your connection."
                    default:
                        self.error = "Unable to sign in. Please try again."
                    }
                    return
                }
                
                if let userId = result?.user.uid {
                    self.fetchUserData(userId: userId)
                }
            }
        }
    }
    
    func signUp(email: String, password: String, name: String, birthdate: Date) {
        isLoading = true
        error = nil
        
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    // Provide user-friendly error messages
                    let authError = error as NSError
                    switch authError.code {
                    case AuthErrorCode.emailAlreadyInUse.rawValue:
                        self.error = "This email is already in use."
                    case AuthErrorCode.invalidEmail.rawValue:
                        self.error = "Please enter a valid email address."
                    case AuthErrorCode.weakPassword.rawValue:
                        self.error = "Your password is too weak. Please use at least 6 characters."
                    case AuthErrorCode.networkError.rawValue:
                        self.error = "Network error. Please check your connection."
                    default:
                        self.error = "Unable to create account. Please try again."
                    }
                }
                return
            }
            
            if let userId = result?.user.uid {
                // Create user profile
                let newUser = User.createNewUser(id: userId, name: name, email: email)
                self.saveUserData(user: newUser)
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = "Unable to create your profile. Please try again."
                }
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
                self.onAuthStateChanged?()
            }
        } catch {
            self.error = "Unable to sign out. Please try again."
        }
    }
    
    func resetPassword(email: String) {
        isLoading = true
        error = nil
        
        auth.sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    let authError = error as NSError
                    switch authError.code {
                    case AuthErrorCode.userNotFound.rawValue:
                        self.error = "No account found with this email."
                    case AuthErrorCode.invalidEmail.rawValue:
                        self.error = "Please enter a valid email address."
                    default:
                        self.error = "Unable to reset password. Please try again."
                    }
                    return
                }
                
                // Success case - we don't set any error
                // The view will show success UI when error is nil
            }
        }
    }
    
    // MARK: - Firestore Methods
    
    private func fetchUserData(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    // Handle network errors gracefully
                    let nsError = error as NSError
                    if nsError.domain == NSURLErrorDomain || 
                       (nsError.domain == FirestoreErrorDomain && nsError.code == FirestoreErrorCode.unavailable.rawValue) {
                        // Offline error - handle gracefully
                        self.error = "Please check your internet connection"
                    } else {
                        // Other errors - generic message
                        self.error = "Unable to access your account information"
                    }
                    return
                }
                
                if let document = document, document.exists {
                    do {
                        if let userData = try? document.data(as: User.self) {
                            self.currentUser = userData
                            self.isAuthenticated = true
                            self.onAuthStateChanged?()
                        } else {
                            self.error = "Unable to load your profile"
                        }
                    } catch {
                        self.error = "Unable to load your profile"
                    }
                } else {
                    self.error = "Profile not found"
                }
            }
        }
    }
    
    private func saveUserData(user: User) {
        do {
            try db.collection("users").document(user.id).setData(from: user)
            
            DispatchQueue.main.async {
                self.currentUser = user
                self.isAuthenticated = true
                self.isLoading = false
                self.onAuthStateChanged?()
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                // Generic error message instead of raw error
                self.error = "Unable to save your profile"
            }
        }
    }
    
    // MARK: - Update User Profile
    
    func updateUserProfile(updatedUser: User) {
        isLoading = true
        error = nil
        
        do {
            try db.collection("users").document(updatedUser.id).setData(from: updatedUser)
            
            DispatchQueue.main.async {
                self.currentUser = updatedUser
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                // Generic error message instead of raw error
                self.error = "Unable to update your profile"
            }
        }
    }
    
    // MARK: - Delete Account
    
    func deleteAccount(completion: @escaping (Bool) -> Void) {
        guard let currentUser = auth.currentUser else {
            error = "No user is currently logged in"
            completion(false)
            return
        }
        
        isLoading = true
        error = nil
        
        // 1. Delete user data from Firestore
        db.collection("users").document(currentUser.uid).delete { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = "Failed to delete user data: \(error.localizedDescription)"
                    completion(false)
                }
                return
            }
            
            // 2. Delete user account from Firebase Auth
            currentUser.delete { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        // Handle specific errors
                        let authError = error as NSError
                        if authError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                            self.error = "For security reasons, please sign out and sign in again before deleting your account."
                        } else {
                            self.error = "Failed to delete account: \(error.localizedDescription)"
                        }
                        completion(false)
                        return
                    }
                    
                    // Success
                    self.currentUser = nil
                    self.isAuthenticated = false
                    self.onAuthStateChanged?()
                    completion(true)
                }
            }
        }
    }
} 