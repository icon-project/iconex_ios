//
//  Errors.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation

enum CryptError: Error, CustomDebugStringConvertible {
    case generateKey
    case convertKey
    case createPublicKey
    case keyMalformed
    case makeAddress
    case sign
    case invalidMessage
    case invalidPassword
    
    var debugDescription: String {
        return "Fatal error. CryptError(\(self))"
    }
}

enum WalletError: Error, CustomDebugStringConvertible {
    case emptyWallet
    case invalidKeystore
    case noWallet(String)
    case noToken(String)
    
    var debugDescription: String {
        return "Fata error. WalletError(\(self))"
    }
}

enum CommonError: Error, CustomDebugStringConvertible {
    case invalidFiles
    case duplicateAddress
    case duplicateName
    case duplicateToken
    case emptyPrivateKey
    case saveData
    
    var debugDescription: String {
        return "Fatal error. CommonError(\(self))"
    }
}
