//
//  AddUrbexView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 28/02/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import SwiftUI

struct AddUrbexView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var firestoreService = FirestoreService(autoFetchUrbexes: false)
    @Binding var selectedTab: NavigationTabs
    
   
    @State private var selectedUrbex: Urbex?
    @State private var isActive: Bool = false
    @State private var shouldReload = false
    @State private var imageLoadTriggers: [String: UUID] = [:]
    @State private var showDeleteAlert = false
    @State private var urbexToDelete: Urbex?
    @State private var hasLoadedInitialData = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle()
                    .foregroundStyle(.semiDark)
                    .ignoresSafeArea()
                
                if firestoreService.isLoading {
                    ProgressView("Loading Your Urbexes")
                        .font(.system(size: 10))
                        .progressViewStyle(.circular)
                        .scaleEffect(1.2)
                        .foregroundStyle(.white.opacity(0.7))
                        .tint(.white.opacity(0.7))
                } else if firestoreService.urbexes.isEmpty {
                    VStack(spacing: 10) {
                        Text("You haven't added any urbexes on this account yet.")
                            .foregroundStyle(.gray)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        VStack {
                            HStack(spacing: 0) {
                                Text("Tap the ")
                                    .foregroundStyle(.gray)
                                    .font(.headline)
                                Text("Add New Urbex")
                                    .fontWeight(.heavy)
                                    .foregroundStyle(.white)
                                    .opacity(0.7)
                                    .font(.headline)
                                Text(" button below")
                                    .foregroundStyle(.gray)
                                    .font(.headline)
                            }
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            
                            Text("to add your first urbex!")
                                .foregroundStyle(.gray)
                                .font(.headline)
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    
                    List(firestoreService.urbexes) { urbex in
                        
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
                                        .minimumScaleFactor(0.8)
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
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                     
                                        if authViewModel.currentUser?.favoriteUrbexes.contains(urbex.id ?? "") ?? false {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(.red)
                                                .frame(width: 20, height: 20)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                        }
                                        
                                      
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
                                        Button(role: .destructive) {
                                            urbexToDelete = urbex
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                
                                
                               
                            }
                    .listStyle(.grouped)
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await firestoreService.fetchUrbexesForUser()
                    }
                }
                
                VStack {
                    Spacer()
                    NavigationLink {
                        AddUrbexDetailsView()
                            .onDisappear {
                                Task {
                                    for _ in 1...3 {
                                        await firestoreService.fetchUrbexesForUser()
                                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                                    }
                                }
                            }
                    } label: {
                        Label("Add New Urbex", systemImage: "plus.circle")
                            .fontWeight(.semibold)
                            .frame(width: 250, height: 50)
                            .background(.white)
                            .foregroundStyle(.black)
                            .clipShape(.buttonBorder)
                            
                    }
                    .padding(.bottom, 20)
                }
                
            }
            .navigationTitle("My Urbexes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.darkest, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                if !hasLoadedInitialData {
                    await firestoreService.fetchUrbexesForUser()
                    hasLoadedInitialData = true
                }
            }
            .alert("Delete Urbex", isPresented: $showDeleteAlert) {
                     Button("Cancel", role: .cancel) {}
                     Button("Delete", role: .destructive) {
                         if let urbex = urbexToDelete {
                             Task {
                                 await firestoreService.deleteUrbex(urbex)
                                 await firestoreService.fetchUrbexesForUser()
                             }
                         }
                     }
                 } message: {
                     Text("Are you sure you want to delete this urbex? This action cannot be undone.")
                 }
            
          
            .navigationDestination(isPresented: $isActive) {
                if let selectedUrbex = selectedUrbex {
                    UrbexDetailsView(urbex: selectedUrbex)
                }
            }
        }
      
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue != .addUrbex {
                isActive = false 
            }
        }
    }
}
