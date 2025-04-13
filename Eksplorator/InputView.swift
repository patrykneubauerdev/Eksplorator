//
//  InputView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 30/01/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.


import SwiftUI

struct InputView: View {
    
    @Binding var text: String
    let title: String
    let placeholder: String
    var isSecureField = false
    var submitLabel: SubmitLabel = .next
    var submitAction: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .foregroundStyle(.white)
                .fontWeight(.semibold)
                .font(.footnote)
            
            if isSecureField {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 14))
                    .submitLabel(submitLabel)
                    .onSubmit {
                        submitAction?()
                    }
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14))
                    .submitLabel(submitLabel)
                    .onSubmit {
                        submitAction?()
                    }
            }
            
            Divider()
        }
    }
}

#Preview {
    InputView(text: .constant(""), title: "Email Address", placeholder: "name@example.com")
}
