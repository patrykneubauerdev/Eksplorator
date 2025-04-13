//
//  ContactDevView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 23/03/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import SwiftUI

struct ContactDevView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
           
            ScrollView {
                VStack(spacing: 20) {
                   
                    Spacer()
                        .frame(height: 220)
                    
                    Text("Have a question, suggestion, or found a bug? Feel free to contact me!")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    Link(destination: URL(string: "mailto:patrykneubauerdev@gmail.com")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Send Email")
                                .fontWeight(.semibold)
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .cornerRadius(10)
                    }
                    
                    Link(destination: URL(string: "https://t.me/patrykneubauer")!) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Telegram")
                                .fontWeight(.semibold)
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .background(Color(.semiDark))
            
          
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
            }
            .padding(.trailing, 10)
            .padding(.top, 10)
        }
        .background(Color(.semiDark))
    }
}

#Preview {
    ContactDevView()
}
