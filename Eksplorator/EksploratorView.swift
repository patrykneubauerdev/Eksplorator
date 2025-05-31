//
//  EksploratorView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 18/01/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.



import SwiftUI


enum NavigationTabs: Hashable {
    case urbexes, favorites, addUrbex, profile
}

struct EksploratorView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var selectedTab: NavigationTabs = .urbexes
    
    var body: some View {
        if viewModel.userSession != nil || viewModel.isGuestMode {
            TabView(selection: $selectedTab) {
                Tab("Urbexes", systemImage: "house.fill", value: .urbexes) {
                    UrbexesView(selectedTab: $selectedTab)
                        .toolbarBackground(.darkest, for: .tabBar)
                        .toolbarBackground(.visible, for: .tabBar)
                }
                
                Tab("Favorites", systemImage: "heart.square.fill", value: .favorites) {
                    FavoritesView(selectedTab: $selectedTab)
                        .toolbarBackground(.darkest, for: .tabBar)
                        .toolbarBackground(.visible, for: .tabBar)
                }
                
                Tab("Add Urbex", systemImage: "plus.circle.fill", value: .addUrbex) {
                    AddUrbexView(selectedTab: $selectedTab)
                        .toolbarBackground(.darkest, for: .tabBar)
                        .toolbarBackground(.visible, for: .tabBar)
                }
                
                Tab("Profile", systemImage: "person.fill", value: .profile) {
                    ProfileView()
                        .toolbarBackground(.darkest, for: .tabBar)
                        .toolbarBackground(.visible, for: .tabBar)
                        .environmentObject(viewModel)
                }
            }
            
            
            .onAppear {
                viewModel.verifyUserExists()
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                viewModel.verifyUserExists()
            }
            
            
        } else {
            LoginView()
                .environmentObject(viewModel)
        }
    }
}

#Preview {
    EksploratorView()
        .environmentObject(AuthViewModel())
}
