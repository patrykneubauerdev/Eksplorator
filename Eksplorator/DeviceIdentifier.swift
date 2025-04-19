//
//  DeviceIdentifier.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 07/04/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import Foundation
import UIKit


class DeviceIdentifier {
   
    static func getDeviceIdentifier() -> String {
       
        if let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString {
            return identifierForVendor
        }
        
       
        let keychainIdentifierKey = "com.urbexapp.deviceIdentifier"
        
    
        if let existingID = KeychainHelper.load(key: keychainIdentifierKey) as? String {
            return existingID
        }
        
      
        let newID = UUID().uuidString
        KeychainHelper.save(newID, key: keychainIdentifierKey)
        return newID
    }
}
