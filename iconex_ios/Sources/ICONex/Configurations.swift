//
//  Configurations.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation

struct Configuration {
    public enum HOST: Int {
        case main = 0
        case dev = 1
        case yeouido = 2
    }
    
    
    static var general = Configuration()
    
    var host: HOST {
        let save = UserDefaults.standard.integer(forKey: "Provider")
        if let provider = HOST(rawValue: save) {
            return provider
        } else {
            return .main
        }
    }
    var faqLink: String {
        return "https://docs.google.com/spreadsheets/d/1HiT98wqEpFgF2d98eJefQfH7xK4KPPxNDiiXg3AcJ7w/edit#gid=0"
    }
    
    static func systemCheck() -> Bool {
        var error: NSError? = nil
        #if NSHC
        IXSWrapper.systemCheck(&error)
        #endif
        return error == nil
    }
    
    static func integrityCheck() -> Bool {
        
        #if NSHC
        var initInfo = ix_init_info()
        var verifyInfo = ix_verify_info()
        initInfo.integrity_type = IX_INTEGRITY_LOCAL
        
        let ret = a106c4e13097eb3613110ee85730fc9f9(&initInfo, &verifyInfo)
        
        var copyVerify = verifyInfo
        
        if ret == 1 {
            let result = withUnsafePointer(to: &copyVerify.verify_result) {
                $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout.size(ofValue: verifyInfo.verify_result), {
                    String(cString: $0)
                })
            }
            
            if result == VERIFY_SUCC {
                return true
            }
        }
        
        return false
        #else
        return true
        #endif
    }
    
    static func debuggerCheck() -> Bool {
        #if NSHC && !DEBUG
        let result = IXSWrapper.detectDebugger()
        
        return result != 1
        #else
        return true
        #endif
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


extension Configuration.HOST {
    var name: String {
        switch self {
        case .main:
            return "Mainnet"
            
        case .dev:
            return "Testnet"
            
        case .yeouido:
            return "Yeouido (여의도)"
        }
    }
}
