//
//  Secrets.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 12/04/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import Foundation

final class Secrets {
    static let shared = Secrets()

    private var secrets: [String: Any] = [:]

    private init() {
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
           let dict = plist as? [String: Any] {
            secrets = dict
        }
    }

    func get(_ key: String) -> String? {
        return secrets[key] as? String
    }
}
