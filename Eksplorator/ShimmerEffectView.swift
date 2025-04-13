//
//  ShimmerEffectView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 08/02/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import SwiftUI

struct ShimmerEffectView: View {
    @State private var isAnimating = false
 
    var body: some View {
        ZStack {
          
           
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
          
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.2),
                            Color.white.opacity(0.5),
                            Color.gray.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .mask(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .clear,
                                    .white.opacity(0.8),
                                    .clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: isAnimating ? 400 : -200)
                )
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        isAnimating = true
                    }
                }
            
           
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) 
        
    }
}
#Preview {
    ShimmerEffectView()
}
