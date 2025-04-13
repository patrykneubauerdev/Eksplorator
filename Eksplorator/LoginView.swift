//
//  LoginView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 30/01/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import SwiftUI
import RegexBuilder

struct LoginView: View {
    
    @State private var email = ""
    @State private var password = ""
    @State private var alertMessage: String?
    @State private var showAlert = false
    
    @EnvironmentObject var viewModel: AuthViewModel
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.semiDark)
                    .ignoresSafeArea()
                    .onTapGesture {
                               hideKeyboard()
                           }
                VStack {
                    Image(.example)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 120)
                        .padding(.vertical, 32)
                    
                    VStack(spacing: 24) {
                        InputView(
                            text: $email,
                            title: "Email Address",
                            placeholder: "Enter your email address",
                            submitLabel: .next
                        ) {
                            focusedField = .password
                        }
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .email)
                        
                        InputView(
                            text: $password,
                            title: "Password",
                            placeholder: "Enter your password",
                            isSecureField: true,
                            submitLabel: .done
                        ) {
                            focusedField = nil 
                        }
                        .focused($focusedField, equals: .password)
                        
                        HStack {
                            Spacer()
                            NavigationLink {
                                ResetPasswordView()
                            } label: {
                                Text("Forgot password?")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                                    .underline()
                            }
                        }
                        .padding(.trailing)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    Button {
                        Task {
                            do {
                                try await viewModel.signIn(withEmail: email, password: password)
                            } catch let error as AuthViewModel.AuthError {
                                alertMessage = error.localizedDescription
                                showAlert = true
                            }
                        }
                    } label: {
                        HStack {
                            Text("SIGN IN")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundStyle(.black)
                        .frame(width: 320, height: 50)
                    }
                    .background(.white)
                    .disabled(!formIsValid)
                    .opacity(formIsValid ? 1.0 : 0.5)
                    .clipShape(.buttonBorder)
                    .padding(.top, 25)
                    
                    Spacer()
                    
                    NavigationLink {
                        RegistrationView()
                            .navigationBarBackButtonHidden(true)
                    } label: {
                        HStack(spacing: 3) {
                            Text("Don't have an account?")
                            Text("Sign up")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Authentication Failed"),
                      message: Text(alertMessage ?? "An unknown error occurred. Please try again."),
                      dismissButton: .cancel(Text("OK")))
            }
        }
        .preferredColorScheme(.dark)
    }
    
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - AuthenticationFormProtocol
extension LoginView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !email.isEmpty
        && email.isValidEmail
        && !password.isEmpty
        && password.count > 11
    }
}

// MARK: - Walidacja Emaila
extension String {
    var isValidEmail: Bool {
        let emailRegex = "^(?!\\.)[A-Za-z0-9._%+-]+(?<=\\S)@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}
