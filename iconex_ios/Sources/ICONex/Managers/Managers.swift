//
//  Managers.swift
//  iconex_ios
//
//  Created by a1ahn on 11/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import ICONKit
import BigInt

// MARK: WalletManager
class WalletManager {
    static let shared = WalletManager()
    
    private init() {}
    
    var walletList: [BaseWalletConvertible] {
        return DB.loadWallets()
    }
    
    var types: [String] {
        return DB.walletTypes()
    }
}

extension WalletManager {
    func walletBy(address: String, type: String) -> BaseWalletConvertible? {
        return DB.walletBy(address: address.lowercased(), type: type.lowercased())
    }
    
}




// MARK: ICONManager
class ICONManager {
    static let shared = ICONManager()
    
    private init() {}
    
    var iconService: ICONService {
        return ICONService(provider: Config.host.provider, nid: Config.host.nid)
    }
    
}
