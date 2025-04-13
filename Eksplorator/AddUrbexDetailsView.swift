//
//  AddUrbexView.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 28/01/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Photos

struct AddUrbexDetailsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var firestoreService: FirestoreService
    @Environment(\.dismiss) var dismiss
    
    
    private let perspectiveHandler = PerspectiveAPIHandler(apiKey: Secrets.shared.get("GOOGLE_CLOUD_API_KEY") ?? "")
    
    @State private var name = ""
    @State private var description = ""
    @State private var city = ""
    @State private var country: Country = .poland
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @State private var addedBy = Auth.auth().currentUser?.displayName ?? "Unknown"
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var isLoading = false
    @State private var textEditorHeight: CGFloat = 50
    @State private var showCoordPrompt = false
    @State private var showConfirmationAlert = false
    @State private var isAnalyzing = false
    @State private var analysisError: String? = nil
    @State private var isCheckingContent = false
    @State private var showContentWarningAlert = false
    @State private var contentWarningMessage = ""
    @State private var dailyLimitReached = false
    
    private let MAX_DAILY_URBEX_LIMIT = 5
    
    private var db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.semiDark)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Add Urbex:")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .opacity(0.7)
                            .shadow(radius: 5)
                            .padding(.bottom, 7)
                        
                        customTextField("Urbex Name", text: $name)
                        descriptionField()
                        customTextField("City", text: $city)
                        Menu {
                            Picker("Select Country", selection: $country) {
                                ForEach(Country.sortedByName, id: \.self) { country in
                                    Text(country.displayName)
                                        .tag(country)
                                }
                            }
                            .pickerStyle(.inline)
                        } label: {
                            HStack {
                                Text(country.flag)
                                    .font(.system(size: 20))
                                Text(country.displayName)
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                            )
                        }
                        HStack {
                            TextField("Latitude", text: $latitude)
                                .keyboardType(.numbersAndPunctuation)
                                .disableAutocorrection(true)
                                .onChange(of: latitude) {
                                    latitude = sanitizeCoordinateInput(latitude)
                                }
                                .frame(maxWidth: .infinity)

                            Text(",")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.7))

                            TextField("Longitude", text: $longitude)
                                .keyboardType(.numbersAndPunctuation)
                                .disableAutocorrection(true)
                                .onChange(of: longitude) {
                                    longitude = sanitizeCoordinateInput(longitude)
                                }
                                .frame(maxWidth: .infinity)

                            Button {
                                showCoordPrompt.toggle()
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                        )
                        .listRowBackground(Color.semiDark)
                        .scrollContentBackground(.hidden)
                        
                        Button {
                            requestPhotoLibraryAccess()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                                    .frame(height: 120)
                                    .background(Color.semiDark.opacity(0.3))
                                
                                VStack {
                                    if isAnalyzing {
                                        ProgressView("Analyzing image")
                                            .font(.system(size: 10))
                                            .progressViewStyle(.circular)
                                            .scaleEffect(1.2)
                                            .foregroundStyle(.white.opacity(0.7))
                                            .tint(.white.opacity(0.7))
                                            .frame(width: 100, height: 100)
                                        
                                    } else if let selectedImage = selectedImage {
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 7))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 7)
                                                    .stroke(.white.opacity(0.7), lineWidth: 1)
                                            )
                                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                            .animation(.spring(duration: 0.5), value: selectedImage)
                                    } else {
                                        
                                        VStack(spacing: 5) {
                                            Image(systemName: "photo.badge.plus")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 40, height: 40)
                                                .foregroundStyle(.white.opacity(0.7))
                                            
                                            Text("Select Image")
                                                .font(.subheadline)
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                    }
                                }
                                
                                if let error = analysisError {
                                    Text(error)
                                        .foregroundStyle(.red)
                                        .fontWeight(.semibold)
                                        .font(.footnote)
                                        .padding(.top, 90)
                                }
                            }
                        }
                        .disabled(isAnalyzing)
                        .listRowBackground(Color.clear)
                        .padding(.top, 5)
                        
                        
                        
                        Text("\(authViewModel.getTodayUrbexAdditionCount())/\(MAX_DAILY_URBEX_LIMIT) urbexes added today")
                            .font(.caption)
                            .foregroundStyle(authViewModel.getTodayUrbexAdditionCount() == MAX_DAILY_URBEX_LIMIT ? .red : .white.opacity(0.7))
                            .padding(.top, 5)
                        
                        Button {
                            validateContentAndProceed()
                        } label: {
                            HStack {
                                Text("Add Urbex")
                                    .fontWeight(.bold)
                                
                                if isCheckingContent {
                                    ProgressView()
                                        .tint(.black)
                                        .scaleEffect(0.8)
                                        .padding(.leading, 5)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white)
                            .opacity(isLoading || isCheckingContent || !isFormValid() ? 0.5 : 1.0)
                            .foregroundStyle(.black)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading || isCheckingContent || !isFormValid())
                        .listRowBackground(Color.clear)
                        .alert("Add Urbex", isPresented: $showConfirmationAlert) {
                            Button("Yes", role: .none) {
                                addUrbex()
                                dismiss()
                            }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("Are you sure you want to add this Urbex? Once added, you won't be able to edit its details.")
                        }
                        .alert("Inappropriate Content Detected", isPresented: $showContentWarningAlert) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text(contentWarningMessage)
                        }
                        .alert("Daily Limit Reached", isPresented: $dailyLimitReached) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text("You've already added \(MAX_DAILY_URBEX_LIMIT) urbexes today. Please try again tomorrow.")
                        }
                    }
                    .padding(35)
                    .scrollIndicators(.hidden)
                    .scrollContentBackground(.hidden)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.darkest, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePickerView(isPresented: $isImagePickerPresented, selectedImage: $selectedImage)
                .onDisappear {
                    if let image = selectedImage {
                        analyzeImage(image)
                    }
                }
        }
        .sheet(isPresented: $showCoordPrompt) {
            CoordinatesPromptView()
        }
        .preferredColorScheme(.dark)
    }
    
    
    private func validateContentAndProceed() {
        
        let todayCount = authViewModel.getTodayUrbexAdditionCount()
            if todayCount >= MAX_DAILY_URBEX_LIMIT {
                dailyLimitReached = true
                return
            }
        
        isCheckingContent = true
        
        
        perspectiveHandler.validateUGCContent(
            placeName: name,
            placeDescription: description,
            cityName: city,
            threshold: 0.7
        ) { result in
            DispatchQueue.main.async {
                isCheckingContent = false
                
                switch result {
                case .success(let validationResult):
                    if validationResult.isValid {
                        
                        showConfirmationAlert = true
                    } else {
                        
                        contentWarningMessage = "Remove inappropriate content to add Urbex:\n\n\(validationResult.description)"
                        showContentWarningAlert = true
                    }
                    
                case .failure(let error):
                    
                    contentWarningMessage = "An error occurred while checking the content: \(error.localizedDescription)"
                    showContentWarningAlert = true
                }
            }
        }
    }
    
    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        analysisError = nil
        
        GoogleVisionService().analyzeImage(image: image) { isSafe, error in
            DispatchQueue.main.async {
                isAnalyzing = false
                if !isSafe {
                    analysisError = error ?? "Image is not appropriate."
                    selectedImage = nil
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        analysisError = nil
                    }
                }
            }
        }
    }
    
    func sanitizeCoordinateInput(_ input: String) -> String {
        var result = input.replacingOccurrences(of: ",", with: ".") 

        let allowedCharacters = CharacterSet(charactersIn: "-.0123456789")
        result = result.filter { String($0).rangeOfCharacter(from: allowedCharacters) != nil }

       
        if result.contains("-") {
            let minusIndex = result.firstIndex(of: "-")!
            if minusIndex != result.startIndex {
                result.remove(at: minusIndex)
            }
        }

       
        let dotCount = result.filter { $0 == "." }.count
        if dotCount > 1 {
            if let lastDotIndex = result.lastIndex(of: ".") {
                result.remove(at: lastDotIndex)
            }
        }

      
        if result.count > 20 {
            result = String(result.prefix(20))
        }

        return result
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func descriptionField() -> some View {
        VStack(alignment: .leading, spacing: 5) {
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                    .background(Color.semiDark)
                
                if description.isEmpty {
                    Text("Enter description...")
                        .foregroundColor(.white.opacity(0.3))
                        .padding(15)
                }
                
                TextEditor(text: $description)
                    .padding(10)
                    .frame(minHeight: textEditorHeight, maxHeight: 200)
                    .foregroundStyle(.white)
                    .onChange(of: description) { _, newValue in
                        let newLineCount = newValue.components(separatedBy: "\n").count - 1
                        if newLineCount > 8 {
                            let lines = newValue.components(separatedBy: "\n")
                            description = lines.prefix(9).joined(separator: "\n")
                        }
                        withAnimation {
                            textEditorHeight = max(50, min(200, CGFloat(description.count / 2)))
                        }
                    }
            }
        }
        .listRowBackground(Color.semiDark)
    }
    
    // MARK: - Custom TextField
    private func customTextField(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            )
            .keyboardType(keyboard)
            .listRowBackground(Color.semiDark)
            .onChange(of: text.wrappedValue) { _, newValue in
                if newValue.count > 58 {
                    text.wrappedValue = String(text.wrappedValue.prefix(58))
                }
            }
    }
    
    // MARK: - Validate form
    private func isFormValid() -> Bool {
        return !name.isEmpty && !description.isEmpty && !city.isEmpty && !latitude.isEmpty && !longitude.isEmpty && selectedImage != nil
    }
    
    
    
    private func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self.isImagePickerPresented = true
                }
            }
        }
    }
    
    
    
    // MARK: - Add Urbex Logic
    private func addUrbex() {
        guard let image = selectedImage else {
            print("No image selected")
            return
        }
        
        isLoading = true
        
        guard let webpData = image.convertToWebP() else {
            print("Error converting image to WebP")
            isLoading = false
            return
        }
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("urbex_images/\(UUID().uuidString).webp")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/webp"
        
        imageRef.putData(webpData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting image URL: \(error.localizedDescription)")
                    isLoading = false
                    return
                }
                
                guard let imageURL = url?.absoluteString else {
                    isLoading = false
                    return
                }
                
                let lat = Double(latitude) ?? 0.0
                let lon = Double(longitude) ?? 0.0
                
                let urbexID = UUID().uuidString
                
                let urbex = Urbex(
                    id: urbexID,
                    addedBy: authViewModel.currentUser?.username ?? "Unknown",
                    addedDate: Timestamp(date: Date()),
                    city: city,
                    country: country.rawValue.uppercased(),
                    description: description,
                    imageURL: imageURL,
                    latitude: lat,
                    longitude: lon,
                    name: name,
                    likes: [],
                    dislikes: []
                )
                
                db.collection("urbexes").document(urbexID).setData([
                    "addedBy": urbex.addedBy,
                    "city": urbex.city,
                    "country": urbex.country,
                    "description": urbex.description,
                    "imageURL": urbex.imageURL,
                    "latitude": urbex.latitude,
                    "longitude": urbex.longitude,
                    "name": urbex.name,
                    "addedDate": urbex.addedDate,
                    "likes": [],
                    "dislikes": []
                    
                ]) { error in
                    if let error = error {
                        print("Error adding urbex: \(error.localizedDescription)")
                    } else {
                        print("Urbex added successfully")
                        self.authViewModel.addUrbexToUser(urbex: urbex)
                        self.authViewModel.incrementDailyUrbexCount() 
                    }
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    let firestoreService = FirestoreService()
    
    return AddUrbexDetailsView()
        .environmentObject(firestoreService)
}





extension UIImage {
    func convertToWebP() -> Data? {
       
        let maxDimension: CGFloat = 1000
        let scale = min(maxDimension/size.width, maxDimension/size.height, 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
     
        guard let imageData = resizedImage?.jpegData(compressionQuality: 0.5) else { return nil }
        
     
        if let originalData = self.jpegData(compressionQuality: 1.0) {
            print("Original size: \(originalData.count / 1024)KB")
            print("Compressed size: \(imageData.count / 1024)KB")
        }
        
        return imageData
    }
}
