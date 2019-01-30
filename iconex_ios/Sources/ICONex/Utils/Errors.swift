//
//  Errors.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation

public enum IXError: Error {
    case invalidCoinType
    case needAlias
    
    case generateKey
    case convertKey
    case copyPublicKey
    case keyMalformed
    case makeAddress
    case sign
    case invalidMessage
    case decrypt
    case invalidPassword
    
    case emptyWallet
    case invalidKeystore
    
    case convertBInt
    
    case storeData
    
    case invalidFiles
    case duplicateAddress
    case duplicateName
    case duplicateToken
    case invalidTokenInfo
    case emptyPrivateKey
    
    case noAddressInfo
}

extension IXError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidCoinType:
            return "Invalid coin type"
            
        case .needAlias:
            return "Need alias for new wallet"
            
        case .generateKey:
            return "Failed to generate key pair"
            
        case .convertKey:
            return "Failed to convert key from Data to SecKey"
            
        case .copyPublicKey:
            return "Failed to copy public key"
            
        case .keyMalformed:
            return "Key malformed"
            
        case .makeAddress:
            return "Failed to make address"
            
        case .sign:
            return "Failed to signing"
            
        case .invalidMessage:
            return "Invalid message"
            
        case .decrypt:
            return "Failed to decrypt"
            
        case .invalidPassword:
            return "Invalid password"
            
        case .emptyWallet:
            return "Empty wallet. Please create wallet first."
            
        case .invalidKeystore:
            return "Invalid Keystore data"
            
        case .convertBInt:
            return "Cannot convert string to BInt"
            
        case .storeData:
            return "Error occurred when save data into internal storage."
            
        case .invalidFiles:
            return "Invalid type of file"
            
        case .duplicateAddress:
            return "ICONex already has address."
            
        case .duplicateName:
            return "ICONex Already has name."
            
        case .duplicateToken:
            return "Token has already registered."
            
        case .invalidTokenInfo:
            return "Invalid token information"
            
        case .emptyPrivateKey:
            return "Private Key is missing."
            
        case .noAddressInfo:
            return "Couldn't find any AddressBook Informations"
        }
    }
}
