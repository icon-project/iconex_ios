//
//  Communicator.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import Foundation
import Alamofire
import BigInt

enum ICONClientState {
    case new, doing, done, failed
}

typealias ICXResult = (_ result: IXJSONResponse?) -> Void

@available(*, deprecated)
class ICXClient: Operation {
    
    var wallet: ICXWallet?
    var address: String?
    var state: ICONClientState = .new
    private var request: IXRequestConvertible?
    private var handler: (ICXResult) = { balance in }
    
    init(wallet: ICXWallet) {
        self.wallet = wallet
    }
    
    init(address: String) {
        self.address = address
    }
    
    @discardableResult
    func requestBalance(completionHandler: @escaping ICXResult) -> ICXClient {
        
        state = .doing
        self.handler = completionHandler
        
        var address = ""
        if let wallet = self.wallet {
            address = wallet.address!
        } else if let adr = self.address {
            address = adr
        }
        
        self.request = ICON.V2.BalanceRequest(id: getID(), address: address)
        
        return self
    }
    
    @discardableResult
    func requestTransactionHistory(next: Int, completionHandler: @escaping ICXResult) -> ICXClient {
        state = .doing
        self.handler = completionHandler
        
        var address = ""
        if let wallet = self.wallet {
            address = wallet.address!
        } else if let adr = self.address {
            address = adr
        }
        
        self.request = ICON.V2.TransactionHistoryRequest(address: address, next: next)
        
        return self
    }
    
    func fetch() {
        guard let request = self.request else {
            self.handler(nil)
            return
        }
        
        Alamofire.request(request).responseJSON(completionHandler: { response in
            let result = IXJSONResponse()
            result.response = response.response
            result.request = request
            result.error = response.error
            result.data = response.data
            
            switch response.result {
            case .success:
                guard case let value as [String: Any] = response.result.value else {
                    return
                }
                self.state = .done
                result.value = value
                
            case .failure:
                self.state = .failed
            }
            
            self.handler(result)
        })
    }
    
    override func main() {
        fetch()
    }
}

@available(*, deprecated)
class EthereumClient: Operation {
    
    var wallet: ETHWallet?
    var address: String?
    var state: ICONClientState = .new
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
