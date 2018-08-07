//
//  ICON.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import Foundation

/// ICX Keystore struct
public struct ICON {
    struct Keystore: Codable {
        let version: Int = 3
        let id: String = UUID().uuidString
        var address: String
        var crypto: Crypto
        let coinType: String = "icx"
    }
    
    struct Crypto: Codable {
        var ciphertext: String
        var cipherparams: CipherParams
        var cipher: String
        var kdf: String
        var kdfparams: KDF
        var mac: String
    }
    
    struct CipherParams: Codable {
        var iv: String
    }
    
    struct KDF: Codable {
        let dklen: Int
        var salt: String
        let c: Int
        let prf: String
    }
    
    public class Wallet {
        var keystore: Keystore?
        var address: String? {
            return keystore?.address
        }
    }
}


// MARK: Date
extension Date {
    static var timestampString: String {
        let date = Date()
        let time = floor(date.timeIntervalSince1970)
        
        return String(format: "%.0f", time)
    }
    
    static var millieTimestamp: String {
        let date = Date()
        let time = floor(date.timeIntervalSince1970)
        
        return String(format: "%.0f", time * 1000)
    }
    
    static var microTimestamp: String {
        let date = Date()
        let time = floor(date.timeIntervalSince1970)
        
        return String(format: "%.0f", time * 1000 * 1000)
    }
    
    static var currentZuluTime: String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        var result = formatter.string(from: date)
        formatter.dateFormat = "HH-mm-ss.SSS"
        result = result + "T" + formatter.string(from: date) + "Z"
        
        return result
    }
    
    var timestampString: String {
        return String(format: "%.0f", self.timeIntervalSince1970)
    }
    
    var millieTimestamp: String {
        return String(format: "%.0f", self.timeIntervalSince1970 * 1000)
    }
    
    var microTimestamp: String {
        return String (format: "%.0f", self.timeIntervalSince1970 * 1000 * 1000)
    }
    
    func toString(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        
        return formatter.string(from: self)
    }
}

extension String {
    
    func hexToData() -> Data? {
        var data = Data(capacity: self.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSMakeRange(0, utf16.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }
        
        guard data.count > 0 else { return nil }
        
        return data
    }
    
}
