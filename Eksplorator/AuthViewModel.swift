//
//  AuthViewModel.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 30/01/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

protocol AuthenticationFormProtocol {
    var formIsValid: Bool { get }
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var dailyUrbexAdditions: [String: Int] = [:]
    private var db = Firestore.firestore()
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private let firestoreService = FirestoreService()
    
    init() {
         self.userSession = Auth.auth().currentUser
         
         authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
             DispatchQueue.main.async {
                 self?.userSession = user
                 if user == nil {
                     self?.currentUser = nil
                 } else {
                     self?.checkUserExistence(userId: user?.uid)
                 }
             }
         }
         
         Task {
             await fetchUser()
         }
     }
    
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUser()
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }
    
    private func checkUserExistence(userId: String?) {
        guard let userId = userId else {
            self.userSession = nil
            self.currentUser = nil
            return
        }
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let error = error {
                print("Error during user verification: \(error.localizedDescription)")
                self?.userSession = nil
                self?.currentUser = nil
            } else if document?.exists == false {
             
                self?.userSession = nil
                self?.currentUser = nil
            }
        }
    }
    
    func isUsernameTaken(username: String) async throws -> Bool {
        let querySnapshot = try await Firestore.firestore()
            .collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments()
        
        return !querySnapshot.documents.isEmpty
    }
    
    func getTodayUrbexAdditionCount() -> Int {
        let today = getTodayDateString()
        return dailyUrbexAdditions[today] ?? 0
    }
    
    private func getTodayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    func incrementDailyUrbexCount() {
        let today = getTodayDateString()
        let currentCount = dailyUrbexAdditions[today] ?? 0
        dailyUrbexAdditions[today] = currentCount + 1
        
    
        updateDailyUrbexCountInFirestore()
    }
    
    
    func checkDeviceAccountLimit() async throws -> Bool {
         let deviceID = DeviceIdentifier.getDeviceIdentifier()
         let db = Firestore.firestore()
         
         do {
           
             let snapshot = try await db.collection("devices")
                 .document(deviceID)
                 .getDocument()
             
             if let data = snapshot.data(), let count = data["accountCount"] as? Int {
               
                 return count < 3
             } else {
             
                 return true
             }
         } catch {
             print("Error checking device limit: \(error.localizedDescription)")
         
             return true
         }
     }
    
   
     func registerDeviceForAccount() async {
         let deviceID = DeviceIdentifier.getDeviceIdentifier()
         let db = Firestore.firestore()
         
         do {
             let docRef = db.collection("devices").document(deviceID)
             let snapshot = try await docRef.getDocument()
             
             if let data = snapshot.data(), let count = data["accountCount"] as? Int {
                 // Increment account count
                 try await docRef.updateData(["accountCount": count + 1])
             } else {
               
                 try await docRef.setData([
                     "deviceID": deviceID,
                     "accountCount": 1,
                     "firstRegistered": FieldValue.serverTimestamp()
                 ])
             }
         } catch {
             print("Error registering device: \(error.localizedDescription)")
         }
     }
    
    
    func createUserWithDeviceLimit(withEmail email: String, password: String, username: String) async throws {
      
        let canRegister = try await checkDeviceAccountLimit()
        
        guard canRegister else {
            throw AuthError.deviceLimitReached
        }
        
 
        try await createUser(withEmail: email, password: password, username: username)
        
    
        await registerDeviceForAccount()
    }
   
    
    
    
    private func updateDailyUrbexCountInFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).updateData([
            "dailyUrbexAdditions": dailyUrbexAdditions
        ]) { error in
            if let error = error {
                print("Error updating daily urbex count: \(error.localizedDescription)")
            }
        }
    }
    
    func toggleFavoriteUrbex(urbexID: String) async {
        guard let user = currentUser else { return }
        let userRef = Firestore.firestore().collection("users").document(user.id)
        
        do {
            let snapshot = try await userRef.getDocument()
            var favoriteUrbexes = snapshot.data()?["favoriteUrbexes"] as? [String] ?? []
            
            if favoriteUrbexes.contains(urbexID) {
                favoriteUrbexes.removeAll { $0 == urbexID }
            } else {
                favoriteUrbexes.append(urbexID)
            }
            
            
            try await userRef.setData(["favoriteUrbexes": favoriteUrbexes], merge: true)
            
            
            await fetchUser()
        } catch {
            print("Error while updating favorites: \(error.localizedDescription)")
        }
    }
    
    func createUser(withEmail email: String, password: String, username: String) async throws {
        do {
            if try await isUsernameTaken(username: username) {
                throw AuthError.usernameAlreadyInUse
            }
            
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            
            let user = User(
                id: result.user.uid,
                username: username,
                email: email,
                favoriteUrbexes: [],
                urbexes: []
            )
            
            var encodedUser = try Firestore.Encoder().encode(user)
            
         
            let dailyAdditions: [String: Int] = [:]
            encodedUser["dailyUrbexAdditions"] = dailyAdditions
            
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            
            self.dailyUrbexAdditions = dailyAdditions
            await fetchUser()
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        self.userSession = nil
        self.currentUser = nil
    }
    
    func addUrbexToUser(urbex: Urbex) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userID).updateData([
            "urbexes": FieldValue.arrayUnion([urbex.id ?? ""])
        ]) { error in
            if let error = error {
                print("Error adding urbex to user: \(error.localizedDescription)")
            } else {
                print("Urbex added to user successfully")
            }
        }
    }

    
    func fetchUserData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                do {
                    let user = try document.data(as: User.self)
                    self.currentUser = user
                } catch {
                    print("Error decoding user data: \(error)")
                }
            } else {
                print("User does not exist: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    func reauthenticateAndDeleteUser(password: String) async throws {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }

        let credential = EmailAuthProvider.credential(withEmail: email, password: password)

        do {
            try await user.reauthenticate(with: credential)
            try await Firestore.firestore().collection("users").document(user.uid).delete()
            try await user.delete()
            
           
        } catch {
            throw AuthError.invalidCredentials
        }
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        do {
            try await user.reauthenticate(with: credential)
            try await user.updatePassword(to: newPassword)
        } catch {
            throw mapAuthError(error as NSError)
        }
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }
    
    func fetchUser() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
            if let data = snapshot.data() {
                self.currentUser = User(
                    id: data["id"] as? String ?? "",
                    username: data["username"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    favoriteUrbexes: data["favoriteUrbexes"] as? [String] ?? [],
                    urbexes: data["urbexes"] as? [String] ?? []
                )
                
              
                self.dailyUrbexAdditions = data["dailyUrbexAdditions"] as? [String: Int] ?? [:]
            }
        } catch {
            print("User fetch error: \(error.localizedDescription)")
        }
    }
    
    private func mapAuthError(_ error: NSError) -> AuthError {
        let errorCode = AuthErrorCode(rawValue: error.code)
        
        switch errorCode {
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .networkError:
            return .networkError
        default:
            return .invalidCredentials
        }
    }
    
    enum AuthError: Error, LocalizedError {
        
            case invalidCredentials
            case networkError
            case emailAlreadyInUse
            case usernameAlreadyInUse
            case deviceLimitReached
            
            var errorDescription: String? {
                switch self {
                case .invalidCredentials:
                    return "The email or password you entered is incorrect. Please try again."
                case .networkError:
                    return "Network issue detected. Please check your connection and try again."
                case .emailAlreadyInUse:
                    return "This email is already registered. Please sign in or use a different email."
                case .usernameAlreadyInUse:
                    return "This username is already taken. Please choose a different one."
                case .deviceLimitReached:
                    return "Maximum number of accounts (3) has been reached for this device. Please use an existing account."
                }
            }
        }
    
    
    }


