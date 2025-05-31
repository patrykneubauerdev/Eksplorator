//
//  UrbexDetailsView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 26/01/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.


import SwiftUI
import FirebaseCore
import FirebaseFirestore


struct UrbexDetailsView: View {
    @State var urbex: Urbex
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isFavorite: Bool = false
    @State private var hasLiked: Bool = false
    @State private var hasDisliked: Bool = false
    @State private var hasReported = false
    @State private var showReportSuccessAlert = false
    @State private var showReportSheet = false
    @State private var showAlreadyReportedAlert = false
    @State private var isAddedByAdmin: Bool = false
    @State private var addedByUsername: String = ""
    @State private var hasMarkedActive: Bool = false
    @State private var hasMarkedInactive: Bool = false
    @State private var showLoginAlert = false
    @State private var loginAlertMessage = ""
    
    private let firestoreService = FirestoreService()
    
    
    var totalStatusVotes: Int {
          urbex.activeVotes.count + urbex.inactiveVotes.count
      }
    
    var activePercentage: CGFloat {
           totalStatusVotes > 0 ? CGFloat(urbex.activeVotes.count) / CGFloat(totalStatusVotes) : 0.5
       }

    var totalVotes: Int {
        urbex.likes.count + urbex.dislikes.count
    }

    var likePercentage: CGFloat {
        totalVotes > 0 ? CGFloat(urbex.likes.count) / CGFloat(totalVotes) : 0.5
    }

    var body: some View {
        ZStack {
            Color.semiDark.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let url = URL(string: urbex.imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ShimmerEffectView()
                                    .frame(height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7)
                                            .stroke(.white.opacity(0.7), lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                            case .success(let image):
                                GeometryReader { geo in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: geo.size.width, height: 300)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 7))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 7)
                                                .stroke(.white.opacity(0.7), lineWidth: 1)
                                        )
                                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                                        .animation(.spring(duration: 0.5), value: image)
                                }
                                .frame(height: 300)
                                .padding(.horizontal)
                            case .failure(_):
                                ZStack {
                                    Rectangle()
                                        .foregroundStyle(.gray.opacity(0.3))
                                        .frame(height: 300)
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                .padding(.horizontal)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    
                    VStack(spacing: 16) {
                        Text(urbex.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .minimumScaleFactor(0.6)
                            .lineLimit(4)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 10) {
                        Button(action: {
                            if authViewModel.currentUser?.isGuest ?? false {
                                loginAlertMessage = "You need to be signed in to add urbexes to favorites"
                                showLoginAlert = true
                            } else {
                                Task {
                                    guard let urbexID = urbex.id else { return }
                                    await authViewModel.toggleFavoriteUrbex(urbexID: urbexID)
                                    isFavorite.toggle()
                                    await firestoreService.fetchUrbexes()
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.title3)
                                    .foregroundColor(isFavorite ? .red : .white)
                                Text(isFavorite ? "Remove from Favorites" : "Add to Favorites")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(Color.greyish)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(.white.opacity(0.7), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 15) {
                        HStack(spacing: 30) {
                            Button(action: {
                                if authViewModel.currentUser?.isGuest ?? false {
                                    loginAlertMessage = "You need to be signed in to like urbexes"
                                    showLoginAlert = true
                                } else {
                                    Task {
                                        guard let urbexID = urbex.id, let userID = authViewModel.currentUser?.id else { return }
                                        await firestoreService.toggleLike(for: urbexID, userID: userID)
                                        await updateUrbexData()
                                        hasLiked.toggle()
                                        if hasLiked { hasDisliked = false }
                                    }
                                }
                            }) {
                                VStack {
                                    Image(systemName: hasLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                        .font(.title2)
                                        .foregroundColor(hasLiked ? .green : .white)
                                    Text("\(urbex.likes.count)")
                                        .font(.caption)
                                        .monospacedDigit()
                                }
                            }
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 1, height: 30)
                            
                            Button(action: {
                                if authViewModel.currentUser?.isGuest ?? false {
                                    loginAlertMessage = "You need to be signed in to dislike urbexes"
                                    showLoginAlert = true
                                } else {
                                    Task {
                                        guard let urbexID = urbex.id, let userID = authViewModel.currentUser?.id else { return }
                                        await firestoreService.toggleDislike(for: urbexID, userID: userID)
                                        await updateUrbexData()
                                        hasDisliked.toggle()
                                        if hasDisliked { hasLiked = false }
                                    }
                                }
                            }) {
                                VStack {
                                    Image(systemName: hasDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                        .font(.title2)
                                        .foregroundColor(hasDisliked ? .red : .white)
                                    Text("\(urbex.dislikes.count)")
                                        .font(.caption)
                                        .monospacedDigit()
                                }
                            }
                        }
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: 250, height: 10)
                                .foregroundStyle(
                                    LinearGradient(stops: [
                                        .init(color: .green, location: 0.0),
                                        .init(color: .green.opacity(0.8), location: 0.3),
                                        .init(color: .red.opacity(0.8), location: 0.7),
                                        .init(color: .red, location: 1.0)
                                    ], startPoint: .leading, endPoint: .trailing)
                                )
                            
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: 2, height: 15)
                                .foregroundColor(.white)
                                .offset(x: (1 - likePercentage) * 250)
                                .animation(.easeInOut, value: likePercentage)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.greyish)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(.white.opacity(0.7), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    
                    
                    
                    VStack(spacing: 15) {
                             Text("Status:")
                                 .font(.headline)
                                 .foregroundColor(.white)
                                 .padding(.top, 5)
                             
                             HStack(spacing: 30) {
                                 Button(action: {
                                     if authViewModel.currentUser?.isGuest ?? false {
                                         loginAlertMessage = "You need to be signed in to mark urbex status"
                                         showLoginAlert = true
                                     } else {
                                         Task {
                                             guard let urbexID = urbex.id, let userID = authViewModel.currentUser?.id else { return }
                                             await firestoreService.toggleActiveStatus(for: urbexID, userID: userID)
                                             await updateUrbexData()
                                             hasMarkedActive.toggle()
                                             if hasMarkedActive { hasMarkedInactive = false }
                                         }
                                     }
                                 }) {
                                     VStack {
                                         Image(systemName: hasMarkedActive ? "checkmark.circle.fill" : "checkmark.circle")
                                             .font(.title2)
                                             .foregroundColor(hasMarkedActive ? .green : .white)
                                         Text("\(urbex.activeVotes.count)")
                                             .font(.caption)
                                             .monospacedDigit()
                                         Text("Active")
                                             .font(.caption)
                                             .foregroundColor(.white.opacity(0.8))
                                     }
                                 }
                                 
                                 Rectangle()
                                     .fill(Color.white.opacity(0.3))
                                     .frame(width: 1, height: 30)
                                 
                                 Button(action: {
                                     if authViewModel.currentUser?.isGuest ?? false {
                                         loginAlertMessage = "You need to be signed in to mark urbex status"
                                         showLoginAlert = true
                                     } else {
                                         Task {
                                             guard let urbexID = urbex.id, let userID = authViewModel.currentUser?.id else { return }
                                             await firestoreService.toggleInactiveStatus(for: urbexID, userID: userID)
                                             await updateUrbexData()
                                             hasMarkedInactive.toggle()
                                             if hasMarkedInactive { hasMarkedActive = false }
                                         }
                                     }
                                 }) {
                                     VStack {
                                         Image(systemName: hasMarkedInactive ? "xmark.circle.fill" : "xmark.circle")
                                             .font(.title2)
                                             .foregroundColor(hasMarkedInactive ? .red : .white)
                                         Text("\(urbex.inactiveVotes.count)")
                                             .font(.caption)
                                             .monospacedDigit()
                                         Text("Inactive")
                                             .font(.caption)
                                             .foregroundColor(.white.opacity(0.8))
                                     }
                                 }
                             }
                             
                             VStack(spacing: 5) {
                                 ZStack(alignment: .leading) {
                                     Rectangle()
                                         .frame(width: 250, height: 10)
                                         .foregroundColor(.red)
                                         .clipShape(RoundedRectangle(cornerRadius: 5))
                                     
                                     Rectangle()
                                         .frame(width: 250 * activePercentage, height: 10)
                                         .foregroundColor(.green)
                                         .clipShape(RoundedRectangle(cornerRadius: 5))
                                         .animation(.easeInOut, value: activePercentage)
                                 }
                                 
                                 Text("\(Int(activePercentage * 100))% consider this location active")
                                     .font(.caption)
                                     .foregroundColor(.white.opacity(0.8))
                             }
                         }
                         .padding()
                         .frame(maxWidth: .infinity)
                         .background(
                             RoundedRectangle(cornerRadius: 7)
                                 .fill(Color.greyish)
                         )
                         .overlay(
                             RoundedRectangle(cornerRadius: 7)
                                 .stroke(.white.opacity(0.7), lineWidth: 1)
                         )
                         .padding(.horizontal)
                    
                    
                    
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details:")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        DetailRow(icon: "person.fill", title: "Added by", value: urbex.addedBy)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        DetailRow(icon: "calendar", title: "Added on", value: formattedDate(urbex.addedDate))
                        
                        
                        DetailRow(icon: "building.2.fill", title: "City", value: urbex.city)
                            .minimumScaleFactor(0.6)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "globe.europe.africa.fill")
                                .frame(width: 24)
                            Text("Country:")
                                .foregroundColor(.white.opacity(0.7))
                            if let country = Country.allCases.first(where: { $0.rawValue.uppercased() == urbex.country }) {
                                Text(country.displayName)
                                Text(country.flag)
                            } else {
                                Text(urbex.country)
                            }
                            Spacer()
                        }
                        
                        Button(action: {
                            if let url = URL(string: "https://www.google.com/maps?q=\(urbex.latitude),\(urbex.longitude)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.and.ellipse")
                                    .frame(width: 24)
                                Text("Coordinates:")
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(String(format: "%.7f", urbex.latitude)), \(String(format: "%.7f", urbex.longitude))")
                                    .foregroundColor(.blue)
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.greyish)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(.white.opacity(0.7), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description:")
                            .font(.headline)
                            .padding(.bottom, 2)
                        
                        Text(urbex.description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.vertical, 4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.greyish)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(.white.opacity(0.7), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .scrollIndicators(.hidden)
        }
        .alert("Sign In Required", isPresented: $showLoginAlert) {
            Button("Sign In", role: .none) {
                authViewModel.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(loginAlertMessage)
        }
        .alert("Thank you!", isPresented: $showReportSuccessAlert, actions: {
                   Button("OK", role: .cancel) { }
               }, message: {
                   Text("Your report has been successfully submitted. We appreciate your help in keeping the community safe.")
               })
        .alert("Already Reported", isPresented: $showAlreadyReportedAlert, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text("You have already reported this urbex. It is currently under review.")
        })
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onAppear {
            isFavorite = authViewModel.currentUser?.favoriteUrbexes.contains(urbex.id ?? "") ?? false
            if let userID = authViewModel.currentUser?.id {
                hasLiked = urbex.likes.contains(userID)
                hasDisliked = urbex.dislikes.contains(userID)
                hasMarkedActive = urbex.activeVotes.contains(userID)
                hasMarkedInactive = urbex.inactiveVotes.contains(userID)
            }
            
            fetchAddedByUserDetails()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showReportSheet = true
                }) {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.white)
                    Text("Report")
                        .foregroundStyle(.white)
                }
                .actionSheet(isPresented: $showReportSheet) {
                    ActionSheet(
                        title: Text("Report Urbex"),
                        message: Text("Select a reason for reporting this urbex"),
                        buttons: [
                            .default(Text("Inappropriate Content")) { reportUrbex(reason: "Inappropriate Content") },
                            .default(Text("Violence or Harmful Activities")) { reportUrbex(reason: "Violence or Harmful Activities") },
                            .default(Text("Hate Speech or Racism")) { reportUrbex(reason: "Hate Speech or Racism") },
                            .default(Text("Nudity or Sexual Content")) { reportUrbex(reason: "Nudity or Sexual Content") },
                            .default(Text("Other")) { reportUrbex(reason: "Other") },
                            .cancel()
                        ]
                    )
                }
            }
        }
    }
    
    private func DetailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .frame(width: 24)
            Text(title + ":")
                .foregroundColor(.white.opacity(0.7))
            
         
            if title == "Added by" && isAddedByAdmin {
                Text(addedByUsername.isEmpty ? value : addedByUsername)
                    .foregroundColor(.purple)
                
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.purple)
            } else {
                Text(value)
            }
        }
    }
    
    
    private func formattedDate(_ timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func updateUrbexData() async {
        guard let urbexID = urbex.id else { return }
        if let updatedUrbex = await firestoreService.fetchUrbexByID(urbexID) {
            urbex = updatedUrbex
        }
    }

    private func makeGoogleMapsURL(latitude: Double, longitude: Double) -> URL {
        let urlString = "https://www.google.com/maps?q=\(latitude),\(longitude)"
        return URL(string: urlString)!
    }
    
    
    private func fetchAddedByUserDetails() {
        let db = Firestore.firestore()
      
        db.collection("users")
            .whereField("username", isEqualTo: urbex.addedBy)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching user details: \(error.localizedDescription)")
                    return
                }
                
                if let userDoc = snapshot?.documents.first {
                    if let isAdmin = userDoc.data()["isAdmin"] as? Bool {
                        self.isAddedByAdmin = isAdmin
                    }
                    
                    if let username = userDoc.data()["username"] as? String {
                        self.addedByUsername = username
                    }
                }
            }
    }
    

    private func reportUrbex(reason: String) {
        guard let urbexID = urbex.id else { return }
        
        
        let reporterID = authViewModel.currentUser?.isGuest ?? false
            ? "guest_" + DeviceIdentifier.getDeviceIdentifier()
            : authViewModel.currentUser?.id ?? ""
        
        Firestore.firestore().collection("reports")
            .whereField("urbexID", isEqualTo: urbexID)
            .whereField("reportedBy", isEqualTo: reporterID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking report: \(error.localizedDescription)")
                    return
                }

                if let documents = snapshot?.documents, !documents.isEmpty {
                    showAlreadyReportedAlert = true
                    return
                }

                let reportData: [String: Any] = [
                    "urbexID": urbexID,
                    "reportedBy": reporterID,
                    "reason": reason,
                    "timestamp": Timestamp(),
                    "isGuestReport": authViewModel.currentUser?.isGuest ?? false
                ]

                Firestore.firestore().collection("reports").addDocument(data: reportData) { error in
                    if let error = error {
                        print("Error reporting urbex: \(error.localizedDescription)")
                    } else {
                        hasReported = true
                        showReportSuccessAlert = true
                        print("Urbex reported successfully.")
                    }
                }
            }
    }
}
