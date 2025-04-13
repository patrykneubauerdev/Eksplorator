//
//  SettingsRowView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 30/01/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import SwiftUI


struct SettingsRowView: View {
    
    let imageName: String
    let title: String
    let tintColor: Color
    
    var body: some View {
        
        
        
        HStack(spacing: 12) {
            
            Image(systemName: imageName)
                .imageScale(.small)
                .font(.title)
                .foregroundStyle(tintColor)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
        .preferredColorScheme(.dark)
        
  
        
        
    }
}

#Preview {
    SettingsRowView(imageName: "gear", title: "Version", tintColor: .gray)
}
