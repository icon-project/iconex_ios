//
//  BundleExport.swift
//  iconex_ios
//
//  Created by a1ahn on 04/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import ICONKit

class BundleExport {
    var bundles: [(BaseWalletConvertible, String)]?
    var password: String?
    
    func export() -> WalletBundleList? {
        guard let walletList = bundles, let pwd = password else { return nil }
        
        var exportList = WalletBundleList()
        for item in walletList {
            let wallet = item.0
            let prvString = item.1
            let prv = PrivateKey(hex: Data(hex: prvString))
            if let icx = wallet as? ICXWallet {
                do {
                    let newKeystore = try ICXWallet.generateICXKeystore(prv, password: pwd)
                    let newWallet = ICXWallet(name: icx.name, keystore: newKeystore, created: icx.created)
                    newWallet.tokens = wallet.tokens
                    let walletBundle = newWallet.exportBundle()
                    exportList.append([newWallet.address: walletBundle])
                } catch {
                    Log("Error - \(error)")
                    continue
                }
            } else if let eth = wallet as? ETHWallet {
                do {
                    let newKeystore = try ETHWallet.generateETHKeyStore(privateKey: prv, password: pwd)
                    let newWallet = ETHWallet(name: eth.name, keystore: newKeystore, created: eth.created)
                    newWallet.tokens = wallet.tokens
                    let walletBundle = newWallet.exportBundle()
                    exportList.append([newWallet.address.add0xPrefix(): walletBundle])
                } catch {
                    Log("Error - \(error)")
                    continue
                }
            }
        }
        
        return exportList
    }
}
