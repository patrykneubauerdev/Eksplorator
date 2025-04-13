//
//  EksploratorApp.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 18/01/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import SwiftUI
import Firebase

@main
struct EksploratorApp: App {
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var networkManager = NetworkStatusManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                EksploratorView()
                    .environmentObject(authViewModel)
                    .accentColor(.accent)
                    .preferredColorScheme(.dark)
               
                if !networkManager.isConnected {
                    VStack {
                        NetworkStatusBanner()
                        Spacer()
                    }
                    .animation(.easeInOut, value: networkManager.isConnected)
                }
            }
            .environmentObject(networkManager)
        }
    }
}
