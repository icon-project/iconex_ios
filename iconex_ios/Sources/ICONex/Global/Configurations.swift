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
        case euljiro = 1
        case yeouido = 2
        #if DEBUG
        case localTest
        #endif
        
        var provider: String {
            switch self {
            case .main:
                return "https://ctz.solidwallet.io/api/v3"
                
            case .euljiro:
                return "https://test-ctz.solidwallet.io/api/v3"
                
            case .yeouido:
                return "https://bicon.net.solidwallet.io/api/v3"
                
            default:
                return "http://20.20.7.156:9000/api/v3"
            }
        }
        
        var nid: String {
            switch self {
            case .main:
                return "0x1"
                
            case .euljiro:
                return "0x2"
                
            case .yeouido:
                return "0x3"
                
            default:
                return "0x3"
            }
        }
    }
    
    
    static var general = Configuration()
    
    var host: HOST {
        #if DEBUG
        return .euljiro
        #else
        let save = UserDefaults.standard.integer(forKey: "Provider")
        if let provider = HOST(rawValue: save) {
            return provider
        } else {
            return .main
        }
        #endif
    }
    var faqLink: String {
        return "https://docs.google.com/spreadsheets/d/1HiT98wqEpFgF2d98eJefQfH7xK4KPPxNDiiXg3AcJ7w/edit#gid=0"
    }
    
    static func systemCheck() -> Bool {
        #if !DEBUG
        var patternInfo:UnsafeMutablePointer<ix_detected_pattern>?
        let ret = a3c76b59d787bed13ac3766dd1e003fdc(&patternInfo) //ix_sysCheckStart(&patternInfo)
        
        if ret != 1 {
            return false
        } else {
            let pattern:iXDetectedPattern = iXInfoUtil.convertDetectedPattern(patternInfo)
            let jbCode:String = pattern.pattern_type_id;
            
            if jbCode.isEmpty == false {
                if jbCode == "0000" {
                    
                    return true
                }
                else {
                    return false
                }
            }
        }
        return true
        #endif
        return true
    }
    
    static func integrityCheck() -> Bool {
        
        #if !DEBUG
        var isRet:Bool = true
        
        // version : 1.2.1
        var initInfo = ix_init_info()
        var verifyInfo = ix_verify_info()
        
        initInfo.integrity_type = IX_INTEGRITY_LOCAL
        
        let ret = a106c4e13097eb3613110ee85730fc9f9(&initInfo, &verifyInfo) // ix_integrityCheck(&initInfo, &verifyInfo)
        let info:iXVerifyInfo = iXInfoUtil.convertVerifyInfo(&verifyInfo)
        
        if ret != 1
        {
            isRet = false;
        }
        else
        {
            if info.verify_result == VERIFY_SUCC
            {
                isRet = true;
            }
            else
            {
                isRet = false;
            }
        }
        
        return isRet;
        #else
        return true
        #endif
    }
    
    static func debuggerCheck() -> Bool {
        #if !DEBUG
        return f16fc676040b6d2ee392956bfee0fcbd() != 1
        #else
        return true
        #endif
    }
    
    static func setDebug() {
    #if DEBUG
        #if NSHC
//        IXSWrapper.setDebug()
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
            
        case .euljiro:
            return "Euljiro (을지로)"
            
        case .yeouido:
            return "Yeouido (여의도)"
            
        default:
            return "내부 테스트"
        }
    }
}
