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
    
    static let exchange = ExchangeManager.shared
    
    static let iiss = PRepManager.shared
    
    static let voteList = VoteListManager.shared
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
        return DB.walletBy(address: address.add0xPrefix().lowercased(), type: type.lowercased())
    }
}

// MARK: ICONManager
class ICONManager {
    static let shared = ICONManager()
    
    private init() {}
    
    var iconService: ICONService {
        return ICONService(provider: Config.host.provider, nid: Config.host.nid)
    }
    
    var service: ICONService { return self.iconService }
    
    var stepCost: Response.StepCosts?
    var stepPrice: BigUInt?
}

extension ICONManager {
    func getStepCosts() -> Response.StepCosts? {
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
        return getBalance(address: wallet.address)
    }
    
    func getBalance(address: String) -> BigUInt? {
        let result = self.iconService.getBalance(address: address).execute()
        
        switch result {
        case .success(let balance):
            // update
            Manager.balance.updateWalletBalance(address: address, balance: balance)
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
    
    public func getIRCTokenBalance(dependedAddress: String, contractAddress: String) -> Result<BigUInt, Error> {
        let call = Call<BigUInt>(from: dependedAddress, to: contractAddress, method: "balanceOf", params: ["_owner": dependedAddress])
        let result = self.iconService.call(call).execute()
        
        switch result {
        case .success(let balance):
            Manager.balance.updateTokenBalance(address: dependedAddress, contract: contractAddress, balance: balance)
            
        case .failure:
            break
        }
        
        return result
    }
    
    
    public func sendTransaction(transaction: Transaction, privateKey: PrivateKey) throws -> Result<String, Error> {
        let signed = try SignedTransaction(transaction: transaction, privateKey: privateKey)
        
        let request = iconService.sendTransaction(signedTransaction: signed)
        let response = request.execute()
        
        return response
    }
    
    public func getTransactionResult(txHash: String) -> Response.TransactionResult? {
        let request = iconService.getTransactionResult(hash: txHash)
        let response = request.execute()
        
        switch response {
        case .success(let result):
            return result
        case .failure(let err):
            Log(err, .error)
            return nil
        }
    }
    
}

// IISS
extension ICONManager {
    func getStake(from: ICXWallet) -> PRepStakeResponse? {
        let params = ["address": from.address]
        
        let call = Call<PRepStakeResponse>(from: from.address, to: CONST.iiss, method: "getStake", params: params)
        let result = self.iconService.call(call).execute()
        
        do {
            return try result.get()
        } catch {
            Log("Error - \(error)")
            return nil
        }
    }
    
    func getStake(from: ICXWallet, _ completion: @escaping ((PRepStakeResponse?) -> Void)) {
        let params = ["address": from.address]
        
        let call = Call<PRepStakeResponse>(from: from.address, to: CONST.iiss, method: "getStake", params: params)
        self.iconService.call(call).async({ result in
            var response: PRepStakeResponse?
            do {
                response = try result.get()
            } catch {
                Log("Error - \(error)")
                response = nil
            }
            completion(response)
        })
    }
    
    func setStake(from: ICXWallet, value: BigUInt, stepLimit: BigUInt) -> CallTransaction {
        let params = ["value": value.toHexString()]
        
        let call = CallTransaction()
            .method("setStake")
            .from(from.address)
            .to(CONST.iiss)
            .nid(Manager.icon.iconService.nid)
            .stepLimit(stepLimit)
            .params(params)
        return call
    }
    
    func setDelegation(from: ICXWallet, delegations: [[String: Any]]) -> CallTransaction {
        let del = ["delegations": delegations]
        
        let call = CallTransaction()
        call.from = from.address
        call.to = CONST.iiss
        call.method("setDelegation")
        call.params(del)
        call.nid = Manager.icon.iconService.nid
        
        do {
            let estimatedStep = try Manager.icon.service.estimateStep(transaction: call).execute().get()
            call.stepLimit(estimatedStep)
            
        } catch {
            print("없다")
        }
        
        return call
    }
    
    func getDelegation(wallet: ICXWallet) -> TotalDelegation? {
        let params = ["address": wallet.address]
        
        let call = Call<TotalDelegation>(from: wallet.address, to: CONST.iiss, method: "getDelegation", params: params)
        let result = self.iconService.call(call).execute()
        
        do {
            return try result.get()
        } catch {
            Log("Error - \(error)")
            return nil
        }
    }
    
    func getDelegation(wallet: ICXWallet, _ completion: @escaping ((TotalDelegation?) -> Void)) {
        let params = ["address": wallet.address]
        
        let call = Call<TotalDelegation>(from: wallet.address, to: CONST.iiss, method: "getDelegation", params: params)
        self.iconService.call(call).async { result in
            var delegate: TotalDelegation?
            do {
                delegate = try result.get()
            } catch {
                Log("Error - \(error)")
                delegate = nil
            }
            completion(delegate)
        }
    }
    
    func claimIScore(from: ICXWallet) -> String? {
        let call = Call<String>(from: from.address, to: CONST.iiss, method: "claimIScore", params: nil)
        let result = self.iconService.call(call).execute()
        
        do {
            return try result.get()
        } catch {
            Log("Error - \(error)")
            return nil
        }
    }
    
    func queryIScore(from: ICXWallet) -> QueryIScoreResponse? {
        let params = ["address": from.address]
        
        let call = Call<QueryIScoreResponse>(from: from.address, to: CONST.iiss, method: "queryIScore", params: params)
        let result = self.iconService.call(call).execute()
        
        do {
            return try result.get()
        } catch {
            Log("Error - \(error)")
            return nil
        }
    }
    
    func getPRepInfo(from: ICXWallet, address: String) -> PRepInfoResponse? {
        let params = ["address": address]
        
        let call = Call<PRepInfoResponse>(from: from.address, to: CONST.iiss, method: "getPRep", params: params)
        let result = self.iconService.call(call).execute()
        
        do {
            return try result.get()
        } catch {
            Log("Error - \(error)")
            return nil
        }
    }
    
    func getPreps(from: ICXWallet, start: BigUInt?, end: BigUInt?) -> PRepListResponse? {
        var params = [String: String]()
        if let startIndex = start {
            params["startRanking"] = startIndex.toHexString()
        }
        if let endIndex = end {
            params["endRanking"] = endIndex.toHexString()
        }
        let call = Call<PRepListResponse>(from: from.address, to: CONST.iiss, method: "getPReps", params: params)
        let result = self.iconService.call(call).execute()
        
        do {
            return try result.get()
        } catch {
            Log("Error - \(error)")
            return nil
        }
    }
}

// MARK: BalanceManager
class BalanceManager {
    static let shared = BalanceManager()
    
    private var isWorking: Bool = false
    
    private var walletBalances = [String: BigUInt]()
    private var tokenBalances = [String: [String: BigUInt]]()
    
    private init() { }
}

extension BalanceManager {
    func getAllBalances(_ completion: (() -> Void)? = nil) {
        guard isWorking == false else { return }
        DispatchQueue.global().async { [unowned self] in
            self.isWorking = true
            for wallet in Manager.wallet.walletList {
                if let icx = wallet as? ICXWallet {
                    if let balance = try? Manager.icon.iconService.getBalance(address: icx.address).execute().get() {
                        Log("Wallet balance - \(wallet.name) , \(balance.toString(decimal: 18, 18, false))")
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
                DispatchQueue.main.async {
                    mainViewModel.noti.onNext(true)
                }
            }
            
            Manager.icon.stepCost = Manager.icon.getStepCosts()
            Manager.icon.stepPrice = Manager.icon.getStepPrice()
            Manager.iiss.getPRepInfo()
            
            DispatchQueue.main.async {
                mainViewModel.reload.onNext(true)
                self.isWorking = false
                completion?()
            }
        }
    }
    
    func getBalance(wallet: BaseWalletConvertible) -> BigUInt? {
        return walletBalances[wallet.address]
    }
    
    func calculateExchangeTotalBalance() -> [BigUInt] {
        var icxBalance: BigUInt = 0
        var ethBalance: BigUInt = 0
        
        for wallet in Manager.wallet.walletList {
            let address = wallet.address
            
            if wallet is ICXWallet {
                icxBalance += walletBalances[address] ?? 0
            } else {
                ethBalance += walletBalances[address] ?? 0
            }
        }
        
        return [icxBalance, ethBalance]
    }
    
    func getTokenBalance(address: String, contract: String) -> BigUInt {
        guard let wallet = self.tokenBalances[address] else { return 0 }
        let balance = wallet[contract] ?? 0
        
        return balance
    }
    
    func updateWalletBalance(address: String, balance: BigUInt) {
        walletBalances[address] = balance
    }
    
    func updateTokenBalance(address: String, contract: String, balance: BigUInt) {
        tokenBalances[address]?.updateValue(balance, forKey: contract)
    }
}

// MARK: PRepManager
class PRepManager {
    static let shared = PRepManager()
    
    private var walletInfo = [String: MyStakeInfo]()
    private var service: ICONManager {
        return Manager.icon
    }
    
//    private var votedPower: String = ""
    
    private init() { }
    
    func getPRepInfo() {
        DispatchQueue.global().async {
            let icxList = Manager.wallet.walletList.compactMap { $0 as? ICXWallet }
            
            var staked: BigUInt = 0
            var voted: BigUInt = 0
            
            for icx in icxList {
                guard let stake = self.service.getStake(from: icx) else { continue }
                guard let voting = self.service.getDelegation(wallet: icx) else { continue }
                guard let iscore = self.service.queryIScore(from: icx) else { continue }
                let myStake = MyStakeInfo(stake: stake.stake, votingPower: voting.votingPower, iscore: iscore.iscore)
                staked += stake.stake
                voted += voting.totalDelegated
                self.walletInfo[icx.address] = myStake
            }
            
            let percent: Float = {
                if voted == 0 {
                    return 0.0
                } else {
                    guard let stakedDecimal = staked.decimalNumber, let votedDecimal = voted.decimalNumber else {
                        return 0.0
                    }
                    
                    let result = (votedDecimal / stakedDecimal) * 100
                    return result.floatValue
                }
            }()
            
            let percentString = String(format: "%.1f", percent) + " %"
            mainViewModel.totalVotedPower.onNext(percentString)
        }
    }
    
    func votingPower(icx: ICXWallet) -> BigUInt? {
        return walletInfo[icx.address]?.votingPower
    }
    
    func stake(icx: ICXWallet) -> BigUInt? {
        return walletInfo[icx.address]?.stake
    }
    
    func iscore(icx: ICXWallet) -> BigUInt? {
        return walletInfo[icx.address]?.iscore
    }
}

// MARK: ExchangeManager
class ExchangeManager {
    static let shared = ExchangeManager()
    
    var exchangeList = "icxeth,icxbtc,icxusd,ethusd,ethbtc,etheth,btcicx,ethicx,icxicx"
    var currentExchange: String = "usd"
    var exchangeInfoList = [String: ExchangeInfo]()
    
    private init () { }
    
    func getExchangeList() {
        DispatchQueue.global().async {
            var tracker: Tracker {
                switch Config.host {
                case .main:
                    return Tracker.main()
                    
                case .euljiro:
                    return Tracker.euljiro()
                    
                case .yeouido:
                    return Tracker.yeouido()
                    
                default:
                    return Tracker.localTest()
                }
            }
            
            guard let data = tracker.exchangeData(list: self.exchangeList) else { return }
            
            do {
                let decoder = JSONDecoder()
                let list = try decoder.decode([ExchangeInfo].self, from: data)
                
                for info in list {
                    self.exchangeInfoList[info.tradeName] = info
                }
            } catch {
                Log("Error - \(error)")
            }
        }
    }
    
    func addToken(_ symbol: String) {
        let lowerCased = symbol.lowercased()
        var expected = "\(lowerCased)eth"
        if !exchangeList.contains(expected) {
            exchangeList.append("," + expected)
        }
        expected = "\(lowerCased)btc"
        if !exchangeList.contains(expected) {
            exchangeList.append("," + expected)
        }
        expected = "\(lowerCased)usd"
        if !exchangeList.contains(expected) {
            exchangeList.append("," + expected)
        }
    }
}

typealias ETHTokenResult = (name: String, symbol: String, decimal: Int)

struct Ethereum {
    
    static var provider: URL {
        switch Config.host {
        case .main:
            return URL(string: "https://eth.solidwallet.io/")!
            
//        case .testnet, .yeouido:
        default:
            return URL(string: "https://ropsten.infura.io")!
        }
    }
    
    static var etherScanURL: URL {
        switch Config.host {
        case .main:
            return URL(string: "https://etherscan.io/address")!
            
//        case .testnet, .yeouido:
        default:
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
        
        let intermediate = web3.eth.sendETH(to: EthereumAddress(to)!, amount: value, extraData: data, transactionOptions: options)
        
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
    
    static func requestSendTransaction(privateKey: String, gasPrice: BigUInt, gasLimit: BigUInt, from: String, to: String, value: BigUInt, data: Data? = nil) -> (isSuccess: Bool, reason: Int) {
        
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
        
        let intermediate = web3.eth.sendETH(to: EthereumAddress(to)!, amount: value, extraData: data ?? Data(), transactionOptions: options)
        
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
