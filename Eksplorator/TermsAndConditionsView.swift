//
//  TermsAndConditionsView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 30/03/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import SwiftUI

struct TermsAndConditionsView: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showPrivacyPolicy = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                    .frame(height: 40)
                Text("Terms and Conditions")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                Group {
                    Text("1. Acceptance of Terms")
                        .font(.headline)
                    
                    Text("By accessing and using this application, you agree to be bound by these Terms and Conditions, all applicable laws and regulations, and agree that you are responsible for compliance with any applicable local laws.")
                    
                    Text("2. User Accounts")
                        .font(.headline)
                    
                    Text("Users are responsible for maintaining the confidentiality of their account information, including password. You are responsible for all activities that occur under your account.")
                    
                    Text("3. User Conduct")
                        .font(.headline)
                    
                    Text("Users agree not to use the service for any unlawful purpose or in any way that could damage, disable, overburden, or impair the service.")
                    
                    Text("4. Privacy Policy")
                        .font(.headline)
                    
                    Text("Your use of this application is also governed by our: ")
                    Text("Privacy Policy")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            showPrivacyPolicy = true
                        }
                    Text("which is incorporated into these Terms by this reference.")
                }
                
                Group {
                    
                    Text("5. Prohibited Content")
                        .font(.headline)

                    Text("Users are strictly prohibited from posting any content that includes:")
                    Text("""
                    - Profanity, obscene, or sexually explicit language.
                    - Hate speech, racism, discrimination, or any content promoting violence.
                    - False, misleading, or defamatory statements.
                    - Any content that violates applicable laws or infringes on the rights of others.
                    """)
                        
                    Text("Failure to comply with these guidelines may result in immediate removal of the content and suspension or termination of your account, at our sole discretion.")
                    
                    Text("6. Termination")
                        .font(.headline)
                    
                    Text("We reserve the right to terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.")
                    
                    Text("7. Changes to Terms")
                        .font(.headline)
                    
                    Text("We reserve the right, at our sole discretion, to modify or replace these Terms at any time. By continuing to access or use our application after any revisions become effective, you agree to be bound by the revised terms.")
                    
                    Text("8. Internet Connection Requirement")
                        .font(.headline)
                    
                    Text("Important: This application requires an active internet connection to function properly. Features such as authentication, data synchronization, and content loading will not work without internet access.")
                        .font(.headline)
                    
                    Text("9. Intellectual Property")
                        .font(.headline)
                    
                    Text("This application, including its concept, structure, and implementation, is the intellectual property of Patryk Neubauer. Unauthorized replication, modification, or distribution of this software, in whole or in part, is strictly prohibited.")
                    
                    Text("Eksplorator is a UGC-based application, and while user-generated content remains the property of its respective creators, the framework, design logic, and core functionality of the application are protected under applicable copyright and intellectual property laws.")
                    
                    Text("Any attempt to reverse engineer, duplicate, or exploit this application without prior written consent may result in legal action.")
                }
                
                Text("By using this application, you acknowledge that you have read and understand these Terms and Conditions and agree to be bound by them.")
                    .fontWeight(.medium)
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Eksplorator – © 2025 Patryk Neubauer. All rights reserved.")
                        .font(.headline)
                        .padding(.top, 30)
                    
                    Text("For inquiries, please contact: patrykneubauerdev@gmail.com")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .background(Color(.semiDark))
        .scrollIndicators(.hidden)
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
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
                   }
        
    }
}


#Preview {
    TermsAndConditionsView(isPresented: .constant(true))
}
