//
//  PerspectiveAPIHandler.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 30/03/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import Foundation
import Combine


class PerspectiveAPIHandler {
    
  
    private let apiURL = URL(string: "https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze")!
    
  
    private let apiKey: String
    
  
    private let attributes = [
        "TOXICITY",
        "SEVERE_TOXICITY",
        "IDENTITY_ATTACK",
        "INSULT",
        "PROFANITY",
        "THREAT",
        "TOXICITY_EXPERIMENTAL",
        "SEXUALLY_EXPLICIT",
        "INFLAMMATORY"
    ]
    
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
   
    func analyzeText(_ text: String, languages: [String] = ["en"], completion: @escaping (Result<ToxicityAnalysisResult, Error>) -> Void) {
        guard var urlComponents = URLComponents(url: apiURL, resolvingAgainstBaseURL: false) else {
            completion(.failure(PerspectiveAPIError.invalidURL))
            return
        }
        
    
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        guard let url = urlComponents.url else {
            completion(.failure(PerspectiveAPIError.invalidURL))
            return
        }
        
    
        let requestData = prepareRequestData(text: text, languages: languages)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestData)
        } catch {
            completion(.failure(error))
            return
        }
        
       
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(PerspectiveAPIError.noData))
                return
            }
            
            do {
                let apiResponse = try JSONDecoder().decode(PerspectiveAPIResponse.self, from: data)
                let result = self.processAPIResponse(apiResponse)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
   
    func analyzeTextPublisher(_ text: String, languages: [String] = ["pl", "en"]) -> AnyPublisher<ToxicityAnalysisResult, Error> {
        Future<ToxicityAnalysisResult, Error> { promise in
            self.analyzeText(text, languages: languages) { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
   
    private func prepareRequestData(text: String, languages: [String]) -> PerspectiveAPIRequest {
        var requestedAttributes: [String: PerspectiveAttributeRequest] = [:]
        
        for attribute in attributes {
            requestedAttributes[attribute] = PerspectiveAttributeRequest(scoreType: "PROBABILITY")
        }
        
        return PerspectiveAPIRequest(
            comment: CommentRequest(text: text),
            languages: languages,
            requestedAttributes: requestedAttributes
        )
    }
    
  
    private func processAPIResponse(_ response: PerspectiveAPIResponse) -> ToxicityAnalysisResult {
        var scores: [ToxicityType: Double] = [:]
        
        if let toxicityScore = response.attributeScores["TOXICITY"]?.summaryScore.value {
            scores[.toxicity] = toxicityScore
        }
        
        if let severeToxicityScore = response.attributeScores["SEVERE_TOXICITY"]?.summaryScore.value {
            scores[.severeToxicity] = severeToxicityScore
        }
        
        if let identityAttackScore = response.attributeScores["IDENTITY_ATTACK"]?.summaryScore.value {
            scores[.identityAttack] = identityAttackScore
        }
        
        if let insultScore = response.attributeScores["INSULT"]?.summaryScore.value {
            scores[.insult] = insultScore
        }
        
        if let profanityScore = response.attributeScores["PROFANITY"]?.summaryScore.value {
            scores[.profanity] = profanityScore
        }
        
        if let threatScore = response.attributeScores["THREAT"]?.summaryScore.value {
            scores[.threat] = threatScore
        }
        
        if let toxicityExperimentalScore = response.attributeScores["TOXICITY_EXPERIMENTAL"]?.summaryScore.value {
            scores[.toxicityExperimental] = toxicityExperimentalScore
        }
        
        if let sexuallyExplicitScore = response.attributeScores["SEXUALLY_EXPLICIT"]?.summaryScore.value {
            scores[.sexuallyExplicit] = sexuallyExplicitScore
        }
        
        if let inflammatoryScore = response.attributeScores["INFLAMMATORY"]?.summaryScore.value {
            scores[.inflammatory] = inflammatoryScore
        }
        
        return ToxicityAnalysisResult(scores: scores)
    }
}




enum ToxicityType: String, CaseIterable {
    case toxicity = "Toxicity"
    case severeToxicity = "Severe toxicity"
    case identityAttack = "Identity attack"
    case insult = "Insult"
    case profanity = "Profanity"
    case threat = "Threat"
    case toxicityExperimental = "Experimental toxicity"
    case sexuallyExplicit = "Sexually explicit"
    case inflammatory = "Inflammatory"
}


struct ToxicityAnalysisResult {
    let scores: [ToxicityType: Double]
    
  
    func isToxic(threshold: Double = 0.7) -> Bool {
        for (_, score) in scores {
            if score >= threshold {
                return true
            }
        }
        return false
    }
    
  
    func detectedToxicities(threshold: Double = 0.7) -> [ToxicityType] {
        return scores.filter { $0.value >= threshold }.map { $0.key }
    }
}




struct PerspectiveAPIRequest: Encodable {
    let comment: CommentRequest
    let languages: [String]
    let requestedAttributes: [String: PerspectiveAttributeRequest]
}


struct CommentRequest: Encodable {
    let text: String
}


struct PerspectiveAttributeRequest: Encodable {
    let scoreType: String
}


struct PerspectiveAPIResponse: Decodable {
    let attributeScores: [String: AttributeScore]
}


struct AttributeScore: Decodable {
    let summaryScore: SummaryScore
}


struct SummaryScore: Decodable {
    let value: Double
}



enum PerspectiveAPIError: Error {
    case invalidURL
    case noData
    case invalidResponse
}



extension PerspectiveAPIHandler {
    
    func validateUGCContent(placeName: String, placeDescription: String, cityName: String, threshold: Double = 0.7, completion: @escaping (Result<UGCValidationResult, Error>) -> Void) {
        
        let dispatchGroup = DispatchGroup()
        var placeNameResult: ToxicityAnalysisResult?
        var placeDescriptionResult: ToxicityAnalysisResult?
        var cityNameResult: ToxicityAnalysisResult?
        var validationError: Error?
        
       
        dispatchGroup.enter()
        analyzeText(placeName) { result in
            switch result {
            case .success(let analysisResult):
                placeNameResult = analysisResult
            case .failure(let error):
                validationError = error
            }
            dispatchGroup.leave()
        }
        
      
        dispatchGroup.enter()
        analyzeText(placeDescription) { result in
            switch result {
            case .success(let analysisResult):
                placeDescriptionResult = analysisResult
            case .failure(let error):
                validationError = error
            }
            dispatchGroup.leave()
        }
        
       
        dispatchGroup.enter()
        analyzeText(cityName) { result in
            switch result {
            case .success(let analysisResult):
                cityNameResult = analysisResult
            case .failure(let error):
                validationError = error
            }
            dispatchGroup.leave()
        }
        
       
        dispatchGroup.notify(queue: .main) {
            if let error = validationError {
                completion(.failure(error))
                return
            }
            
            guard let nameResult = placeNameResult,
                  let descriptionResult = placeDescriptionResult,
                  let cityResult = cityNameResult else {
                completion(.failure(PerspectiveAPIError.invalidResponse))
                return
            }
            
            let isValid = !nameResult.isToxic(threshold: threshold) &&
                         !descriptionResult.isToxic(threshold: threshold) &&
                         !cityResult.isToxic(threshold: threshold)
            
            var issues: [UGCContentIssue] = []
            
            if nameResult.isToxic(threshold: threshold) {
                issues.append(.toxic(field: .placeName, types: nameResult.detectedToxicities(threshold: threshold)))
            }
            
            if descriptionResult.isToxic(threshold: threshold) {
                issues.append(.toxic(field: .placeDescription, types: descriptionResult.detectedToxicities(threshold: threshold)))
            }
            
            if cityResult.isToxic(threshold: threshold) {
                issues.append(.toxic(field: .cityName, types: cityResult.detectedToxicities(threshold: threshold)))
            }
            
            let result = UGCValidationResult(isValid: isValid, issues: issues)
            completion(.success(result))
        }
    }
    
   
    func validateUGCContentPublisher(placeName: String, placeDescription: String, cityName: String, threshold: Double = 0.7) -> AnyPublisher<UGCValidationResult, Error> {
        Future<UGCValidationResult, Error> { promise in
            self.validateUGCContent(placeName: placeName, placeDescription: placeDescription, cityName: cityName, threshold: threshold) { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
}


enum UGCContentField: String {
    case placeName = "Name"
    case placeDescription = "Description"
    case cityName = "City"
}


enum UGCContentIssue {
    case toxic(field: UGCContentField, types: [ToxicityType])
    
    var description: String {
        switch self {
        case .toxic(let field, let types):
            let typesString = types.map { $0.rawValue }.joined(separator: ", ")
            return "Field '\(field.rawValue)' contains prohibited content: \(typesString)"
        }
    }
}


struct UGCValidationResult {
    let isValid: Bool
    let issues: [UGCContentIssue]
    
    var description: String {
        if isValid {
            return "Content is appropriate."
        } else {
            let issuesDescription = issues.map { $0.description }.joined(separator: "\n")
            return "Content contains prohibited elements:\n\(issuesDescription)"
        }
    }
}
