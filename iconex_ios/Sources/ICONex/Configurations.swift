//
//  Configurations.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation

struct Configuration {
    static var general = Configuration()
    
    var isDebug: Bool = false
    var isTestnet: Bool = false
    var faqLink: String {
        return "https://docs.google.com/spreadsheets/d/1HiT98wqEpFgF2d98eJefQfH7xK4KPPxNDiiXg3AcJ7w/edit#gid=0"
    }
    
    static func systemCheck() -> Bool {
        if Config.isDebug { return true }
        
        var error: NSError? = nil
        #if NSHC
        IXSWrapper.systemCheck(&error)
        #endif
        return error == nil
    }
    
    static func integrityCheck() -> Bool {
        if Config.isDebug { return true }
        
        var error: NSError? = nil
        #if NSHC
        IXSWrapper.intigrityCheck(&error)
        #endif
        return error == nil
    }
    
    static func debuggerCheck() -> Bool {
        if Config.isDebug { return true }
        #if NSHC
        let result = IXSWrapper.detectDebugger()
        
        return result != 1
        #else
        return true
        #endif
    }
    
    static func setDebug() {
        if Config.isDebug {
            #if NSHC
            IXSWrapper.setDebug()
            #endif
        }
    }
}

var Config = Configuration.general
