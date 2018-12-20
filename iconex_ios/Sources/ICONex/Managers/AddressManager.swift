//
//  AddressManager.swift
//  iconex_ios
//
//  Created by a1ahn on 20/12/2018.
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import Foundation


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
