//
//  Urbex.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 24/01/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import Foundation
import FirebaseFirestore

struct Urbex: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var addedBy: String
    var addedDate: Timestamp
    var city: String
    var country: String
    var description: String
    var imageURL: String
    var latitude: Double
    var longitude: Double
    var name: String
    var likes: [String] = []
    var dislikes: [String] = []
    var activeVotes: [String] = []
    var inactiveVotes: [String] = []
    
    
    
    
    
}

