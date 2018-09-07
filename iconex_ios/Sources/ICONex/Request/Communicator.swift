//
//  Communicator.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import Alamofire
import BigInt

enum ClientState {
    case new, doing, done, failed
}

@available(*, deprecated)
class EthereumClient: Operation {
    
    var wallet: ETHWallet?
    var address: String?
    var state: ClientState = .new
    private var handler: ((_ value: BigUInt?, _ tokenValue: [String: BigUInt]?) -> Void)!
    
    init(wallet: ETHWallet) {
        self.wallet = wallet
    }
    
    init(address: String) {
        self.address = address
    }
    
    @discardableResult
    func requestBalance(completionHandler: @escaping ((_ etherValue: BigUInt?, _ tokenValue: [String: BigUInt]?) -> Void)) -> EthereumClient {
        self.handler = completionHandler
        
        return self
    }
    
    func fetch() {
        var address = ""
        if let wallet = self.wallet {
            address = wallet.address!
        } else if let adr = self.address {
            address = adr
        }
        if let balance = Ethereum.requestBalance(address: address) {
            var tokenValue = [String: BigUInt]()
            
            if let wallet = self.wallet, let tokens = wallet.tokens {
                for token in tokens {
                    guard let balance = Ethereum.requestTokenBalance(token: token) else {
                        continue
                    }
                    tokenValue[token.contractAddress] = balance
                }
            }
            
            self.handler(balance, tokenValue.count == 0 ? nil : tokenValue)
        } else {
            self.handler(nil, nil)
        }
    }
    
    override func main() {
        fetch()
    }
}
