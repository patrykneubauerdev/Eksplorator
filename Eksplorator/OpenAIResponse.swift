//
//  OpenAIResponse.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 15/02/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import Foundation

struct OpenAIResponse: Codable {
    struct Result: Codable {
        let flagged: Bool
    }
    let results: [Result]
}

// MARK: - Globalne zmienne
var failedAttempts = UserDefaults.standard.integer(forKey: "failedAttempts")
var blockUntil: Date? {
    get {
        if let timestamp = UserDefaults.standard.object(forKey: "blockUntil") as? TimeInterval {
            return Date(timeIntervalSince1970: timestamp)
        }
        return nil
    }
    set {
        if let newValue = newValue {
            UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: "blockUntil")
        } else {
            UserDefaults.standard.removeObject(forKey: "blockUntil")
        }
    }
}


func checkContent(content: String, completion: @escaping (Bool, String?) -> Void) {
    
    guard let apiKey = Secrets.shared.get("OPENAI_API_KEY") else {
        completion(false, "API key not found.")
        return
    }
    let url = URL(string: "https://api.openai.com/v1/moderations")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = ["input": content]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { data, response, error in
        DispatchQueue.main.async {
            guard let data = data, error == nil else {
                completion(false, "Error contacting moderation API.")
                return
            }

            do {
                let moderationResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                let isFlagged = moderationResponse.results.first?.flagged ?? false
                
                completion(!isFlagged, isFlagged ? "Content contains inappropriate language." : nil)

            } catch {
                completion(false, "Error parsing moderation response.")
            }
        }
    }.resume()
}

func isUsernameAllowed(username: String, completion: @escaping (Bool, String?) -> Void) {
    
    let lowercasedUsername = username.lowercased()
    
    
    if let blockTime = blockUntil, Date() < blockTime {
        let remainingTime = Int(blockTime.timeIntervalSince(Date()))
        let message = "Too many inappropriate username attempts. Try again in \(remainingTime / 60) min \(remainingTime % 60) sec."
        completion(false, message)
        return
    }
    
   
    let bannedPattern = #"(?i)h[1i!|]t[l1i]er|n[i1!|]gg[e3]r|f[uü]ck|s[t7]alin|n[a@]z[i1!|]|m[uü]ss[o0]l[i1]n[i1]|k[uü] kl[uü]x kl[a@]n|b[i1]n l[a@]d[e3]n|a[l1] q[a@]e[d3]a|p[uü]t[i1]n|x[i1] j[i1]np[i1]ng|c[o0]mm[uü]n[i1]sm|t[e3]rr[o0]r[i1]sm|j[o0]s[e3]ph g[o0]ebb[e3]ls|p[o0]l p[o0]t|k[i1]m j[o0]ng [uü]n|t[a@]l[i1]b[a@]n|i[s5][i1]s|r[a@]c[i1]sm|s[e3]x[i1]sm|p[e3]d[o0]ph[i1]l[i1][a@]|z[i1]o[nm]ism|w[h4]i[t7]e s[uü]pr[e3]m[a@]cy|bl[a@]ck s[uü]pr[e3]m[a@]cy|h[o0]l[o0]c[a@]ust d[e3]n[i1]al|k[uü]rwa|ch[uü]j|d[e3]bil|idi[o0]ta|p[e3]da[l1]|ci[o0]ta|s[uü]ka|m[a@]ci[o0]ch[a@]|zjeb|jeb[a@]c|s3x|seks|porno|deepthroat|blowjob"#
    if lowercasedUsername.range(of: bannedPattern, options: .regularExpression) != nil {
        print("Username zablokowany przez regex!")
        let attemptsLeft = handleFailedAttempt()
        completion(false, attemptsLeft > 0 ? "This username is not allowed. Attempts left: \(attemptsLeft)" : "You have been temporarily blocked for 15 minutes.")
        return
    }
    
   
    guard let apiKey = Secrets.shared.get("OPENAI_API_KEY") else {
        completion(false, "API key not found.")
        return
    }
    let url = URL(string: "https://api.openai.com/v1/moderations")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = ["input": "Username attempt: \(username)"]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("Błąd API: \(error?.localizedDescription ?? "Nieznany błąd")")
            completion(false, "Error contacting moderation API.")
            return
        }

        do {
            let moderationResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            let isFlagged = moderationResponse.results.first?.flagged ?? false
            
            if isFlagged {
                print("Username zablokowany przez OpenAI Moderation API!")
                let attemptsLeft = handleFailedAttempt()
                completion(false, attemptsLeft > 0 ? "This username is not allowed. Attempts left: \(attemptsLeft)" : "You have been temporarily blocked for 15 minutes.")
                return
            }

          
            resetFailedAttempts()
            completion(true, nil)

        } catch {
            print("Błąd parsowania odpowiedzi API: \(error.localizedDescription)")
            completion(false, "Error parsing moderation response.")
        }
    }.resume()
}

// MARK: - Obsługa nieudanych prób
func handleFailedAttempt() -> Int {
    failedAttempts += 1
    UserDefaults.standard.set(failedAttempts, forKey: "failedAttempts")
    
    if failedAttempts >= 3 {
        blockUntil = Date().addingTimeInterval(15 * 60)
        resetFailedAttempts()
        return 0
    }
    
    return 3 - failedAttempts
}

func resetFailedAttempts() {
    failedAttempts = 0
    UserDefaults.standard.set(failedAttempts, forKey: "failedAttempts")
}
