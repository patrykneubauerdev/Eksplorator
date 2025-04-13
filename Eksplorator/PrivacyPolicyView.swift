//
//  PrivacyPolicyView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 30/03/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Eksplorator – Privacy Policy")
                        .font(.title)
                        .padding(.top, 74)
                    
                    Text("Eksplorator app stores the following user data:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("• Email address")
                        Text("• Password (securely encrypted)")
                        Text("• User ID")
                    }
                    .padding(.leading)
                    .foregroundStyle(.white.opacity(0.8))
                    
                    Text("When users add urbex locations, the following data is stored:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("• Urbex name (provided by the user)")
                        Text("• Urbex description (provided by the user)")
                        Text("• City of urbex location (provided by the user)")
                        Text("• Photo of the urbex (uploaded by the user)")
                    }
                    .padding(.leading)
                    .foregroundStyle(.white.opacity(0.8))
                    
                    Text("All urbex locations added by users remain permanently in the database, even if the user account is deleted. We do not share this data with third parties.")
                    
                    Text("Your data is securely stored using Firebase and Google Cloud services. If you wish to delete your account, you can do so in the app settings. However, urbex locations you added will remain visible in the app.")
                    
                  
                    Text("Prohibited Content & Policy Enforcement")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    Text("""
Users are strictly prohibited from posting content that includes:
- Profanity, obscene, or sexually explicit language.
- Hate speech, racism, discrimination, or any content promoting violence.
- False, misleading, or defamatory statements.
- Any content that violates applicable laws or infringes on the rights of others.

We reserve the right to remove any inappropriate content without prior notice. Repeated violations may result in account suspension or termination.
""")
                    
                    Text("For any inquiries, contact: patrykneubauerdev@gmail.com")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding()
                .foregroundColor(.white)
            }
            .scrollIndicators(.hidden)
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
        .presentationBackground(Color(.semiDark))
    }
}

#Preview {
    PrivacyPolicyView()
}
