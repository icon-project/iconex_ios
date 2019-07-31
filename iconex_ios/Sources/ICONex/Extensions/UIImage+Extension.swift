//
//  UIImage+Extension.swift
//  iconex_ios
//
//  Created by a1ahn on 19/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit

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
