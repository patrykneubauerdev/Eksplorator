//
//  UrbexesView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 24/01/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import SwiftUI

struct UrbexesView: View {
    @StateObject var firestoreService = FirestoreService()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var selectedTab: NavigationTabs
   
    @State private var selectedUrbex: Urbex?
    @State private var isActive: Bool = false
    @State private var imageLoadTriggers: [String: UUID] = [:]
    
  
    @State private var searchText = ""
    @State private var sortOption: SortOption = .newest
    @State private var isShowingFilterMenu = false
    
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest"
        case mostLikes = "Most likes"
        case mostDislikes = "Most dislikes"
        
        var systemImage: String {
            switch self {
            case .newest: return "calendar"
            case .mostLikes: return "hand.thumbsup.fill"
            case .mostDislikes: return "hand.thumbsdown.fill"
            }
        }
    }

    let columns = [
        GridItem(.fixed(170), spacing: 16),
        GridItem(.fixed(170), spacing: 16)
    ]
    
    // Filtered and sorted urbexes
    var filteredUrbexes: [Urbex] {
        let filtered = firestoreService.urbexes.filter { urbex in
            if searchText.isEmpty {
                return true
            } else {
                return urbex.name.localizedCaseInsensitiveContains(searchText) ||
                       urbex.city.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by selected option
        switch sortOption {
        case .newest:
            return filtered.sorted { $0.addedDate.dateValue() > $1.addedDate.dateValue() }
        case .mostLikes:
            return filtered.sorted { $0.likes.count > $1.likes.count }
        case .mostDislikes:
            return filtered.sorted { $0.dislikes.count > $1.dislikes.count }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle()
                    .foregroundStyle(.semiDark)
                    .ignoresSafeArea()
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                VStack(spacing: 0) {
                   
                    Spacer()
                        .frame(height: 10)
                    
                  
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("Search by name or city", text: $searchText)
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.search)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.greyish)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    
                   
                    VStack(spacing: 4) {
                        HStack {
                            Text("Sorting: \(sortOption.rawValue)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                        }
                        
                    
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                
                    if firestoreService.urbexes.isEmpty {
                        Spacer()
                        ProgressView("Loading urbexes")
                            .font(.system(size: 10))
                            .progressViewStyle(.circular)
                            .scaleEffect(1.2)
                            .foregroundStyle(.white.opacity(0.7))
                            .tint(.white.opacity(0.7))
                        Spacer()
                    } else if filteredUrbexes.isEmpty {
                        Spacer()
                        VStack {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.white.opacity(0.5))
                            Text("No urbexes found")
                                .foregroundColor(.white.opacity(0.7))
                            Text("Try changing your search criteria")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.top, 4)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(filteredUrbexes) { urbex in
                                    let isFavorite = authViewModel.currentUser?.favoriteUrbexes.contains(urbex.id ?? "") ?? false
                                  
                                    Button {
                                        selectedUrbex = urbex
                                        isActive = true
                                    } label: {
                                        VStack {
                                            ZStack(alignment: .topTrailing) {
                                                if let url = URL(string: urbex.imageURL) {
                                                    AsyncImage(url: url) { phase in
                                                        switch phase {
                                                        case .empty:
                                                            ShimmerEffectView()
                                                                .frame(width: 150, height: 150)
                                                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                                                .overlay(
                                                                    RoundedRectangle(cornerRadius: 7)
                                                                        .stroke(.white.opacity(0.7), lineWidth: 1)
                                                                )
                                                        case .success(let image):
                                                            image
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fill)
                                                                .frame(width: 150, height: 150)
                                                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                                                .clipped()
                                                                .overlay(
                                                                    RoundedRectangle(cornerRadius: 7)
                                                                        .stroke(.white.opacity(0.7), lineWidth: 1)
                                                                )
                                                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                                                .animation(.spring(duration: 0.5), value: image)
                                                        case .failure(_):
                                                            ShimmerEffectView()
                                                                .frame(width: 150, height: 150)
                                                                .clipShape(RoundedRectangle(cornerRadius: 7))
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
                                                    .padding(.top, 7)
                                                    .id(imageLoadTriggers[urbex.imageURL])
                                                }
                                                
                                                HStack(spacing: 4) {
                                                    if isFavorite {
                                                        Image(systemName: "heart.fill")
                                                            .font(.system(size: 12))
                                                            .foregroundColor(.red)
                                                            .frame(width: 26, height: 26)
                                                            .background(Color.black.opacity(0.6))
                                                            .clipShape(RoundedRectangle(cornerRadius: 7))
                                                    }
                                                    
                                                    if let country = Country.allCases.first(where: { $0.rawValue.uppercased() == urbex.country }) {
                                                        Text(country.flag)
                                                            .font(.system(size: 12))
                                                            .foregroundColor(.white)
                                                            .frame(width: 26, height: 26)
                                                            .background(Color.black.opacity(0.6))
                                                            .clipShape(RoundedRectangle(cornerRadius: 7))
                                                    }
                                          
                                                    ZStack {
                                                        Image(systemName: "hand.thumbsup.fill")
                                                            .font(.system(size: 12))
                                                            .foregroundColor(.white)
                                                            .frame(width: 26, height: 26)
                                                            .background(Color.black.opacity(0.6))
                                                            .clipShape(RoundedRectangle(cornerRadius: 7))
                                                        Text("\(urbex.likes.count)")
                                                            .font(.system(size: 7))
                                                            .minimumScaleFactor(0.5)
                                                            .lineLimit(1)
                                                            .foregroundColor(.white)
                                                            .padding(.horizontal, 2)
                                                            .padding(.vertical, 1)
                                                            .background(Color.green.opacity(0.8))
                                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                                            .offset(x: 8, y: 8)
                                                    }
                                                    
                                                    ZStack {
                                                        Image(systemName: "hand.thumbsdown.fill")
                                                            .font(.system(size: 12))
                                                            .foregroundColor(.white)
                                                            .frame(width: 26, height: 26)
                                                            .background(Color.black.opacity(0.6))
                                                            .clipShape(RoundedRectangle(cornerRadius: 7))
                                                        Text("\(urbex.dislikes.count)")
                                                            .font(.system(size: 7))
                                                            .minimumScaleFactor(0.5)
                                                            .lineLimit(1)
                                                            .foregroundColor(.white)
                                                            .padding(.horizontal, 2)
                                                            .padding(.vertical, 1)
                                                            .background(Color.red.opacity(0.8))
                                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                                            .offset(x: 8, y: 8)
                                                    }
                                                }
                                                .padding(.top, 10)
                                                .padding(.trailing, 3)
                                                
                                            }
                                            
                                            VStack {
                                                Text(urbex.name)
                                                    .font(.headline)
                                                    .foregroundStyle(.white)
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(2)
                                                    .frame(height: 40)
                                                    .minimumScaleFactor(0.8)
                                                    .padding(.horizontal, 8)
                                                
                                                Text(urbex.city)
                                                    .font(.caption)
                                                    .foregroundStyle(.white.opacity(0.7))
                                                    .padding(.horizontal, 8)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                Color.greyish
                                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                                            )
                                        }
                                        .frame(width: 170, height: 230)
                                        .background(
                                            Color.greyish
                                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 7)
                                                .stroke(.white.opacity(0.7), lineWidth: 1)
                                        )
                                    }
                                }
                                
                                if filteredUrbexes.count % 2 != 0 {
                                    Button {
                                        selectedTab = .addUrbex
                                    } label: {
                                        VStack {
                                            Image(systemName: "plus")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 30, height: 30)
                                                .foregroundStyle(.white.opacity(0.7))
                                            
                                            Text("Add your Urbex")
                                                .font(.headline)
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                        .frame(width: 170, height: 230)
                                        .background(Color.greyish)
                                        .clipShape(RoundedRectangle(cornerRadius: 7))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 7)
                                                .stroke(.white.opacity(0.7), lineWidth: 1, antialiased: true)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                        }
                        .refreshable {
                            await firestoreService.fetchUrbexes()
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .navigationTitle("Urbexes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.darkest, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .preferredColorScheme(.dark)
            .navigationDestination(isPresented: $isActive) {
                if let selectedUrbex = selectedUrbex {
                    UrbexDetailsView(urbex: selectedUrbex)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: {
                                sortOption = option
                            }) {
                                Label(option.rawValue, systemImage: option.systemImage)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await firestoreService.fetchUrbexes()
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue != .urbexes {
                isActive = false
            }
        }
    }
    private func hideKeyboard() {
           UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
       }
}

#Preview {
    UrbexesView(selectedTab: .constant(.urbexes))
        .environmentObject(AuthViewModel())
}
