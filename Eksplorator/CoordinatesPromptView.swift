//
//  CoordinatesPromptView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 27/02/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import SwiftUI

struct CoordinatesPromptView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.semiDark
                .ignoresSafeArea()
            
            VStack(spacing: 3) {
                Text("Please enter the coordinates in the same format as shown in the example from Google Maps: (52.4250298 — Latitude, 20.8378622 — Longitude). Make sure to use a dot (.) as the decimal separator instead of a comma (,). ⚠️ If entered incorrectly, the coordinates will appear as zeros and will not work properly.")
                    .foregroundStyle(.white)
                    .frame(width: 350, height: 80)
                    .multilineTextAlignment(.center)
                    .font(.caption2)
                    .padding(.top, 60)
                
                VStack {
                    
                    Image(.coordinatesPrompt)
                        .resizable()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 345, height: 600)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.6), lineWidth: 1)
                        .frame(width: 345, height: 600)
                    
                }
            }
            
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                                   .padding(.trailing, 10)
                                   .padding(.top, 10)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    CoordinatesPromptView()
}
