//
//  Validator.swift
//  iconex_ios
//
//  Created by a1ahn on 18/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation

struct Validator {
    static func isEmail(input email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    static func validateCharacterSet(password: String) -> Bool {
        var charSet = CharacterSet.lowercaseLetters
        let digitSet = CharacterSet.decimalDigits
        let specialSet = CharacterSet(charactersIn: "?!:.,%+-/*<>{}()[]`\"'~_^\\|@#$&")
        let letterSet = charSet.union(CharacterSet.uppercaseLetters)
        
        charSet = letterSet.union(digitSet)
        charSet = charSet.union(specialSet)
        
        let notAllowed = password.unicodeScalars.filter { charSet.inverted.contains($0) }
        let hasLetters = password.unicodeScalars.filter { letterSet.contains($0) }
        let hasDigits = password.unicodeScalars.filter { digitSet.contains($0) }
        let hasSpecial = password.unicodeScalars.filter { specialSet.contains($0) }
        
        return notAllowed.count == 0 && hasLetters.count > 0 && hasDigits.count > 0 && hasSpecial.count > 0
    }
    
    static func validateSequenceNumber(password: String) -> Bool {
        var valid = true
        
        let pinArray = password.unicodeScalars.filter({ $0.isASCII }).map({ $0.value })
        
        for i in 2..<pinArray.count {
            let c1 = Int(String(pinArray[i - 2]))!
            let c2 = Int(String(pinArray[i - 1]))!
            let c3 = Int(String(pinArray[i]))!
            
            if c1 == c2 && c2 == c3 {
                valid = false
                break
            }
        }
        
        return valid
    }
    
    static func validateICXAddress(address: String) -> Bool {
        let pattern = "^(hx[a-zA-Z0-9]{40})$"
        let result = NSPredicate(format: "SELF MATCHES %@", pattern)
        return result.evaluate(with: address)
    }
    
    static func validateIRCAddress(address: String) -> Bool {
        let pattern = "^(cx[a-zA-Z0-9]{40})$"
        let result = NSPredicate(format: "SELF MATCHES %@", pattern)
        return result.evaluate(with: address)
    }
    
    static func validateETHAddress(address: String) -> Bool {
        let tempAddress = address.add0xPrefix()
        guard tempAddress.count == 42 else { return false }
        let pattern = "^(0x[a-zA-Z0-9]{40})$"
        let result = NSPredicate(format: "SELF MATCHES %@", pattern)
        return result.evaluate(with: tempAddress)
    }
    
    static func validateKeystore(urlOfData: URL) throws -> ICONKeystore {
        let content = try Data(contentsOf: urlOfData)
        Log("content - \(String(describing: String(data: content, encoding: .utf8)))")
        let decoder = JSONDecoder()
        
        let keystore = try decoder.decode(ICONKeystore.self, from: content)
        
        let wallet = ICXWallet(name: "temp", keystore: keystore)
        guard wallet.canSave(address: keystore.address) else {
            throw CommonError.duplicateAddress
        }
        
        return keystore
    }
    
    static func checkWalletBundle(url:URL) -> [[String: WalletBundle]]? {
        do {
            let content = try Data(contentsOf: url)
            
            let decoder = JSONDecoder()
            let list = try decoder.decode([[String: WalletBundle]].self, from: content)
            
            return list
        } catch {
            return nil
        }
    }
    
    static func validateBundlePassword(bundle newBundle:[[String: WalletBundle]], password: String) -> Bool {
        let item = newBundle.first!
        let address = item.keys.first!
        let bundle = item[address]!
        let data = bundle.priv.data(using: .utf8)!
        
        if bundle.type == "icx" {
            guard let icx = ICXWallet(name: bundle.name, rawData: data) else { return false }
            guard ((try? icx.extractICXPrivateKey(password: password)) != nil) else { return false }
        } else if bundle.type == "eth" {
            guard let eth = ETHWallet(name: bundle.name, rawData: data) else { return false }
            guard ((try? eth.extractETHPrivateKey(password: password)) != nil) else { return false }
        }
        
        return true
    }
    
    static func validateTokenSymbol(symbol: String) -> Bool {
        let pattern = "^[a-zA-Z0-9]*$"
        let result = NSPredicate(format: "SELF MATCHES %@", pattern)
        return result.evaluate(with: symbol)
    }
}
