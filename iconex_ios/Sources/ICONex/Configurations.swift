//
//  Configurations.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation

struct Configuration {
    public enum HOST {
        case main
        case dev
        case local
    }
    
    
    static var general = Configuration()
    
    var host: HOST = .main
    var faqLink: String {
        return "https://docs.google.com/spreadsheets/d/1HiT98wqEpFgF2d98eJefQfH7xK4KPPxNDiiXg3AcJ7w/edit#gid=0"
    }
    
    static func systemCheck() -> Bool {
        var error: NSError? = nil
        #if NSHC
//        IXSWrapper.systemCheck(&error)
        #endif
        return error == nil
    }
    
    static func integrityCheck() -> Bool {
        var error: NSError? = nil
        #if NSHC
//        IXSWrapper.intigrityCheck(&error)
        Log.Debug("integrity - \(error?.domain)")
        #endif
        return error == nil
    }
    
    static func debuggerCheck() -> Bool {
        #if NSHC
//        let result = IXSWrapper.detectDebugger()
        
//        return result != 1
        #endif
        
        return true
    }
    
    static func setDebug() {
    #if DEBUG
        #if NSHC
        IXSWrapper.setDebug()
        #endif
    #endif
    }
}

var Config = Configuration.general
