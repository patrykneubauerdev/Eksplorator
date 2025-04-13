//
//  ProfileView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 30/01/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.
import SwiftUI

struct ProfileView: View {
    
    @EnvironmentObject var viewModel: AuthViewModel
    
    @State private var showContactDeveloper = false
    @State private var showDeleteAlert = false
    @State private var showErrorAlert = false
    @State private var showSignOutAlert = false
    @State private var showPasswordAlert = false
    @State private var password = ""
    @State private var showTermsSheet = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var showPasswordChangeError = false
    @State private var showPasswordChangeSuccess = false
    @State private var isPasswordSectionExpanded = false
    @State private var showPrivacyPolicy = false
    
   
    
    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle()
                    .foregroundStyle(.semiDark)
                
                if let user = viewModel.currentUser {
                    VStack {
                        List {
                            Section {
                                HStack {
                                    Text(user.initials)
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .frame(width: 72, height: 72)
                                        .background(.gray)
                                        .clipShape(.circle)
                                        .padding(.trailing, 10)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(user.username)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .padding(.top, 4)
                                            .minimumScaleFactor(0.6)
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text(user.email)
                                            .font(.footnote)
                                            .foregroundStyle(.gray)
                                            .minimumScaleFactor(0.6)
                                            .lineLimit(2)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                            .listRowBackground(Color(.greyish))
                            
                            
                            
                            Section("Legal") {
                                
                                Button {
                                    showTermsSheet = true
                                } label: {
                                    Label("Terms & Conditions", systemImage: "questionmark.text.page")
                                }
                                Button {
                                    showPrivacyPolicy = true
                                } label: {
                                    Label("Privacy Policy", systemImage: "doc.text.magnifyingglass")
                                }
                                
                            }
                            .listRowBackground(Color(.greyish))
                            
                            
                            Section("Password & Security") {
                                Button {
                                    withAnimation {
                                        isPasswordSectionExpanded.toggle()
                                    }
                                } label: {
                                    HStack {
                                        Label("Change Password", systemImage: "lock")
                                        Spacer()
                                        Image(systemName: isPasswordSectionExpanded ? "chevron.up" : "chevron.down")
                                            .foregroundStyle(.white)
                                    }
                                }
                                
                                if isPasswordSectionExpanded {
                                    VStack(spacing: 10) {
                                        SecureField("Current Password", text: $currentPassword)
                                            .padding(7)
                                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 1))
                                        
                                        SecureField("New Password", text: $newPassword)
                                            .padding(7)
                                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 1))
                                            .padding([.top, .bottom])
                                        
                                        Button("Confirm Password Change") {
                                            Task {
                                                do {
                                                    try await viewModel.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
                                                    showPasswordChangeSuccess = true
                                                    currentPassword = ""
                                                    newPassword = ""
                                                    
                                                } catch {
                                                    showPasswordChangeError = true
                                                }
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.white)
                                        .foregroundStyle(.black)
                                        .fontWeight(.semibold)
                                        
                                        
                                        .alert("Password Changed", isPresented: $showPasswordChangeSuccess) {
                                            Button("OK", role: .cancel) {}
                                        } message: {
                                            Text("Your password has been successfully updated.")
                                        }
                                        .alert("Error", isPresented: $showPasswordChangeError) {
                                            Button("OK", role: .cancel) {}
                                        } message: {
                                            Text("Could not change the password. Please check your current password and try again.")
                                        }
                                    }
                                    .padding()
                                }
                            }
                            .listRowBackground(Color(.greyish))
                            
                            Section("Account") {
                                Button {
                                    showSignOutAlert = true
                                } label: {
                                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                        .foregroundStyle(.white)
                                    
                                }
                                .alert("Sign Out", isPresented: $showSignOutAlert) {
                                    Button("Sign Out", role: .destructive) {
                                        withAnimation {
                                            viewModel.signOut()
                                        }
                                    }
                                    Button("Cancel", role: .cancel) {}
                                } message: {
                                    Text("Are you sure you want to sign out?")
                                }
                                
                                Button {
                                    showDeleteAlert = true
                                } label: {
                                    Label("Delete Account", systemImage: "trash")
                                        .foregroundStyle(.white)
                                }
                                .alert("Delete Account", isPresented: $showDeleteAlert) {
                                    SecureField("Enter your password", text: $password)
                                    
                                    Button("Delete", role: .destructive) {
                                        Task {
                                            do {
                                                try await viewModel.reauthenticateAndDeleteUser(password: password)
                                                showDeleteAlert = false
                                            } catch {
                                                showDeleteAlert = false
                                                showErrorAlert = true
                                            }
                                        }
                                    }
                                    Button("Cancel", role: .cancel) {
                                        showDeleteAlert = false
                                    }
                                } message: {
                                    Text("Are you sure you want to delete your account? Your created urbexes will remain in the database even after deletion.")
                                }
                                .alert("Incorrect Password", isPresented: $showErrorAlert) {
                                    Button("OK", role: .cancel) {
                                        password = ""
                                    }
                                } message: {
                                    Text("The password you entered is incorrect. Please try again.")
                                }
                            }
                            .listRowBackground(Color(.greyish))
                            
                            Section("Support") {
                              
                                
                                Button {
                                    showContactDeveloper = true
                                } label: {
                                    Label("Contact Developer", systemImage: "headset.circle")
                                    
                                }
                            }
                            .listRowBackground(Color(.greyish))
                            
                            Section {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Text("Version 1.0.0.")
                                            .font(.footnote)
                                            .foregroundStyle(.gray)
                                        
                                        
                                    }
                                    HStack {
                                        Spacer()
                                        Text("© Eksplorator - 2025 Patryk Neubauer")
                                            .font(.footnote)
                                            .foregroundStyle(.gray)
                                    }
                                }
                            }
                            .listRowBackground(Color(.semiDark))
                            
                            
                        }
                        .scrollContentBackground(.hidden)
                        .listRowBackground(Color(.white))
                    }
                } else {
                    ProgressView("Loading Profile")
                        .font(.system(size: 10))
                        .progressViewStyle(.circular)
                        .scaleEffect(1.2)
                        .foregroundStyle(.white.opacity(0.7))
                        .tint(.white.opacity(0.7))
                }
                
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.darkest, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showTermsSheet) {
                TermsAndConditionsView(isPresented: $showTermsSheet)
            }
            .sheet(isPresented: $showContactDeveloper) {
                ContactDevView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            
            
        }
        .scrollIndicators(.hidden)
    }
    
}

#Preview {
    let authViewModel = AuthViewModel()
    authViewModel.currentUser = User.mockUser
    
    return ProfileView()
        .environmentObject(authViewModel)
}
