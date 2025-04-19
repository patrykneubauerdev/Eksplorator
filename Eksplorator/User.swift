//
//  User.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 30/01/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import Foundation

struct User: Identifiable, Codable {
    let id: String
    let username: String
    let email: String
    var favoriteUrbexes: [String]
    var urbexes: [String]
    var isAdmin: Bool = false

    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: username) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        return ""
    }
}


extension User {
    static var mockUser = User(
        id: NSUUID().uuidString,
        username: "Patryk Neubauer",
        email: "test@gmail.com",
        favoriteUrbexes: [],
        urbexes: [],
        isAdmin: true
    )
}
