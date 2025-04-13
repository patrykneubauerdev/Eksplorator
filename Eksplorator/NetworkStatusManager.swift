//
//  NetworkStatusManager.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 23/03/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.


import Network
import SwiftUI

class NetworkStatusManager: ObservableObject {
    @Published var isConnected = true
    private let monitor = NWPathMonitor()
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

struct NetworkStatusBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
                .foregroundColor(.black)
            Text("No internet connection")
                .foregroundColor(.black)
            Text("• Some features may be limited")
                .foregroundColor(.black.opacity(0.7))
        }
        .font(.footnote)
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
}
