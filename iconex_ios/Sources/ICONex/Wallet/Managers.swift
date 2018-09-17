//
//  Managers.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation
import BigInt
import RealmSwift
import web3swift
import ICONKit

typealias WalletBundleItem = (name: String, privKey: String, type: COINTYPE)

enum HandlerStatus {
    case progressing
    case completed
}

class WalletManager {
    
    static let sharedInstance = WalletManager()
    
    public var service: ICONService {
        switch Config.host {
        case .main:
            return ICONService(provider: "https://wallet.icon.foundation", nid: "0x1")
            
        case .dev:
            return ICONService(provider: "https://testwallet.icon.foundation", nid: "0x2")
            
        case .local:
            return ICONService(provider: "http://13.209.103.183:9000", nid: "0x3")
        }
    }
    
    private init () {
        loadWalletList()
        DB.importLocalTokenList()
    }
    private let balanceOperation = WalletBalanceOperation()
    private var _queued = Set<String>()
    
    var isBalanceLoadCompleted: Bool {
        return _queued.count == 0
    }
    var walletInfoList = [WalletInfo]()
    var walletBalanceList = [String: BigUInt]()
    var tokenBalanceList = [String: [String: BigUInt]]()
    
    func getTotalBalances() -> Double {
        var totalBalances = [Double]()
        for walletInfo in walletInfoList {
            let wallet = WManager.loadWalletBy(info: walletInfo)!
            guard let balance = WManager.walletBalanceList[wallet.address!] else {
                continue
            }
            
            guard let exchanged = Tools.balanceToExchange(balance, from: wallet.type.rawValue, to: EManager.currentExchange, belowDecimal: EManager.currentExchange == "usd" ? 2 : 4, decimal: wallet.decimal) else {
                continue
            }
            
            guard let dValue = Double(exchanged) else {
                continue
            }
            
            totalBalances.append(dValue)
            
            if wallet.type == .eth {
                let eth = wallet as! ETHWallet
                guard let tokens = eth.tokens else { continue }
                for token in tokens {
                    guard let tokenBalances = WManager.tokenBalanceList[token.dependedAddress] else { continue }
                    guard let balance = tokenBalances[token.contractAddress] else { continue }
                    guard let exchanged = Tools.balanceToExchange(balance, from: token.symbol.lowercased(), to: EManager.currentExchange, belowDecimal: EManager.currentExchange == "usd" ? 2 : 4, decimal: token.decimal) else { continue }
                    guard let excD = Double(exchanged) else { continue }
                    totalBalances.append(excD)
                }
            }
        }
        
        return totalBalances.reduce(0, +)
    }
    
    var countOfWalletType: Int {
        return DB.walletTypes().count
    }
    
    let userPath = ""
    
    func loadWalletList() {
        walletInfoList.removeAll()
        do {
            let realm = try Realm()
            
            let list = realm.objects(WalletModel.self).sorted(byKeyPath: "createdDate").reversed()
            
            for walletModel in list {
                
                let wallet = WalletInfo(model: walletModel)
                
                walletInfoList.append(wallet)
                
            }
            
        } catch {
            Log.Debug("Get wallet list Error: \(error)")
        }
    }
    
    func loadWalletBy(info: WalletInfo) -> BaseWalletConvertible? {
        guard var wallet = DB.walletBy(info: info) else { return nil }
        wallet.balance = WManager.walletBalanceList[info.address]
        return wallet
    }
    
    func loadWalletBy(address: String, type: COINTYPE) -> BaseWalletConvertible? {
        guard var wallet = DB.walletBy(address: address, type: type) else { return nil }
        wallet.balance = WManager.walletBalanceList[address]
        return wallet
    }
    
    private func getWalletInfo(alias: String) throws -> Data {
        var path = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        path = path.appendingPathComponent(alias)
        return try Data(contentsOf: path)
    }
    
    func getBalance(wallet: BaseWalletConvertible, completionHandler: @escaping (_ isSuccess: Bool) -> Void) {
        
        if wallet.type == .icx {
            if let address = wallet.address {

                let result = self.service.getBalance(address: address)
                
                switch result {
                case .success(let balance):
                    self.walletBalanceList[wallet.address!] = balance
                    
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
                
                self.walletBalanceList[wallet.address!] = value
                completionHandler(true)
            }.fetch()
        }
    }
    
    func getWalletsBalance() {
        for info in self.walletInfoList {
            guard let wallet = WManager.loadWalletBy(info: info), let address = wallet.address else { continue }
            if _queued.contains(address) { continue }
            
            _queued.insert(address)
            if info.type == .icx {
                
                if let data = wallet.__rawData, let iconWallet = ICON.Wallet(rawData: data) {
                    
                    let result = WManager.service.getBalance(wallet: iconWallet)
                    
                    switch result {
                    case .success(let balance):
                        self.walletBalanceList[wallet.address!] = balance
                        
                    case .failure(let error):
                        Log.Debug("Error - \(error)")
                    }
                    
                    guard let tokens = wallet.tokens else { return }
                    
                    var tokenBalances = [String: BigUInt]()
                    for token in tokens {
                        let result = self.getIRCTokenBalance(tokenInfo: token)
                        
                        if let balance = result {
                            tokenBalances[token.contractAddress] = balance
                        }
                    }
                    self.tokenBalanceList[wallet.address!] = tokenBalances
                    
                    self._queued.remove(address)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "kNotificationBalanceListDidChanged"), object: nil, userInfo: nil)
                    
                } else {
                    self._queued.remove(address)
                }
            } else if info.type == .eth {
                guard let wallet = WManager.loadWalletBy(info: info) else { continue }
                let client = EthereumClient(wallet: wallet as! ETHWallet)
                
                client.requestBalance { (ethValue, tokenValues) in
                    
                    if let value = ethValue {
                        self.walletBalanceList[wallet.address!] = value
                    }
                    
                    if let tokens = tokenValues {
                        self.tokenBalanceList[wallet.address!] = tokens
                    }
                    
                    self._queued.remove(address)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "kNotificationBalanceListDidChanged"), object: nil, userInfo: nil)
                }
                balanceOperation.loadQueue.addOperation(client)
            }
        }
    }
    
    func canSaveWallet(alias: String) -> Bool {
        let realm = try! Realm()
        
        let list = realm.objects(WalletModel.self).filter { $0.name == alias }
        
        if list.count > 0 {
            return false
        }
        
        return true
    }
    
    func canSaveWallet(address: String) -> Bool {
        let realm = try! Realm()
        
        let wallet = realm.objects(WalletModel.self).filter( { $0.address.lowercased() == address.lowercased() })
        if wallet.count > 0 {
            return false
        }
        
        return true
    }
    
    func changeWalletName(former: String, newName: String) throws -> Bool {
        return try DB.changeWalletName(former: former, newName:newName)
    }
    
    func changeWalletPassword(wallet: BaseWalletConvertible, old: String, new: String) throws -> Bool {
        return try DB.changeWalletPassword(wallet: wallet, oldPassword: old, newPassword: new)
    }
    
    @discardableResult
    func deleteWallet(wallet: BaseWalletConvertible) -> Bool {
        do {
            let result = try DB.deleteWallet(wallet: wallet)
            WManager.loadWalletList()
            
            return result
        } catch {
            Log.Debug("\(error)")
            return false
        }
    }
    
    func walletTypes() -> [String] {
        return DB.walletTypes()
    }
    
    func tokenTypes() -> [TokenInfo] {
        return DB.allTokenList()
    }
    
    func coinInfoListBy(coin: COINTYPE) -> CoinInfo? {
        return DB.walletListBy(coin: coin)
    }
    
    func coinInfoListBy(token: TokenInfo) -> CoinInfo? {
        return DB.walletListBy(token: token)
    }
}

extension WalletManager {
    public func getIRCTokenInfo(walletAddress: String, contractAddress: String, completion: @escaping (((name: String, symbol: String, decimal: String)?) -> ())) {
        
        DispatchQueue.global().async {
            let result = self.service.getScoreAPI(address: contractAddress)
            
            if let api = result.value {
                let list = api.result!
                let hasName = list.filter { $0.type == "function" && $0.name == "name" }.first
                let hasDecimal = list.filter { $0.type == "function" && $0.name == "decimals" }.first
                let hastotalSupply = list.filter { $0.type == "function" && $0.name == "totalSupply" }.first
                if (hasName != nil && hasDecimal != nil && hastotalSupply != nil) {
                    let result = self.service.call(from: walletAddress, to: contractAddress, dataType: "call", method: "name")
                    
                    guard let name = result.value as? String else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                    Log.Debug("name - \(name)")
                    
                    let decimals = self.service.call(from: walletAddress, to: contractAddress, dataType: "call", method: "decimals")
                    guard let decimal = decimals.value as? String else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                    Log.Debug("decimal - \(decimal)")
                    
                    let symbols = self.service.call(from: walletAddress, to: contractAddress, dataType: "call", method: "symbol")
                    guard let symbol = symbols.value as? String else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                    Log.Debug("symbol - \(symbol)")
                    
                    DispatchQueue.main.async {
                        completion((name: name, symbol: symbol, decimal: decimal))
                    }
                    
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    public func getIRCTokenBalance(tokenInfo: TokenInfo) -> BigUInt? {
        let service = WManager.service
        
        let result = service.call(from: tokenInfo.dependedAddress, to: tokenInfo.contractAddress, dataType: "call", method: "balanceOf", params: ["_owner": tokenInfo.dependedAddress])
        
        switch result {
        case .success(let callResult):
            guard let balance = callResult as? String else { return nil }
            return BigUInt(balance.prefix0xRemoved(), radix: 16)
            
        case .failure(let error):
            Log.Debug("error - \(error)")
            
        }
        
        return nil
    }
    
}

let WManager = WalletManager.sharedInstance

// MARK: Wallet Creator

class WalletCreator {
        
    static let sharedInstance = WalletCreator()
    
    private init() {}
    
    var newType: COINTYPE?
    var newPrivateKey: String?
    var newAlias: String?
    var newWallet: BaseWalletConvertible?
    var newBundle: [[String: WalletExportBundle]]?
    var importStyle: Int = 0
    
    func createWallet(alias: String, password: String, completion: @escaping () -> Void) throws {
        guard let coinType = newType else {
            throw IXError.invalidCoinType
        }
        
        self.newAlias = alias
        
        switch coinType {
        case .icx:
            let newWallet = ICXWallet(alias: alias)
            let icxPrv = newWallet.generatePrivateKey()
            
            self.newPrivateKey = icxPrv
            
            _ = try newWallet.generateICXKeyStore(privateKey: icxPrv, password: password)
            self.newWallet = newWallet
            completion()
            
        case .eth:
            let newWallet = ETHWallet(alias: alias)
            try newWallet.generateETHKeyStore(password: password)
            self.newWallet = newWallet
            
            self.newPrivateKey = try newWallet.extractETHPrivateKey(password: password)
            
            completion()
            break
            
        default:
            break
        }
    }
    
    func createSwapWallet(alias: String, password: String, privateKey: String) throws {
        guard newType != nil else {
            throw IXError.invalidCoinType
        }
        
        self.newAlias = alias
        
        let newWallet = ICXWallet(alias: alias)
        self.newPrivateKey = privateKey
        
        _ = try newWallet.generateICXKeyStore(privateKey: privateKey, password: password)
        self.newWallet = newWallet
    }
    
    func importWallet(alias: String, password: String, completion: @escaping () -> Void) throws {
        guard let coinType = newType else {
            throw IXError.invalidCoinType
        }
        
        self.newAlias = alias
        
        switch coinType {
        case .icx:
            guard let icxPrv = newPrivateKey else {
                throw IXError.emptyPrivateKey
            }
            
            let newWallet = ICXWallet(alias: alias)
            
            try newWallet.generateICXKeyStore(privateKey: icxPrv, password: password)
            
            try newWallet.saveICXWallet()
            
            completion()
            
        case .eth:
            guard let ethPrv = newPrivateKey else {
                throw IXError.emptyPrivateKey
            }
            
            let newWallet = ETHWallet(alias: alias)
            try newWallet.generateETHKeyStore(privateKey: ethPrv, password: password)
            try newWallet.saveETHWallet()
            
            completion()
            
            break
            
        default:
            break
        }
    }
    
    func checkWalletBundle(url:URL) -> Bool {
        do {
            let content = try Data(contentsOf: url)
            
            let decoder = JSONDecoder()
            let list = try decoder.decode([[String: WalletExportBundle]].self, from: content)
            newBundle = list
            
            return true
        } catch {
            return false
        }
    }
    
    func validateBundlePassword(password: String) -> Bool {
        let item = newBundle!.first!
        let address = item.keys.first!
        let bundle = item[address]!
        let data = bundle.priv.data(using: .utf8)!
        do {
            if bundle.type == "icx" {
                guard let icx = ICXWallet(alias: "temp", from: data) else { return false }
                newPrivateKey = try icx.extractICXPrivateKey(password: password)
            } else if bundle.type == "eth" {
                let eth = ETHWallet(alias: "temp", from: data)
                newPrivateKey = try eth.extractETHPrivateKey(password: password)
            }
            
            return true
        } catch {
            Log.Debug("error - \(error)")
            
            return false
        }
    }
    
    func saveBundle() {
        guard let bundle = newBundle else { return }
        
        for item in bundle {
            guard let keyAddress = item.keys.first, let value = item.values.first else {
                continue
            }
            
            if !WManager.canSaveWallet(address: keyAddress) {
                Log.Debug("duplicated address \(keyAddress)")
                continue
            }
            if !WManager.canSaveWallet(alias: value.name) {
                Log.Debug("duplicated name \(value.name)")
                continue
            }
            
            let data = value.priv.data(using: .utf8)!
            Log.Debug(value.priv)
            do {
                switch value.type {
                case "icx":
                    guard let icxWallet = ICXWallet(alias: value.name, from: data) else { continue }
                    try icxWallet.saveICXWallet()
                    Log.Debug("Save ICX wallet which was named as \"\(value.name)\"")
                    
                case "eth":
                    let ethWallet = ETHWallet(alias: value.name, from: data)
                    if let tokens = value.tokens {
                        var tokenList = [TokenInfo]()
                        for token in tokens {
                            let tokenInfo = TokenInfo(name: token.name, defaultName: token.defaultName, symbol: token.symbol, decimal: token.decimals, defaultDecimal: token.defaultDecimals, dependedAddress: ethWallet.address!, contractAddress: token.address, parentType: "eth")
                            tokenList.append(tokenInfo)
                        }
                        ethWallet.tokens = tokenList.count > 0 ? tokenList : nil
                    }
                    try ethWallet.saveETHWallet()
                    Log.Debug("Save ETH wallet which was named as \"\(value.name)\"")
                    
                default:
                    break
                }
            } catch {
                Log.Debug(error)
                continue
            }
        }
        
        WManager.loadWalletList()
    }
    
    func validateKeystore(urlOfData: URL) throws -> (ICON.Keystore, COINTYPE) {
        let content = try Data(contentsOf: urlOfData)
        Log.Debug("content - \(String(data: content, encoding: .utf8))")
        let decoder = JSONDecoder()
        
        let keystore = try decoder.decode(ICON.Keystore.self, from: content)
        
        if keystore.coinType != nil || keystore.address.hasPrefix("hx") {
            return (keystore, .icx)
        } else {
            return (keystore, .eth)
        }
    }
    
    func validateICXPrivateKey() throws -> Bool {
        guard let prvKey = newPrivateKey else {
            throw IXError.keyMalformed
        }
        
        guard let publicKey = ICONUtil.createPublicKey(privateKey: prvKey) else {
            throw IXError.copyPublicKey
        }
        
        let address = ICONUtil.makeAddress(prvKey, publicKey)
        
        return WManager.canSaveWallet(address: address)
    }
    
    func validateETHPrivateKey() throws -> Bool {
        guard let prvKey = newPrivateKey else {
            throw IXError.keyMalformed
        }
        
        let generator = try EthereumKeystoreV3(privateKey: prvKey.hexToData()!)
        
        guard let address = generator?.getAddress()?.address else {
            throw IXError.keyMalformed
        }
        
        return WManager.canSaveWallet(address: address)
    }
    
    func saveWallet(alias: String) throws {
        self.newAlias = alias
        self.newWallet?.alias = alias
        
        if let type = self.newWallet?.type {
            
            switch type {
            case .icx:
                let wallet = self.newWallet as! ICXWallet
                try wallet.saveICXWallet()
                
            case .eth:
                let wallet = self.newWallet as! ETHWallet
                try wallet.saveETHWallet()
                
            default:
                break
            }
            
        } else {
            throw IXError.invalidKeystore
        }
    }
    
    func resetData() {
        newType = nil
        newPrivateKey = nil
        newAlias = nil
        newWallet = nil
        newBundle = nil
    }
}

let WCreator = WalletCreator.sharedInstance

class BundleCreator {
    private var items: [(name: String, privKey: String, type: COINTYPE)]
    
    init(items: [(name: String, privKey: String, type: COINTYPE)]) {
        self.items = items
    }
    
    func createBundle(newPassword: String, completion: @escaping (_ isSuccess: Bool, _ filePath: URL?) -> Void) {
        DispatchQueue.global(qos: .default).async {
            var exportList = [[String: WalletExportBundle]]()
            for item in self.items {
                if item.type == .icx {
                    
                    let wallet = ICXWallet(alias: item.name)
                    do {
                        try wallet.generateICXKeyStore(privateKey: item.privKey, password: newPassword)
                        let export = wallet.exportBundle()
                        exportList.append([wallet.address!: export])
                    } catch {
                        Log.Debug("\(error)")
                        DispatchQueue.main.async {
                            completion(false, nil)
                        }
                        return
                    }
                    
                    
                } else if item.type == .eth {
                    
                    let wallet = ETHWallet(alias: item.name)
                    do {
                        try wallet.generateETHKeyStore(privateKey: item.privKey, password: newPassword)
                        let export = wallet.exportBundle()
                        exportList.append([wallet.address!: export])
                    } catch {
                        Log.Debug("\(error)")
                        DispatchQueue.main.async {
                            completion(false, nil)
                        }
                        return
                    }
                }
            }
            
            let encoder = JSONEncoder()
            do {
                let encoded = try encoder.encode(exportList)
                
                let filename = "ICONex_" + Date.currentZuluTime
                
                let fm = FileManager.default
                
                var path = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
                path = path.appendingPathComponent("ICONex")
                var isDirectory = ObjCBool(false)
                if !fm.fileExists(atPath: path.path, isDirectory: &isDirectory) {
                    try fm.createDirectory(at: path, withIntermediateDirectories: false, attributes: nil)
                }
                
                let filePath = path.appendingPathComponent(filename)
                try encoded.write(to: filePath, options: .atomic)
                
                DispatchQueue.main.async {
                    completion(true, filePath)
                }
            } catch {
                Log.Debug("\(error)")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }
        }
    }
}

struct WalletExportBundle: Codable {
    var name: String
    var type: String
    var priv: String
    var tokens: [TokenExportBundle]?
}

struct TokenExportBundle: Codable {
    var address: String
    var createdAt: String
    var decimals: Int
    var defaultDecimals: Int
    var defaultName: String
    var name: String
    var defaultSymbol: String
    var symbol: String
}

//protocol BalanceInfoConvertible {
//    var walletType: COINTYPE { get set }
//    var address: String { get set }
//    var name: String { get set }
//    var value: String? { get set }
//    var resopnse: IXJSONResponse? { get set }
//}
//
//class BalanceInfo: BalanceInfoConvertible {
//    var walletType: COINTYPE
//    var address: String
//    var name: String
//    var value: String?
//    var resopnse: IXJSONResponse?
//    
//    init(type: COINTYPE, name: String, address: String) {
//        self.name = name
//        self.walletType = type
//        self.address = address
//    }
//}

class WalletBalanceOperation {
    lazy var loadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Balance.Queue"
        queue.maxConcurrentOperationCount = 1
        
        return queue
    }()
}

class SwapManager {
    private init() { }
    
    static let sharedInstance = SwapManager()
    
    var walletInfo: WalletInfo?
    var privateKey: String?
    
    func reset() {
        walletInfo = nil
        privateKey = nil
    }
}

class Preference {
    private init() {}
    
    static let shared = Preference()
    
    var navSelected: Int = 0
}




struct AddressBook {
    static func canSaveAddressBook(name: String) -> Bool {
        return DB.canSaveAddressBook(name: name)
    }
    
    static func canSaveAddressBook(address: String) -> Bool {
        return DB.canSaveAddressBook(address: address)
    }
    
    static func addAddressBook(name: String, address: String, type: COINTYPE) throws {
        try DB.saveAddressBook(name: name, address: address, type: type)
    }
    
    static func modifyAddressBook(oldName: String, newName: String) throws {
        if canSaveAddressBook(name: newName) {
            try DB.modifyAddressBook(oldName: oldName, newName: newName)
        } else {
            throw IXError.duplicateName
        }
    }
    
    static func loadAddressBookList(by: COINTYPE) -> [AddressBookInfo] {
        
        var addressBookList = [AddressBookInfo]()
        do {
            
            let list = try DB.addressBookList(by: by)
            for address in list {
                let addressBook = AddressBookInfo(addressBook: address)
                addressBookList.append(addressBook)
            }
        } catch {
            Log.Debug("Get Addressbook list Error: \(error)")
        }
        
        return addressBookList
    }
    
    static func deleteAddressBook(name: String) throws {
        try DB.deleteAddressBook(name: name)
    }
}


struct Transaction {
    
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
