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

class Manager {
    static let sharedInstance = Manager()
    
    private init() {}
    
    var iconService: ICONService {
        return ICONService(provider: Config.host.provider, nid: Config.host.nid)
    }
}

// MARK: Managing ICX wallets
extension Manager {
    
}
