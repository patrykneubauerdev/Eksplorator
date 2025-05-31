//
//  FavoritesView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 24/01/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var firestoreService = FirestoreService()
    @Binding var selectedTab: NavigationTabs
    
    
    @State private var selectedUrbex: Urbex?
    @State private var isActive: Bool = false
    @State private var imageLoadTriggers: [String: UUID] = [:]
    
    var favoriteUrbexes: [Urbex] {
        firestoreService.urbexes.filter { urbex in
            authViewModel.currentUser?.favoriteUrbexes.contains(urbex.id ?? "") ?? false
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle()
                    .foregroundStyle(.semiDark)
                    .ignoresSafeArea()
                
                if authViewModel.currentUser?.isGuest ?? false {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                            .padding(.bottom, 20)
                        
                        Text("Sign In Required")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("You need to be signed in to add and view your favorite urbex locations")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.gray)
                        
                        Button {
                            authViewModel.signOut()
                        } label: {
                            HStack {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            .foregroundStyle(.black)
                            .frame(width: 250, height: 50)
                            .background(.white)
                            .clipShape(.buttonBorder)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                } else {
                    if firestoreService.isLoading {
                        ProgressView("Loading Favorite Urbexes")
                            .font(.system(size: 10))
                            .progressViewStyle(.circular)
                            .scaleEffect(1.2)
                            .foregroundStyle(.white.opacity(0.7))
                            .tint(.white.opacity(0.7))
                    } else if favoriteUrbexes.isEmpty {
                        Label("No urbex added to Favorites yet", systemImage: "heart.slash.fill")
                            .foregroundColor(.gray)
                            .font(.headline)
                    } else {
                        List(favoriteUrbexes) { urbex in
                            
                            Button {
                                selectedUrbex = urbex
                                isActive = true
                            } label: {
                                HStack(spacing: 16) {
                                    AsyncImage(url: URL(string: urbex.imageURL)) { phase in
                                        switch phase {
                                          
                                        case .empty:
                                            ShimmerEffectView()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 7)
                                                        .stroke(.white.opacity(0.7), lineWidth: 1)
                                                )
                                        
                                        case .success(let image):
                                            image.resizable()
                                                .scaledToFill()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 7)
                                                        .stroke(.white.opacity(0.7), lineWidth: 1)
                                                )
                                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                                .animation(.spring(duration: 0.5), value: image)
                                        
                                        case .failure(_):
                                            ShimmerEffectView()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 7)
                                                        .stroke(.white.opacity(0.7), lineWidth: 1)
                                                )
                                                .onAppear {
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                        imageLoadTriggers[urbex.imageURL] = UUID()
                                                    }
                                                }
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .id(imageLoadTriggers[urbex.imageURL])
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(urbex.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .minimumScaleFactor(0.6)
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        HStack(alignment: .center, spacing: 4) {
                                         
                                            HStack(spacing: 4) {
                                                Image(systemName: "building.2")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.gray)
                                                Text(urbex.city)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                         
                                            if let country = Country.allCases.first(where: { $0.rawValue.uppercased() == urbex.country }) {
                                                Text(country.flag)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.white)
                                                    .frame(width: 20, height: 20)
                                                    .background(Color.black.opacity(0.6))
                                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                            }
                                            
                                         
                                            ZStack {
                                                Image(systemName: "hand.thumbsup.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white)
                                                    .frame(width: 20, height: 20)
                                                    .background(Color.black.opacity(0.6))
                                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                                Text("\(urbex.likes.count)")
                                                    .font(.system(size: 6))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 2)
                                                    .padding(.vertical, 1)
                                                    .background(Color.green.opacity(0.8))
                                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                                                    .offset(x: 6, y: 6)
                                            }
                                            
                                       
                                            ZStack {
                                                Image(systemName: "hand.thumbsdown.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white)
                                                    .frame(width: 20, height: 20)
                                                    .background(Color.black.opacity(0.6))
                                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                                Text("\(urbex.dislikes.count)")
                                                    .font(.system(size: 6))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 2)
                                                    .padding(.vertical, 1)
                                                    .background(Color.red.opacity(0.8))
                                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                                                    .offset(x: 6, y: 6)
                                            }
                                            
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    
                                    
                                    Image(systemName: "chevron.left.2")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.gray.opacity(0.6))
                                        .frame(width: 25)
                                        .padding(.trailing, 2)
                                }
                            }
                            .listRowBackground(Color(.greyish))
                            .swipeActions(edge: .trailing) {
                                Button {
                                    if let urbexID = urbex.id {
                                        Task {
                                            await authViewModel.toggleFavoriteUrbex(urbexID: urbexID)
                                        }
                                    }
                                } label: {
                                    Label("Remove", systemImage: "heart.slash.fill")
                                }
                                .tint(.indigo)
                            }
                        }
                        .listStyle(.grouped)
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .refreshable {
                            await firestoreService.fetchUrbexes()
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.darkest, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(isPresented: $isActive) {
                if let selectedUrbex = selectedUrbex {
                    UrbexDetailsView(urbex: selectedUrbex)
                }
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .favorites {
                Task {
                    await firestoreService.fetchUrbexes()
                }
            } else {
                isActive = false
            }
        }
    }
}
