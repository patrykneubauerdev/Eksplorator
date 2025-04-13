//
//  FirestoreService.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 25/01/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

@MainActor
class FirestoreService: ObservableObject {
    
    
    @Published var urbexes: [Urbex] = []
    @Published var isUrbexAdded = false
    @Published var isLoading = true
    
    
    private var db = Firestore.firestore()
   
    
    
    static let sampleUrbex = Urbex(
           id: "1",
           addedBy: "John Doe",
           addedDate: Timestamp(date: Date()),
           city: "Warsaw",
           country: "Poland",
           description: "This is a description of a sample urbex location.",
           imageURL: "https://firebasestorage.googleapis.com/v0/b/eksplorator-2137.firebasestorage.app/o/sampleUrbexImage.jpg?alt=media&token=a16649c2-be89-407c-adf3-9e8d0d5b7807",
           latitude: 52.2297,
           longitude: 21.0122,
           name: "Sample Urbex Location",
           likes: [],
           dislikes: []
           
       )
    
 
    init(autoFetchUrbexes: Bool = true) {
        Task {
            if autoFetchUrbexes {
                await fetchUrbexes()
            }
            isLoading = false
        }
    }
    
    
    
    func fetchUrbexes() async {
        do {
         
            let snapshot = try await db.collection("urbexes").getDocuments()
            let fetchedUrbexes = snapshot.documents.compactMap { document in
                do {
                    return try document.data(as: Urbex.self)
                } catch {
                    print("Error mapping urbex: \(error.localizedDescription) for document ID: \(document.documentID)")
                    return nil
                }
            }
            
            
            self.urbexes = fetchedUrbexes
        } catch {
            print("Document download error: \(error.localizedDescription)")
        }
    }
    
    
    
    func addUrbexToUser(urbex: Urbex) async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        do {
           
            var urbexWithID = urbex
            if urbex.id == nil {
                urbexWithID.id = UUID().uuidString
            }
            
       
         try   db.collection("urbexes").document(urbexWithID.id ?? "").setData(from: urbexWithID) { error in
                if let error = error {
                    print("Error saving urbex: \(error)")
                }
            }

       
        try    db.collection("users").document(userID).collection("urbexes").addDocument(from: urbexWithID) { error in
                if let error = error {
                    print("Error saving urbex to user's collection: \(error)")
                }
            }

          
            var user = try await fetchUserFromFirestore(userID: userID)
            user.urbexes.append(urbexWithID.id ?? "")
            
           
           try db.collection("users").document(userID).setData(from: user) { error in
                if let error = error {
                    print("Error saving user data: \(error)")
                }
            }
            
        } catch {
            print("Error adding urbex: \(error)")
        }
    }
    
    func fetchUrbexesByIds(ids: [String]) async throws -> [Urbex] {
         var urbexes: [Urbex] = []
         for id in ids {
             let urbexDoc = try await db.collection("urbexes").document(id).getDocument()
             if let urbex = try? urbexDoc.data(as: Urbex.self) {
                 urbexes.append(urbex)
             }
         }
         return urbexes
     }
    
    func fetchUrbexByID(_ urbexID: String) async -> Urbex? {
        let docRef = db.collection("urbexes").document(urbexID)
        do {
            let document = try await docRef.getDocument()
            if document.data() != nil {
                return try? document.data(as: Urbex.self)
            } else {
                print("No data found for urbex with ID \(urbexID)")
                return nil
            }
        } catch {
            print("Error fetching urbex by ID \(urbexID): \(error)")
            return nil
        }
    }
    
    func fetchUrbexesForUser() async {
        isLoading = true 
        
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            isLoading = false
            return
        }

        do {
            let userSnapshot = try await db.collection("users").document(userID).getDocument()
            guard let user = try? userSnapshot.data(as: User.self) else {
                isLoading = false
                return
            }

            let urbexes: [Urbex] = try await fetchUrbexesByIds(ids: user.urbexes)
            
            DispatchQueue.main.async {
                self.urbexes = urbexes
                self.isLoading = false
            }
        } catch {
            print("Error fetching urbexes: \(error)")
            isLoading = false
        }
    }
    
    func fetchUserFromFirestore(userID: String) async throws -> User {
         let userSnapshot = try await db.collection("users").document(userID).getDocument()
         guard let user = try? userSnapshot.data(as: User.self) else {
             throw NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
         }
         return user
     }
    
    func toggleLike(for urbexID: String, userID: String) async {
        let docRef = db.collection("urbexes").document(urbexID)
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                db.runTransaction({ (transaction, errorPointer) -> Any? in
                    do {
                        let snapshot = try transaction.getDocument(docRef) as DocumentSnapshot
                        var urbex = try snapshot.data(as: Urbex.self)

                        if urbex.likes.contains(userID) {
                            urbex.likes.removeAll { $0 == userID }
                        } else {
                            urbex.likes.append(userID)
                            urbex.dislikes.removeAll { $0 == userID }
                        }

                        try transaction.setData(from: urbex, forDocument: docRef)
                        return nil
                    } catch {
                        errorPointer?.pointee = error as NSError
                        return nil
                    }
                }) { (_, error) in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            print("Error toggling like: \(error)")
        }
    }
    
 

    func toggleDislike(for urbexID: String, userID: String) async {
        let docRef = db.collection("urbexes").document(urbexID)
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                db.runTransaction({ (transaction, errorPointer) -> Any? in
                    do {
                        let snapshot = try transaction.getDocument(docRef) as DocumentSnapshot
                        var urbex = try snapshot.data(as: Urbex.self)

                        if urbex.dislikes.contains(userID) {
                            urbex.dislikes.removeAll { $0 == userID }
                        } else {
                            urbex.dislikes.append(userID)
                            urbex.likes.removeAll { $0 == userID }
                        }

                        try transaction.setData(from: urbex, forDocument: docRef)
                        return nil
                    } catch {
                        errorPointer?.pointee = error as NSError
                        return nil
                    }
                }) { (_, error) in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            print("Error toggling dislike: \(error)")
        }
    }

    
    
    func toggleFavoriteUrbex(for userID: String, urbexID: String) async throws {
        let userRef = db.collection("users").document(userID)

        do {
            let snapshot = try await userRef.getDocument()
            if var userData = snapshot.data(), var favoriteUrbexes = userData["favoriteUrbexes"] as? [String] {
                
                if favoriteUrbexes.contains(urbexID) {
                    favoriteUrbexes.removeAll { $0 == urbexID }
                } else {
                    favoriteUrbexes.append(urbexID)
                }

                userData["favoriteUrbexes"] = favoriteUrbexes
                try await userRef.setData(userData, merge: true)
            }
        } catch {
            print("Błąd podczas aktualizacji ulubionych urbexów: \(error.localizedDescription)")
            throw error
        }
    }
    
    
    
    func deleteUrbex(_ urbex: Urbex) async {
         guard let urbexID = urbex.id,
               let userID = Auth.auth().currentUser?.uid else { return }
         
         do {
           
             try await db.collection("urbexes").document(urbexID).delete()
             
          
             let userUrbexes = try await db.collection("users")
                 .document(userID)
                 .collection("urbexes")
                 .whereField("id", isEqualTo: urbexID)
                 .getDocuments()
             
             for document in userUrbexes.documents {
                 try await document.reference.delete()
             }
             
           
             var user = try await fetchUserFromFirestore(userID: userID)
             user.urbexes.removeAll { $0 == urbexID }
             
             try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                 do {
                     try db.collection("users").document(userID).setData(from: user) { error in
                         if let error = error {
                             continuation.resume(throwing: error)
                         } else {
                             continuation.resume()
                         }
                     }
                 } catch {
                     continuation.resume(throwing: error)
                 }
             }
         } catch {
             print("Error deleting urbex: \(error)")
         }
       }
    
    
    
    

    
   
}
