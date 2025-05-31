//
//  RegistrationView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 30/01/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import SwiftUI
import RegexBuilder

struct RegistrationView: View {
    
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var showAlert = false
    @State private var showUsernameRules = false
    @State private var acceptedTerms = false
    @State private var showTermsSheet = false
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    
    @FocusState private var focusedField: Field?

    enum Field {
        case email, username, password, confirmPassword
    }
    
    struct PasswordRequirement: Identifiable {
        let id = UUID()
        let text: String
        let systemImage: String
        let condition: (String) -> Bool
    }
    
    
    private var passwordRequirements: [PasswordRequirement] {
        [
            PasswordRequirement(text: "At least 12 characters", systemImage: "character") { $0.count >= 12 },
            PasswordRequirement(text: "At least one uppercase letter", systemImage: "textformat.abc.dottedunderline") { $0.contains(where: { $0.isUppercase }) },
            PasswordRequirement(text: "At least one special character", systemImage: "number") { $0.contains(where: { "$@$!%*?&#".contains($0) }) }
        ]
    }
    
    var body: some View {
        ZStack {
            Color(.semiDark)
                .ignoresSafeArea()
            VStack {
                Spacer()
                    .frame(height: 125)
                
                Text("Create account:")
                    .frame(width: 300, height: 50)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .opacity(0.7)
                    .shadow(radius: 5)
                    .padding(.bottom, 20)
                
                
                
                
                VStack(spacing: 22) {
                    InputView(
                        text: $email,
                        title: "Email Address",
                        placeholder: "Enter your email address",
                        submitLabel: .next
                    ) {
                        focusedField = .username
                    }
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .email)
                    .onChange(of: email) { _, newValue in
                        if newValue.count > 40 {
                            email = String(newValue.prefix(40))
                        }
                    }

                    
                    ZStack(alignment: .trailing) {
                        InputView(
                             text: $username,
                             title: "Username",
                             placeholder: "Enter your username",
                             submitLabel: .next
                         ) {
                             focusedField = .password
                         }
                         .textInputAutocapitalization(.never)
                         .focused($focusedField, equals: .username)
                         .onChange(of: username) { _, newValue in
                             if newValue.count > 18 {
                                 username = String(newValue.prefix(18))
                             }
                         }
                        
                        Button(action: {
                            showUsernameRules = true
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.white)
                                .opacity(0.8)
                                .imageScale(.large)
                                .fontWeight(.bold)
                        }
                        .padding(.trailing, 10)
                        .alert("Username Policy", isPresented: $showUsernameRules) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text("Using inappropriate, offensive, or racist usernames is strictly prohibited. Violations may result in a permanent account ban.")
                        }
                    }
                    
                    InputView(
                        text: $password,
                        title: "Password",
                        placeholder: "Enter your password",
                        isSecureField: true,
                        submitLabel: .next
                    ) {
                        focusedField = .confirmPassword
                    }
                    .focused($focusedField, equals: .password)
                    
                    
                    HStack(spacing: 4) {
                        ForEach(passwordRequirements) { requirement in
                            HStack(spacing: 4) {
                                Image(systemName: requirement.condition(password) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(requirement.condition(password) ? .white : .gray)
                                Text(requirement.text)
                                    .font(.caption)
                                    .minimumScaleFactor(0.3)
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                    .foregroundStyle(requirement.condition(password) ? .white : .gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    
                    ZStack(alignment: .trailing) {
                        InputView(
                            text: $confirmPassword,
                            title: "Confirm Password",
                            placeholder: "Confirm your password",
                            isSecureField: true,
                            submitLabel: .done
                        ) {
                            focusedField = nil
                        }
                        .focused($focusedField, equals: .confirmPassword)
                        
                        if !password.isEmpty && !confirmPassword.isEmpty {
                            Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(.white)
                                .imageScale(.large)
                                .fontWeight(.bold)
                                .padding(.horizontal, 10)
                        }
                    }
                    
                  
                    HStack(alignment: .center, spacing: 10) {
                        Button(action: {
                            acceptedTerms.toggle()
                        }) {
                            Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                                .foregroundStyle(.white)
                                .imageScale(.large)
                        }
                        
                        HStack(spacing: 3) {
                            Text("I accept the")
                                .foregroundStyle(.white)
                            
                            Button(action: {
                                showTermsSheet = true
                            }) {
                                Text("Terms and Conditions")
                                    .foregroundStyle(.blue)
                                    .underline()
                            }
                        }
                        .font(.system(size: 14))
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal)
                .padding(.top, 5)
                
                Button {
                    guard !isLoading else { return }
                    isLoading = true
                    focusedField = nil
                    
                    Task {
                        isUsernameAllowed(username: username) { isAllowed, message in
                            if isAllowed {
                                Task {
                                    do {
                                        let isUsernameTaken = try await viewModel.isUsernameTaken(username: username)
                                        
                                        if isUsernameTaken {
                                            errorMessage = "This username is already taken. Please choose another one."
                                            showAlert = true
                                            isLoading = false
                                        } else {
                                            try await viewModel.createUserWithDeviceLimit(withEmail: email, password: password, username: username)
                                          
                                        }
                                    } catch AuthViewModel.AuthError.deviceLimitReached {
                                        errorMessage = "Maximum number of accounts (3) has been reached for this device. Please use an existing account."
                                        showAlert = true
                                        isLoading = false
                                    } catch {
                                        errorMessage = "An unexpected error occurred. Please try again."
                                        showAlert = true
                                        isLoading = false
                                    }
                                }
                            } else {
                                errorMessage = message
                                showAlert = true
                                isLoading = false
                            }
                        }
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .padding(.trailing, 10)
                        }
                        
                        Text(isLoading ? "SIGNING UP..." : "SIGN UP")
                            .fontWeight(.semibold)
                        
                        if !isLoading {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .foregroundStyle(.black)
                    .frame(width: 320, height: 50)
                }
                .alert("Registration Error", isPresented: $showAlert, presenting: errorMessage) { _ in
                    Button("OK", role: .cancel) {}
                } message: { error in
                    Text(error)
                }
                .background(.white)
                .disabled(!formIsValid || isLoading)
                .opacity((formIsValid && !isLoading) ? 1.0 : (isLoading ? 0.8 : 0.5))
                .clipShape(.buttonBorder)
                .padding(.top, 25)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 3) {
                        Text("Already have an account?")
                        Text("Sign in")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 14))
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showTermsSheet) {
            TermsAndConditionsView(isPresented: $showTermsSheet)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }
}

// MARK: - AuthenticationFormProtocol
extension RegistrationView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !email.isEmpty
        && email.isValidEmail
        && !password.isEmpty
        && passwordRequirements.allSatisfy { $0.condition(password) }
        && confirmPassword == password
        && !username.isEmpty
        && acceptedTerms
    }
}

#Preview {
    RegistrationView()
}
