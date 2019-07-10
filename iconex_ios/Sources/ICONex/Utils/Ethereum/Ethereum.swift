//
//  Ethereum.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import Web3swift
import BigInt

typealias ETHTokenResult = (name: String, symbol: String, decimal: Int)

struct Ethereum {
    
    static var provider: URL {
        switch Config.host {
        case .main:
            return URL(string: "https://eth.solidwallet.io/")!
            
        case .dev, .yeouido:
            return URL(string: "https://ropsten.infura.io")!
        }
    }
    
    static var etherScanURL: URL {
        switch Config.host {
        case .main:
            return URL(string: "https://etherscan.io/address")!
            
        case .dev, .yeouido:
            return URL(string: "https://ropsten.etherscan.io/address")!
        }
    }
    
    static var gasPrice: BigUInt? {
        guard let web3 = try? Web3.new(Ethereum.provider) else {
            return nil
        }
        guard let gasPrice = try? web3.eth.getGasPrice() else { return nil }
        Log.Debug("gasPrice: \(gasPrice)")
        return gasPrice
    }
    
    static func requestBalance(address: String) -> BigUInt? {
        guard let web3 = try? Web3.new(Ethereum.provider) else {
            return nil
        }
        
        guard let ethAddress = EthereumAddress(address) else { return nil }
        
        let result = try? web3.eth.getBalance(address: ethAddress)
        
        return result
    }
    
    static func requestETHEstimatedGas(value: BigUInt, data: Data, from: String, to: String) -> BigUInt? {
        
        guard let web3 = try? Web3.new(Ethereum.provider) else {
            return nil
        }
        
        var options = TransactionOptions.defaultOptions
        options.from = EthereumAddress(from)
        options.to = EthereumAddress(to)
        options.value = value
        
        let contract = web3.contract(Web3.Utils.coldWalletABI, at: EthereumAddress(to))
        let intermediate = contract?.method(transactionOptions: options)
        
        
        guard let estimatedGas = try? intermediate?.estimateGas(transactionOptions: nil) else {
            return nil
        }
        
        return estimatedGas
    }
    
    static func requestTokenEstimatedGas(value: BigUInt, gasPrice: BigUInt, from: String, to: String, tokenInfo: TokenInfo) -> BigUInt? {
        guard let web3 = try? Web3.new(Ethereum.provider) else {
            return nil
        }
        
        let fromAddress = EthereumAddress(from)
        let toAddress = EthereumAddress(to)
        let contractAddress = EthereumAddress(tokenInfo.contractAddress)
        
        var options = TransactionOptions.defaultOptions
        options.gasPrice = .manual(gasPrice)
        
        let tokenEstimated = web3.eth.sendERC20tokensWithKnownDecimals(tokenAddress: contractAddress!, from: fromAddress!, to: toAddress!, amount: value, transactionOptions: options)
        let estimated = try? tokenEstimated!.estimateGas(transactionOptions: nil)
        Log.Debug("estimated: \(estimated)")
        return estimated
    }
    
    static func requestSendTransaction(privateKey: String, gasPrice: BigUInt, gasLimit: BigUInt, from: String, to: String, value: BigUInt, data: Data, completion: @escaping (_ isSuccess: Bool,_ reason: Int) -> Void) {
        
        DispatchQueue.global(qos: .default).async {
            guard let web3 = try? Web3.new(Ethereum.provider) else {
                DispatchQueue.main.async {
                    completion(false, -99)
                }
                return
            }
            var options = TransactionOptions.defaultOptions
            options.gasPrice = .manual(gasPrice)
            options.gasLimit = .manual(gasLimit)
            options.from = EthereumAddress(from)

            let keystore = try! EthereumKeystoreV3(privateKey: privateKey.hexToData()!)
            let manager = KeystoreManager([keystore!])
            web3.addKeystoreManager(manager)
            
            let intermediate = web3.eth.sendETH(to: EthereumAddress(to)!, amount: value, extraData: data, transactionOptions: options)
            
            if let estimated = try? intermediate!.estimateGas(transactionOptions: nil) {
                Log.Debug("estimated: \(estimated), gasLimit: \(gasLimit)")
                if estimated > gasLimit {
                    DispatchQueue.main.async {
                        completion(false, -1)
                    }
                    return
                }
                
            } else {
                DispatchQueue.main.async {
                    completion(false, -99)
                }
                return
            }
            
            
            guard let result = try? intermediate?.send() else {
                DispatchQueue.main.async {
                    completion(false, -99)
                }
                return
            }
            
            DispatchQueue.main.async {
                Log.Debug("result: \(result)")
                if let txHash = result.transaction.txhash {
                    do {
                        try Transactions.saveTransaction(from: from, to: to, txHash: txHash, value: Tools.bigToString(value: value, decimal: 18, 18, true), type: "eth")
                    } catch {
                        Log.Debug("\(error)")
                    }
                    completion(true, 0)
                } else {
                    completion(false, -99)
                }
            }
        }
    }
    
    static func requestTokenInformation(tokenContractAddress address: String, myAddress: String, completion: @escaping (_ result: ETHTokenResult?) -> Void) {
        let contractAddress = EthereumAddress(address)
        
        DispatchQueue.global(qos: .userInitiated).async {
            
        guard let web3 = try? Web3.new(Ethereum.provider) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        guard let contract = web3.contract(Web3.Utils.erc20ABI, at: contractAddress) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        var options = TransactionOptions.defaultOptions
        options.from = EthereumAddress(myAddress)
        
            var tokenResult = ETHTokenResult("", "", 0)
            
            if let intermediate = contract.method("name", parameters: [], extraData: Data(), transactionOptions: options) {
                if let value = try? intermediate.call(transactionOptions: nil) {
                
                    tokenResult.name = value["0"] as! String
                    
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
            }
            
            if let intermediate = contract.method("symbol", parameters: [], extraData: Data(), transactionOptions: options) {
                if let value = try? intermediate.call(transactionOptions: nil) {
                
                    Log.Debug("symbol: \(value)")
                    tokenResult.symbol = value["0"] as! String
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
            }
            
            if let intermediate = contract.method("decimals", parameters: [], extraData: Data(), transactionOptions: options) {
                if let value = try? intermediate.call(transactionOptions: nil) {
                
                    Log.Debug("decimal: \(value)")
                    tokenResult.decimal = Int(value["0"] as! BigUInt)
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
            }
            DispatchQueue.main.async {
                completion(tokenResult)
            }
        }
    }
    
    static func requestTokenBalance(token: TokenInfo) -> BigUInt? {
        guard let web3 = try? Web3.new(Ethereum.provider) else {
            return nil
        }
        let ethAddress = EthereumAddress(token.contractAddress)
        
        guard let contract = web3.contract(Web3.Utils.erc20ABI, at: ethAddress) else {
            
            return nil
        }
        
        var options = TransactionOptions.defaultOptions
        let address = EthereumAddress(token.dependedAddress.add0xPrefix())
        options.from = address
        guard let value = try? contract.method("balanceOf", parameters: [address] as [AnyObject], transactionOptions: options)!.call(transactionOptions: nil) else {
            
            return nil
        }
        return value["0"] as? BigUInt
    }
    
    static func requestTokenSendTransaction(privateKey: String, from: String, to: String, tokenInfo: TokenInfo, limit: BigUInt, price: BigUInt, value: BigUInt, completion: @escaping (_ isCompleted: Bool) -> Void) {
        DispatchQueue.global(qos: .default).async {
            guard let web3 = try? Web3.new(Ethereum.provider) else {
                Log.Debug("HALT")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let fromAddress = EthereumAddress(from)
            let toAddress = EthereumAddress(to)
            let contractAddress = EthereumAddress(tokenInfo.contractAddress)
            
            let keystore = try! EthereumKeystoreV3(privateKey: privateKey.hexToData()!)
            let manager = KeystoreManager([keystore!])
            web3.addKeystoreManager(manager)
            
            var options = TransactionOptions.defaultOptions
            options.gasLimit = .manual(limit)
            options.gasPrice = .manual(price)
            
            guard let intermediate = web3.eth.sendERC20tokensWithKnownDecimals(tokenAddress: contractAddress!, from: fromAddress!, to: toAddress!, amount: value, transactionOptions: options) else {
                Log.Debug("HALT")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            if let result = try? intermediate.send() {
            
                DispatchQueue.main.async {
                    Log.Debug("success: \(String(describing: result))")
                    if let txHash = result.transaction.txhash {
                        do {
                            try Transactions.saveTransaction(from: from, to: to, txHash: txHash, value: Tools.bigToString(value: value, decimal: 18, 18, true), type: tokenInfo.parentType.lowercased(), tokenSymbol: tokenInfo.symbol.lowercased())
                        } catch {
                            Log.Debug("\(error)")
                        }
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
                
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
}

extension String {
    func add0xPrefix() -> String {
        guard self.length == 40 else { return self }
        
        if !self.hasPrefix("0x") {
            return "0x" + self
        }
        
        return self
    }
    
    func addHxPrefix() -> String {
        guard self.length == 40 else { return self }
        
        if !self.hasPrefix("hx") {
            return "hx" + self
        }
        return self
    }
}
