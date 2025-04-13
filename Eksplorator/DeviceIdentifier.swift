//
//  DeviceIdentifier.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 07/04/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import Foundation
import UIKit

// DeviceIdentifier utility class to get unique device identifier in a privacy-conscious way
class DeviceIdentifier {
    // Get a unique device identifier that is compliant with App Store guidelines
    static func getDeviceIdentifier() -> String {
        // Using identifierForVendor which is App Store compliant and resets when all apps from the vendor are uninstalled
        if let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString {
            return identifierForVendor
        }
        
        // Fallback to creating and storing a UUID in keychain if identifierForVendor is not available
        let keychainIdentifierKey = "com.urbexapp.deviceIdentifier"
        
        // Try to retrieve existing ID from keychain
        if let existingID = KeychainHelper.load(key: keychainIdentifierKey) as? String {
            return existingID
        }
        
        // Create new UUID if none exists
        let newID = UUID().uuidString
        KeychainHelper.save(newID, key: keychainIdentifierKey)
        return newID
    }
}
