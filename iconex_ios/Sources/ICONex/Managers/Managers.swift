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
import Web3swift

struct Manager {
    static let wallet = WalletManager.shared
    
    static let icon = ICONManager.shared
    
    static let balance = BalanceManager.shared
}


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

extension ICONManager {
    func getStepCosts() -> ICONKit.Response.StepCosts? {
        func getStepCosts() -> ICONKit.Response.StepCosts? {
            let call = Call<Response.StepCosts>(from: CONST.governance, to: CONST.scoreGovernance, method: "getStepCosts", params: nil)
            let result = self.iconService.call(call).execute()
            
            switch result {
            case .failure(let error):
                Log("error - \(String(describing: error))")
                return nil
                
            case .success(let cost):
                Log("cost - \(cost)")
                return cost
            }
        }
    }
    
    func getMaxStepLimit() -> BigUInt? {
        let call = Call<String>(from: CONST.governance, to: CONST.scoreGovernance, method: "getMaxStepLimit", params: ["contextType": "invoke"])
        let result: Result = self.iconService.call(call).execute()
        
        guard let value = try? result.get(), let maxLimit = BigUInt(value.prefix0xRemoved(), radix: 16) else { return nil }
        Log("max - \(maxLimit)")
        return maxLimit
    }
    
    func getMinStepLimit() -> BigUInt? {
        let call = Call<String>(from: CONST.governance, to: CONST.scoreGovernance, method: "getMinStepLimit", params: nil)
        let result = self.iconService.call(call).execute()
        
        guard let min = try? result.get(), let minLimit = BigUInt(min.prefix0xRemoved(), radix: 16) else { return nil }
        Log("min - \(minLimit)")
        return minLimit
    }
    
    func getStepPrice() -> BigUInt? {
        let call = Call<String>(from: CONST.governance, to: CONST.scoreGovernance, method: "getStepPrice", params: nil)
        let result = self.iconService.call(call).execute()
        
        guard let stringPrice = try? result.get(), let stepPrice = BigUInt(stringPrice.prefix0xRemoved(), radix: 16) else { return nil }
        Log("stepPrice - \(stepPrice)")
        return stepPrice
    }
    
    func getBalance(wallet: ICXWallet) -> BigUInt? {
        let result = self.iconService.getBalance(address: wallet.address).execute()
        
        switch result {
        case .success(let balance):
            return balance
            
        case .failure(let error):
            Log("Error - \(error)")
            return nil
        }
    }
    
    func getIRCTokenInfo(walletAddress: String, contractAddress: String) -> (name: String, symbol: String, decimal: String)? {
        
        let nameCall = Call<String>(from: walletAddress, to: contractAddress, method: "name", params: nil)
        let result = self.iconService.call(nameCall).execute()
        
        guard let name = try? result.get() else {
            return nil
        }
        Log("name - \(name)")
        
        let decimalCall = Call<String>(from: walletAddress, to: contractAddress, method: "decimals", params: nil)
        let decResult = self.iconService.call(decimalCall).execute()
        
        guard let decimal = try? decResult.get() else {
            return nil
        }
        Log("decimal - \(decimal)")
        
        let symCall = Call<String>(from: walletAddress, to: contractAddress, method: "symbol", params: nil)
        let symResult = self.iconService.call(symCall).execute()
        
        guard let symbol = try? symResult.get() else {
            return nil
        }
        Log("symbol - \(symbol)")
        
        return (name: name, symbol: symbol, decimal: decimal)
    }
    
    func getIRCTokenBalance(tokenInfo: Token) -> BigUInt? {
        let call = Call<BigUInt>(from: tokenInfo.parent, to: tokenInfo.contract, method: "balanceOf", params: ["_owner": tokenInfo.parent])
        let result = self.iconService.call(call).execute()
        
        guard let balance = try? result.get() else { return nil }
        
        return balance
    }
    
    public func getIRCTokenBalance(dependedAddress: String, contractAddress: String) -> Result<BigUInt, ICError> {
        let call = Call<BigUInt>(from: dependedAddress, to: contractAddress, method: "balanceOf", params: ["_owner": dependedAddress])
        let result = self.iconService.call(call).execute()
        
        return result
    }
    
}

class BalanceManager {
    static let shared = BalanceManager()
    
    private var isWorking: Bool = false
    
    private var walletBalances = [String: BigUInt]()
    private var tokenBalances = [String: [String: BigUInt]]()
    
    private init() { }
}

extension BalanceManager {
    func getAllBalances() {
        
        guard isWorking == false else { return }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        DispatchQueue.global().async { [unowned self] in
            
            
            self.isWorking = true
            for wallet in Manager.wallet.walletList {
                if let icx = wallet as? ICXWallet {
                    if let balance = try? Manager.icon.iconService.getBalance(address: icx.address).execute().get() {
                        self.walletBalances[wallet.address] = balance
                        
                        guard let tokenList = wallet.tokens else { continue }
                        var tokenBalances = [String: BigUInt]()
                        for token in tokenList {
                            if let balance = Manager.icon.getIRCTokenBalance(tokenInfo: token) {
                                tokenBalances[token.contract] = balance
                            }
                        }
                        self.tokenBalances[wallet.address] = tokenBalances
                    }
                } else if let eth = wallet as? ETHWallet {
                    if let balance = Ethereum.requestBalance(address: eth.address.add0xPrefix()) {
                        self.walletBalances[wallet.address] = balance
                        
                        guard let tokenList = wallet.tokens else { continue }
                        var tokenBalances = [String: BigUInt]()
                        for token in tokenList {
                            if let balance = Ethereum.requestTokenBalance(token: token) {
                                tokenBalances[token.contract] = balance
                            }
                        }
                        self.tokenBalances[wallet.address] = tokenBalances
                    }
                }
            }
            DispatchQueue.main.async {
                self.isWorking = false
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
    
    func getBalance(wallet: BaseWalletConvertible) -> BigUInt? {
        if let icx = wallet as? ICXWallet, let balance = Manager.icon.getBalance(wallet: icx) {
            self.walletBalances[wallet.address] = balance
            return balance
        } else if let eth = wallet as? ETHWallet, let balance = Ethereum.requestBalance(address: eth.address) {
            self.walletBalances[wallet.address] = balance
            return balance
        } else {
            return nil
        }
    }
}

typealias ETHTokenResult = (name: String, symbol: String, decimal: Int)

struct Ethereum {
    
    static var provider: URL {
        switch Config.host {
        case .main:
            return URL(string: "https://eth.solidwallet.io/")!
            
        case .testnet, .yeouido:
            return URL(string: "https://ropsten.infura.io")!
        }
    }
    
    static var etherScanURL: URL {
        switch Config.host {
        case .main:
            return URL(string: "https://etherscan.io/address")!
            
        case .testnet, .yeouido:
            return URL(string: "https://ropsten.etherscan.io/address")!
        }
    }
    
    static var gasPrice: BigUInt? {
        guard let web3 = try? Web3.new(Ethereum.provider) else {
            return nil
        }
        guard let gasPrice = try? web3.eth.getGasPrice() else { return nil }
        Log("gasPrice: \(gasPrice)")
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
    
    static func requestTokenEstimatedGas(value: BigUInt, gasPrice: BigUInt, from: String, to: String, tokenInfo: Token) -> BigUInt? {
        guard let web3 = try? Web3.new(Ethereum.provider) else {
            return nil
        }
        
        let fromAddress = EthereumAddress(from)
        let toAddress = EthereumAddress(to)
        let contractAddress = EthereumAddress(tokenInfo.contract)
        
        var options = TransactionOptions.defaultOptions
        options.gasPrice = .manual(gasPrice)
        
        let tokenEstimated = web3.eth.sendERC20tokensWithKnownDecimals(tokenAddress: contractAddress!, from: fromAddress!, to: toAddress!, amount: value, transactionOptions: options)
        let estimated = try? tokenEstimated!.estimateGas(transactionOptions: nil)
        Log("estimated: \(String(describing: estimated))")
        return estimated
    }
    
    static func requestSendTransaction(privateKey: String, gasPrice: BigUInt, gasLimit: BigUInt, from: String, to: String, value: BigUInt, data: Data) -> (isSuccess: Bool, reason: Int) {
        
        guard let web3 = try? Web3.new(Ethereum.provider) else {
            return (false, -99)
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
            Log("estimated: \(estimated), gasLimit: \(gasLimit)")
            if estimated > gasLimit {
                return (false, -1)
            }
            
        } else {
            return (false, -99)
        }
        
        
        guard let result = try? intermediate?.send() else {
            return (false, -99)
        }
        
        Log("result: \(result)")
        if let txHash = result.transaction.txhash {
            do {
                try DB.saveTransaction(from: from, to: to, txHash: txHash, value: value.toString(decimal: 18, 18, true), type: "eth")
            } catch {
                Log("\(error)")
            }
            return (true, 0)
        } else {
            return (false, -99)
        }
    }
    
    static func requestTokenInformation(tokenContractAddress address: String, myAddress: String) -> ETHTokenResult? {
        let contractAddress = EthereumAddress(address)
        
        guard let web3 = try? Web3.new(Ethereum.provider) else {
            return nil
        }
        
        guard let contract = web3.contract(Web3.Utils.erc20ABI, at: contractAddress) else {
            return nil
        }
        
        var options = TransactionOptions.defaultOptions
        options.from = EthereumAddress(myAddress)
        
        var tokenResult = ETHTokenResult("", "", 0)
        
        if let intermediate = contract.method("name", parameters: [], extraData: Data(), transactionOptions: options) {
            if let value = try? intermediate.call(transactionOptions: nil) {
                
                tokenResult.name = value["0"] as! String
                
            } else {
                return nil
            }
        }
        
        if let intermediate = contract.method("symbol", parameters: [], extraData: Data(), transactionOptions: options) {
            if let value = try? intermediate.call(transactionOptions: nil) {
                
                Log("symbol: \(value)")
                tokenResult.symbol = value["0"] as! String
            } else {
                return nil
            }
        }
        
        if let intermediate = contract.method("decimals", parameters: [], extraData: Data(), transactionOptions: options) {
            if let value = try? intermediate.call(transactionOptions: nil) {
                
                Log("decimal: \(value)")
                tokenResult.decimal = Int(value["0"] as! BigUInt)
            } else {
                return nil
            }
        }
        return tokenResult
    }
    
    
    static func requestTokenBalance(token: Token) -> BigUInt? {
        guard let web3 = try? Web3.new(Ethereum.provider) else {
            return nil
        }
        let ethAddress = EthereumAddress(token.contract)
        
        guard let contract = web3.contract(Web3.Utils.erc20ABI, at: ethAddress) else {
            
            return nil
        }
        
        var options = TransactionOptions.defaultOptions
        let address = EthereumAddress(token.parent.add0xPrefix())
        options.from = address
        guard let value = try? contract.method("balanceOf", parameters: [address] as [AnyObject], transactionOptions: options)!.call(transactionOptions: nil) else {
            
            return nil
        }
        return value["0"] as? BigUInt
    }
    
    static func requestTokenSendTransaction(privateKey: String, from: String, to: String, tokenInfo: Token, limit: BigUInt, price: BigUInt, value: BigUInt, completion: @escaping (_ isCompleted: Bool) -> Void) {
        DispatchQueue.global(qos: .default).async {
            guard let web3 = try? Web3.new(Ethereum.provider) else {
                Log("HALT")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let fromAddress = EthereumAddress(from)
            let toAddress = EthereumAddress(to)
            let contractAddress = EthereumAddress(tokenInfo.contract)
            
            let keystore = try! EthereumKeystoreV3(privateKey: privateKey.hexToData()!)
            let manager = KeystoreManager([keystore!])
            web3.addKeystoreManager(manager)
            
            var options = TransactionOptions.defaultOptions
            options.gasLimit = .manual(limit)
            options.gasPrice = .manual(price)
            
            guard let intermediate = web3.eth.sendERC20tokensWithKnownDecimals(tokenAddress: contractAddress!, from: fromAddress!, to: toAddress!, amount: value, transactionOptions: options) else {
                Log("HALT")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            if let result = try? intermediate.send() {
                
                DispatchQueue.main.async {
                    Log("success: \(String(describing: result))")
                    if let txHash = result.transaction.txhash {
                        do {
                            try Transactions.saveTransaction(from: from, to: to, txHash: txHash, value: value.toString(decimal: 18, 18, true), type: tokenInfo.parentType.lowercased(), tokenSymbol: tokenInfo.symbol.lowercased())
                        } catch {
                            Log("\(error)")
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

// MARK: Transactions
struct Transactions {
    
    static func saveTransaction(from: String, to: String, txHash: String, value: String, type: String, tokenSymbol: String? = nil) throws {
        
        try DB.saveTransaction(from: from, to: to, txHash: txHash, value: value, type: type, tokenSymbol: tokenSymbol)
        
    }
    
    static func transactionList(address: String) -> [TransactionModel]? {
        
        return DB.transactionList(address: address)
    }
    
    static func recentTransactionList(type: String, exclude: String) -> [TransactionInfo] {
        
        var infos = [TransactionInfo]()
        
        if let models = DB.transactionList(type: type) {
            
            for model in models {
                if model.to == exclude { continue }
                var name = ""
                if let walletName = DB.findWalletName(with: model, exclude: exclude) {
                    name = walletName
                }
                
                let info = TransactionInfo(name: name, address: model.to, date: model.date, hexAmount: model.value, tokenSymbol: model.tokenSymbol)
                
                infos.append(info)
            }
            
        }
        
        return infos
    }
    
    static func updateTransactionCompleted(txHash: String) {
        DB.updateTransactionCompleted(txHash: txHash)
    }
    
}
