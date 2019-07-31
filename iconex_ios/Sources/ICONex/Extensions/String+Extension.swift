//
//  String+Extension.swift
//  iconex_ios
//
//  Created by a1ahn on 19/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit
import CoreImage
import BigInt

// MARK: String
extension String {
    var base64Encoded: String? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        
        return data.base64EncodedString()
    }
    
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    var asciiArray: [UInt32] {
        return unicodeScalars.filter { $0.isASCII }.map { $0.value }
    }
    
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func boundingRect(size: CGSize, font: UIFont) -> CGSize {
        let text = self as NSString
        return text.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil).size
    }
    
    func generateQRCode() -> CIImage? {
        let data = self.data(using: .utf8)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        
        return filter?.outputImage
    }
}

extension String {
    func split(by length: Int) -> [String] {
        var startIndex = self.startIndex
        var results = [Substring]()
        
        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            results.append(self[startIndex..<endIndex])
            startIndex = endIndex
        }
        
        return results.map { String($0) }
    }
}

extension String {
    func removeContinuosSuffix(string: String) -> String {
        var conv = self as NSString
        while conv.hasSuffix(string) {
            conv = conv.substring(to: conv.length - 1) as NSString
        }
        return String(conv)
    }
}

extension String {
    func bigUInt(decimal: Int = 18, fixed: Bool = false) -> BigUInt? {
        var groupingSeparator = Tool.groupingSeparator
        var decimalSeparator = Tool.decimalSeparator
        
        if fixed {
            groupingSeparator = ","
            decimalSeparator = "."
        }
        
        let strip = self.replacingOccurrences(of: groupingSeparator, with: "")
        let comp = strip.components(separatedBy: decimalSeparator)
        
        var result: BigUInt?
        if comp.count < 2 {
            guard let first = comp.first, let quotient = BigUInt(first) else {
                return nil
            }
            
            let completed = quotient * BigUInt(10).power(decimal)
            result = completed
        } else {
            guard let first = comp.first, let second = comp.last, let quotient = BigUInt(first, radix: 10), let remainder = BigUInt(second, radix: 10) else {
                return nil
            }
            let completed = (quotient * BigUInt(10).power(decimal)) + (remainder * BigUInt(10).power(decimal - second.count))
            result = completed
        }
        
        return result
    }
}

extension String {
    func currencySeparated() -> String {
        let comp = self.components(separatedBy: Tool.decimalSeparator)
        
        guard let upper = comp.first else {
            return self
        }
        
        var below = ""
        if comp.count == 2, let last = comp.last, last != "" {
            below = last
        }
        
        let split = String(upper.reversed()).split(by: 3)
        let joined = split.joined(separator: Tool.groupingSeparator)
        let formatted = String(joined.reversed())
        return below == "" ? formatted : formatted + Tool.decimalSeparator + below
    }
}

extension String {
    func add0xPrefix() -> String {
        guard self.count == 40 else { return self }
        
        if !self.hasPrefix("0x") {
            return "0x" + self
        }
        
        return self
    }
    
    func addHxPrefix() -> String {
        guard self.count == 40 else { return self }
        
        if !self.hasPrefix("hx") {
            return "hx" + self
        }
        return self
    }
}
