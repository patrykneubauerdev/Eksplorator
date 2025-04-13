//
//  GoogleVisionService.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 28/03/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import Foundation
import UIKit

class GoogleVisionService {
    private let apiKey = Secrets.shared.get("GOOGLE_CLOUD_API_KEY")
    
    func analyzeImage(image: UIImage, completion: @escaping (Bool, String?) -> Void) {
        guard let base64Image = image.toBase64() else {
            completion(false, "Failed to convert image")
            return
        }
        
        let requestData: [String: Any] = [
            "requests": [
                [
                    "image": ["content": base64Image],
                    "features": [
                        ["type": "SAFE_SEARCH_DETECTION"],
                        ["type": "TEXT_DETECTION"]
                    ]
                ]
            ]
        ]
        
        guard let apiKey = apiKey,
              let url = URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(apiKey)") else {
            completion(false, "Invalid API key or URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestData, options: [])
            request.httpBody = jsonData
        } catch {
            completion(false, "Failed to encode JSON")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(false, "Request error: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            
            do {
                let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let responses = responseJSON?["responses"] as? [[String: Any]],
                   let safeSearch = responses.first?["safeSearchAnnotation"] as? [String: String] {
                    
                    let adult = safeSearch["adult"] ?? "UNKNOWN"
                    let violence = safeSearch["violence"] ?? "UNKNOWN"
                    let racy = safeSearch["racy"] ?? "UNKNOWN"
                    let spoof = safeSearch["spoof"] ?? "UNKNOWN"
                    let medical = safeSearch["medical"] ?? "UNKNOWN"
                    
                    let blockedCategories: Set<String> = ["LIKELY", "VERY_LIKELY"]
                    
                    if blockedCategories.contains(adult) || blockedCategories.contains(violence) || blockedCategories.contains(racy) || blockedCategories.contains(spoof) || blockedCategories.contains(medical) {
                        completion(false, "Image contains inappropriate content")
                    } else {
                        completion(true, nil)
                    }
                } else {
                    completion(false, "Unexpected API response")
                }
            } catch {
                completion(false, "Failed to parse response")
            }
        }
        
        task.resume()
    }
}

extension UIImage {
    func toBase64() -> String? {
        return self.jpegData(compressionQuality: 0.8)?.base64EncodedString()
    }
}
