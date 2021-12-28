//
//  WalletLoader.swift
//  iconex_ios
//
//  Created by a1ahn on 07/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation

enum LoaderType {
    case wallet, bundle, privateKey
}

class WalletLoader {
    var type: LoaderType {
        if keystore != nil {
            return .wallet
        }
        if bundle != nil {
            return .bundle
        }
        
        return .privateKey
    }
    
    var keystore: ICONKeystore?
    var password: String?
    var bundle: WalletBundleList?
    var privateKeyHexString: String?
    var name: String?
    
    init(keystore: ICONKeystore, password: String) {
        self.keystore = keystore
        self.password = password
    }
    
    init(bundle: WalletBundleList, password: String) {
        self.bundle = bundle
        self.password = password
    }
    
    init(privateKey: String) {
        self.privateKeyHexString = privateKey
    }
    
    var value: Any? {
        if let ks = keystore {
            return ks
        } else if let bd = bundle {
            return bd
        } else if let prk = privateKeyHexString {
            return prk
        } else {
            return nil
        }
    }
}
