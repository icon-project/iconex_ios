//
//  extensions.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics
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
    
    var length: Int {
        let nsstring = self as NSString
        
        return nsstring.length
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

// MARK: Chracter
extension Character {
    var asciiValue: Int {
        get {
            let s = String(self).unicodeScalars
            return Int(s[s.startIndex].value)
        }
    }
}

// MARK: UIColor
extension UIColor {
    public enum darkTheme {
        case background
        case text
        
        var normal: UIColor {
            switch self {
            case .background:
                return UIColor(38, 38, 38)
                
            case .text:
                return UIColor(255, 255, 255)
            }
        }
        
        var selected: UIColor {
            switch self {
            case .background:
                return UIColor(0, 0, 0)
                
            case .text:
                return UIColor(255, 255, 255)
            }
        }
        
        var pressed: UIColor {
            switch self {
            case .background:
                return UIColor(0, 0, 0)
                
            case .text:
                return UIColor(255, 255, 255)
            }
        }
        
        var disabled: UIColor {
            switch self {
            case .background:
                return UIColor(230, 230, 230)
                
            case .text:
                return UIColor(179, 179, 179)
            }
        }
    }
    
    public enum lightTheme {
        case background
        case text
        
        var normal: UIColor {
            switch self {
            case .background:
                return UIColor(26, 170, 186)
                
            case .text:
                return UIColor.white
            }
        }
        
        var selected: UIColor {
            switch self {
            case .background:
                return UIColor(18, 117, 128)
                
            case .text:
                return UIColor.white
            }
        }
        
        var pressed: UIColor {
            switch self {
            case .background:
                return UIColor(18, 117, 128)
                
            case .text:
                return UIColor.white
            }
        }
        
        var disabled: UIColor {
            switch self {
            case .background:
                return UIColor(230, 230, 230)
                
            case .text:
                return UIColor(179, 179, 179)
            }
        }
    }
    
    public enum Step {
        case checked
        case current
        case standBy
        
        var line: UIColor {
            switch self {
            case .checked:
                return UIColor.white
                
            case .current:
                return UIColor.white
                
            case .standBy:
                return UIColor(6, 138, 153)
            }
        }
        
        var text: UIColor {
            switch self {
            case .checked:
                return UIColor(hex: 0xFFFFFF, alpha: 0.5)
                
            case .current:
                return UIColor.white
                
            case .standBy:
                return UIColor(6, 138, 153)
            }
        }
    }
    
    static var warn: UIColor {
        return UIColor(242, 48, 48)
    }
    
    convenience init(_ red: Int, _ green: Int, _ blue: Int, _ alpha: CGFloat = 1.0) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }
    
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        self.init(red: CGFloat((hex >> 16) & 0xff), green: CGFloat((hex >> 8) & 0xff), blue: CGFloat(hex & 0xff), alpha: alpha)
    }
    
}

// MARK: UIButton
extension UIButton {
    func alignVertical(spacing: CGFloat = 5) {
        guard let imageSize = self.imageView?.image?.size, let text = self.titleLabel?.text, let font = self.titleLabel?.font else {
            return
        }
        
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageSize.width, bottom: -(imageSize.height + spacing), right: 0)
        let labelString = NSString(string: text)
        let titleSize = labelString.size(withAttributes: [NSAttributedString.Key.font: font])
        self.imageEdgeInsets = UIEdgeInsets(top: -(titleSize.height + spacing), left: 0, bottom: 0, right: -titleSize.width)
        let edgeOffset = abs(titleSize.height - imageSize.height) / 2.0
        self.contentEdgeInsets = UIEdgeInsets(top: edgeOffset, left: 0, bottom: edgeOffset, right: 0)
    }
    
    func setBackgroundImage(color: UIColor, state: UIControl.State) {
        let backImage = UIImage(color: color)
        self.setBackgroundImage(backImage, for: state)
    }
    
    func rounded() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = self.layer.bounds.size.height / 2
        self.titleLabel?.font = UIFont.systemFont(ofSize: 17)
    }
    
    func cornered() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 4
        self.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    }
    
    func styleLight() {
        self.setBackgroundImage(UIImage(color: UIColor.lightTheme.background.normal), for: .normal)
        self.setTitleColor(UIColor.lightTheme.text.normal, for: .normal)
        self.setBackgroundImage(UIImage(color: UIColor.lightTheme.background.pressed), for: .highlighted)
        self.setTitleColor(UIColor.lightTheme.text.pressed, for: .highlighted)
        self.setBackgroundImage(UIImage(color: UIColor.lightTheme.background.selected), for: .selected)
        self.setTitleColor(UIColor.lightTheme.text.selected, for: .selected)
        self.setBackgroundImage(UIImage(color: UIColor.lightTheme.background.disabled), for: .disabled)
        self.setTitleColor(UIColor.lightTheme.text.disabled, for: .disabled)
    }
    
    func styleDark() {
        self.setBackgroundImage(UIImage(color: UIColor.darkTheme.background.normal), for: .normal)
        self.setTitleColor(UIColor.darkTheme.text.normal, for: .normal)
        self.setBackgroundImage(UIImage(color: UIColor.darkTheme.background.pressed), for: .highlighted)
        self.setTitleColor(UIColor.darkTheme.text.pressed, for: .highlighted)
        self.setBackgroundImage(UIImage(color: UIColor.darkTheme.background.selected), for: .selected)
        self.setTitleColor(UIColor.darkTheme.text.selected, for: .selected)
        self.setBackgroundImage(UIImage(color: UIColor.darkTheme.background.disabled), for: .disabled)
        self.setTitleColor(UIColor.darkTheme.text.disabled, for: .disabled)
    }
}

// MARK : UIView
extension UIView {
    func border(_ width: CGFloat, _ color: UIColor) {
        self.layer.borderWidth = width
        self.layer.borderColor = color.cgColor
    }
    
    func corner(_ radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}

extension UIView {
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

// MARK : CALayer
extension CALayer {
    func border(_ width: CGFloat, _ color: UIColor) {
        self.borderWidth = width
        self.borderColor = color.cgColor
    }
}

// MARK: UIImage
extension UIImage {
    public convenience init?(color: UIColor) {
        let rect = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    public convenience init?(color: UIColor, width: CGFloat, height: CGFloat) {
        let rect = CGRect(origin: .zero, size: CGSize(width: width, height: height))
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    public convenience init?(backgroundColor: UIColor, size: CGSize, borderColor: UIColor = UIColor.white, borderWidth: CGFloat = 0) {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            context.cgContext.setFillColor(borderColor.cgColor)
            context.cgContext.addEllipse(in: CGRect(origin: .zero, size: size))
            
            context.cgContext.drawPath(using: .fill)
            
            let innerRect = CGRect(origin: CGPoint(x: borderWidth, y: borderWidth), size: CGSize(width: size.width - borderWidth * 2, height: size.height - borderWidth * 2))
            context.cgContext.setFillColor(backgroundColor.cgColor)
            context.cgContext.addEllipse(in: innerRect)
            
            context.cgContext.drawPath(using: .fill)
        }
        
        guard let cgImage = image.cgImage else { return nil }
        
        self.init(cgImage: cgImage, scale: UIScreen.main.nativeScale, orientation: .up)
    }
}

// MARK : Data
extension Data {
    func subdata(in range: ClosedRange<Index>) -> Data {
        return subdata(in: range.lowerBound ..< range.upperBound + 1)
    }
    
//    struct HexEncodingOptions: OptionSet {
//        let rawValue: Int
//        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
//    }
//    
//    func hexEncodedString(options: HexEncodingOptions = []) -> String {
//        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
//        return map { String(format: format, $0) }.joined()
//    }
}


// MARK: UIViewController
extension UIViewController {
    func show(_ sourceController: UIViewController, _ animated: Bool = true, _ handler: (() -> Void)? = nil) {
        sourceController.present(self, animated: animated, completion: handler)
    }
}



public enum Model : String {
    case simulator   = "simulator/sandbox",
    iPod1            = "iPod 1",
    iPod2            = "iPod 2",
    iPod3            = "iPod 3",
    iPod4            = "iPod 4",
    iPod5            = "iPod 5",
    iPad2            = "iPad 2",
    iPad3            = "iPad 3",
    iPad4            = "iPad 4",
    iPhone4          = "iPhone 4",
    iPhone4S         = "iPhone 4S",
    iPhone5          = "iPhone 5",
    iPhone5S         = "iPhone 5S",
    iPhone5C         = "iPhone 5C",
    iPadMini1        = "iPad Mini 1",
    iPadMini2        = "iPad Mini 2",
    iPadMini3        = "iPad Mini 3",
    iPadAir1         = "iPad Air 1",
    iPadAir2         = "iPad Air 2",
    iPadPro9_7       = "iPad Pro 9.7\"",
    iPadPro9_7_cell  = "iPad Pro 9.7\" cellular",
    iPadPro10_5      = "iPad Pro 10.5\"",
    iPadPro10_5_cell = "iPad Pro 10.5\" cellular",
    iPadPro12_9      = "iPad Pro 12.9\"",
    iPadPro12_9_cell = "iPad Pro 12.9\" cellular",
    iPhone6          = "iPhone 6",
    iPhone6plus      = "iPhone 6 Plus",
    iPhone6S         = "iPhone 6S",
    iPhone6Splus     = "iPhone 6S Plus",
    iPhoneSE         = "iPhone SE",
    iPhone7          = "iPhone 7",
    iPhone7plus      = "iPhone 7 Plus",
    iPhone8          = "iPhone 8",
    iPhone8plus      = "iPhone 8 Plus",
    iPhoneX          = "iPhone X",
    unrecognized     = "?unrecognized?"
}

public extension UIDevice {
    var type: Model {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
                
            }
        }
        var modelMap : [ String : Model ] = [
            "i386"       : .simulator,
            "x86_64"     : .simulator,
            "iPod1,1"    : .iPod1,
            "iPod2,1"    : .iPod2,
            "iPod3,1"    : .iPod3,
            "iPod4,1"    : .iPod4,
            "iPod5,1"    : .iPod5,
            "iPad2,1"    : .iPad2,
            "iPad2,2"    : .iPad2,
            "iPad2,3"    : .iPad2,
            "iPad2,4"    : .iPad2,
            "iPad2,5"    : .iPadMini1,
            "iPad2,6"    : .iPadMini1,
            "iPad2,7"    : .iPadMini1,
            "iPhone3,1"  : .iPhone4,
            "iPhone3,2"  : .iPhone4,
            "iPhone3,3"  : .iPhone4,
            "iPhone4,1"  : .iPhone4S,
            "iPhone5,1"  : .iPhone5,
            "iPhone5,2"  : .iPhone5,
            "iPhone5,3"  : .iPhone5C,
            "iPhone5,4"  : .iPhone5C,
            "iPad3,1"    : .iPad3,
            "iPad3,2"    : .iPad3,
            "iPad3,3"    : .iPad3,
            "iPad3,4"    : .iPad4,
            "iPad3,5"    : .iPad4,
            "iPad3,6"    : .iPad4,
            "iPhone6,1"  : .iPhone5S,
            "iPhone6,2"  : .iPhone5S,
            "iPad4,1"    : .iPadAir1,
            "iPad4,2"    : .iPadAir2,
            "iPad4,4"    : .iPadMini2,
            "iPad4,5"    : .iPadMini2,
            "iPad4,6"    : .iPadMini2,
            "iPad4,7"    : .iPadMini3,
            "iPad4,8"    : .iPadMini3,
            "iPad4,9"    : .iPadMini3,
            "iPad6,3"    : .iPadPro9_7,
            "iPad6,11"   : .iPadPro9_7,
            "iPad6,4"    : .iPadPro9_7_cell,
            "iPad6,12"   : .iPadPro9_7_cell,
            "iPad6,7"    : .iPadPro12_9,
            "iPad6,8"    : .iPadPro12_9_cell,
            "iPad7,3"    : .iPadPro10_5,
            "iPad7,4"    : .iPadPro10_5_cell,
            "iPhone7,1"  : .iPhone6plus,
            "iPhone7,2"  : .iPhone6,
            "iPhone8,1"  : .iPhone6S,
            "iPhone8,2"  : .iPhone6Splus,
            "iPhone8,4"  : .iPhoneSE,
            "iPhone9,1"  : .iPhone7,
            "iPhone9,2"  : .iPhone7plus,
            "iPhone9,3"  : .iPhone7,
            "iPhone9,4"  : .iPhone7plus,
            "iPhone10,1" : .iPhone8,
            "iPhone10,2" : .iPhone8plus,
            "iPhone10,3" : .iPhoneX,
            "iPhone10,6" : .iPhoneX
        ]
        
        if let model = modelMap[String.init(validatingUTF8: modelCode!)!] {
            return model
        }
        return Model.unrecognized
    }
}

extension String {
    func currencySeparated() -> String {
        let comp = self.components(separatedBy: Tools.decimalSeparator)

        guard let upper = comp.first else {
            return self
        }

        var below = ""
        if comp.count == 2, let last = comp.last, last != "" {
            below = last
        }
        
        let split = String(upper.reversed()).split(by: 3)
        let joined = split.joined(separator: Tools.groupingSeparator)
        let formatted = String(joined.reversed())
        return below == "" ? formatted : formatted + Tools.decimalSeparator + below
    }
}

// https://stackoverflow.com/a/46049763/1648275
struct JSONCodingKeys: CodingKey {
    var stringValue: String
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int?
    
    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

extension KeyedDecodingContainer {
    
    func decode(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any> {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode(type)
    }
    
    func decodeIfPresent(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any>? {
        guard contains(key) else {
            return nil
        }
        guard try decodeNil(forKey: key) == false else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    func decode(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any> {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
    
    func decodeIfPresent(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any>? {
        guard contains(key) else {
            return nil
        }
        guard try decodeNil(forKey: key) == false else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {
        var dictionary = Dictionary<String, Any>()
        
        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode(Array<Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }
}

extension UnkeyedDecodingContainer {
    
    mutating func decode(_ type: Array<Any>.Type) throws -> Array<Any> {
        var array: [Any] = []
        while isAtEnd == false {
            // See if the current value in the JSON array is `null` first and prevent infite recursion with nested arrays.
            if try decodeNil() {
                continue
            } else if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decode(Array<Any>.self) {
                array.append(nestedArray)
            }
        }
        return array
    }
    
    mutating func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {
        
        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}
