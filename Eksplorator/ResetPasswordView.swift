//
//  ResetPasswordView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 02/02/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import SwiftUI


extension ResetPasswordView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !email.isEmpty && email.isValidEmail
    }
}

struct ResetPasswordView: View {
    
    @State private var email = ""
    @State private var message: String?
    @State private var isSuccess = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            Color(.semiDark)
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
            VStack {
                
                Spacer()
                Text("Reset Password")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .opacity(0.7)
                    .shadow(radius: 5)
                    .padding(.bottom, 7)
                
                InputView(text: $email,
                          title: "Email Address",
                          placeholder: "Enter your email")
                .textInputAutocapitalization(.never)
                .padding()
                
                if let message = message {
                    Text(message)
                        .font(.system(size: 14))
                        .foregroundStyle(isSuccess ? .green : .red)
                        .padding(.top, 10)
                        .multilineTextAlignment(.center)
                }
                
                Button {
                    Task {
                        do {
                            try await viewModel.resetPassword(email: email)
                            message = "If this email is registered, a reset link has been sent. Please check your inbox and spam folder."
                            isSuccess = true
                            dismiss()
                        } catch {
                            message = "Please make sure the email is correctly formatted and try again."
                            isSuccess = false
                        }
                    }
                } label: {
                    Text("Send Reset Link")
                        .fontWeight(.semibold)
                        .frame(width: 320, height: 50)
                        .background(.white)
                        .foregroundColor(.black)
                        .clipShape(.buttonBorder)
                }
                .disabled(!formIsValid)
                .opacity(formIsValid ? 1.0 : 0.5)
                .padding(.top, 20)
                Spacer()
                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(false)
    }
    
    private func hideKeyboard() {
           UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
       }
}

#Preview {
    ResetPasswordView()
}
