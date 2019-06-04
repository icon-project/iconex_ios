//
//  BalanceManager.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import BigInt
import ICONKit

class WalletBalanceOperation {
    lazy var loadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Balance.Queue"
        queue.maxConcurrentOperationCount = 1
        
        return queue
    }()
}

class BalanceManager {
    static let shared = BalanceManager()
    
    
    private let balanceOperation = WalletBalanceOperation()
    private var _queued = Set<String>()
    
    var isBalanceLoadCompleted: Bool {
        return _queued.count == 0
    }
    var isBalanceEmpty: Bool {
        return walletBalanceList.count == 0
    }
    
    var walletBalanceList = [String: BigUInt]()
    var tokenBalanceList = [String: [String: BigUInt]]()
    
    func getTotalBalances() -> BigUInt? {
        var totalBalances = [BigUInt]()
        for walletInfo in WManager.walletInfoList {
            let wallet = WManager.loadWalletBy(info: walletInfo)!
            guard let balance = Balance.walletBalanceList[wallet.address!] else {
                continue
            }
            
            guard let exchanged = Tools.balanceToExchange(balance, from: wallet.type.rawValue, to: Exchange.currentExchange, belowDecimal: Exchange.currentExchange == "usd" ? 2 : 4, decimal: wallet.decimal), let exc = Tools.stringToBigUInt(inputText: exchanged) else {
                continue
            }
            
            totalBalances.append(exc)
            
            if wallet.type == .eth {
                let eth = wallet as! ETHWallet
                guard let tokens = eth.tokens else { continue }
                for token in tokens {
                    guard let tokenBalances = Balance.tokenBalanceList[token.dependedAddress.add0xPrefix()] else { continue }
                    guard let balance = tokenBalances[token.contractAddress] else { continue }
                    guard let exchanged = Tools.balanceToExchange(balance, from: token.symbol.lowercased(), to: Exchange.currentExchange, belowDecimal: Exchange.currentExchange == "usd" ? 2 : 4, decimal: token.decimal), let exc = Tools.stringToBigUInt(inputText: exchanged) else { continue }
                    totalBalances.append(exc)
                }
            }
        }
        
        return totalBalances.reduce(0, +)
    }
    
    func getBalance(wallet: BaseWalletConvertible, completionHandler: @escaping (_ isSuccess: Bool) -> Void) {
        
        if wallet.type == .icx {
            if let address = wallet.address  {
                
                let request = WManager.service.getBalance(address: address)
                let result = request.execute()
                switch result {
                case .success(let balance):
                    self.walletBalanceList[wallet.address!.add0xPrefix().lowercased()] = balance
                    
                case .failure(let error):
                    Log.Debug("Error - \(error)")
                }
                completionHandler(true)
            }
        } else if wallet.type == .eth {
            let client = EthereumClient(wallet: wallet as! ETHWallet)
            
            client.requestBalance { (optionalValue, _) in
                guard let value = optionalValue else {
                    completionHandler(false)
                    return
                }
                
                self.walletBalanceList[wallet.address!.add0xPrefix().lowercased()] = value
                completionHandler(true)
                }.fetch()
        }
    }
    
    func getWalletsBalance() {
        guard self._queued.isEmpty, isBalanceLoadCompleted == true else { return }
        
        DispatchQueue.global().async {
            for info in WManager.walletInfoList {
                guard let wallet = WManager.loadWalletBy(info: info), let address = wallet.address else { continue }
                if self._queued.contains(address) { continue }
                
                self._queued.insert(address)
                if info.type == .icx {
                    
                    if wallet.__rawData != nil {
                        
                        let result = WManager.service.getBalance(address: address).execute()
                        
                        switch result {
                        case .success(let balance):
                            self.walletBalanceList[wallet.address!.lowercased()] = balance
                            
                        case .failure(let error):
                            Log.Debug("Error - \(error)")
                        }
                        
                        guard let tokens = wallet.tokens else { return }
                        
                        var tokenBalances = [String: BigUInt]()
                        for token in tokens {
                            let result = WManager.getIRCTokenBalance(tokenInfo: token)
                            
                            if let balance = result {
                                tokenBalances[token.contractAddress.lowercased()] = balance
                            }
                        }
                        self.tokenBalanceList[wallet.address!.lowercased()] = tokenBalances
                        
                        self._queued.remove(address)
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "kNotificationBalanceListDidChanged"), object: nil, userInfo: nil)
                        }
                    } else {
                        self._queued.remove(address)
                    }
                } else if info.type == .eth {
                    guard let wallet = WManager.loadWalletBy(info: info) else { continue }
                    let client = EthereumClient(wallet: wallet as! ETHWallet)
                    
                    client.requestBalance { (ethValue, tokenValues) in
                        
                        if let value = ethValue {
                            self.walletBalanceList[wallet.address!.lowercased()] = value
                        }
                        
                        if let tokens = tokenValues {
                            self.tokenBalanceList[wallet.address!.add0xPrefix().lowercased()] = tokens
                        }
                        
                        self._queued.remove(address)
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "kNotificationBalanceListDidChanged"), object: nil, userInfo: nil)
                        }
                    }
                    self.balanceOperation.loadQueue.addOperation(client)
                }
            }
        }
    }
    
}

let Balance = BalanceManager.shared
