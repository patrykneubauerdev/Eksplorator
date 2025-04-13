//
//  KeychainHelper.swift
//  Eksplorator
//
//  Created by Patryk Neubauer on 07/04/2025.
//  Copyright © Eksplorator 2025 Patryk Neubauer. All rights reserved.

import Foundation
import Security


class KeychainHelper {
    static func save(_ data: Any, key: String) {
        guard let data = (data as? String)?.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
       
        SecItemDelete(query as CFDictionary)
        
    
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(key: String) -> Any? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr {
            if let data = dataTypeRef as? Data,
               let result = String(data: data, encoding: .utf8) {
                return result
            }
        }
        return nil
    }
}
