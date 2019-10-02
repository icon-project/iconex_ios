//
//  MainViewModel.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 20/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import BigInt
import ICONKit
import Web3swift

class MainViewModel {
    static let shared = MainViewModel()
    
    var currencyUnit: BehaviorSubject<BalanceUnit>
    
    var totalExchangedBalance: PublishSubject<String>
    
//    var totalVotedPower: PublishSubject<String>
    var totalVotedPower: BehaviorSubject<String>
    
    var balaneList: PublishSubject<[BigUInt]>
    
    var reload: PublishSubject<Bool>
    var noti: PublishSubject<Bool>
    
    var isBigCard: BehaviorSubject<Bool>
    
    var disposeBag = DisposeBag()
    
    init() {
        self.currencyUnit = BehaviorSubject<BalanceUnit>(value: .USD)
        
        self.totalExchangedBalance = PublishSubject<String>()
        
        self.totalVotedPower = BehaviorSubject<String>(value: "-")
        
        self.balaneList = PublishSubject<[BigUInt]>()
        
        self.reload = PublishSubject<Bool>()
        self.noti = PublishSubject<Bool>()
        
        self.isBigCard = BehaviorSubject<Bool>(value: false)
        
        Observable.combineLatest(self.currencyUnit, self.balaneList).flatMapLatest { (unit, totalBalance) -> Observable<String> in
            let unitSymbol = unit.symbol
            
            guard let icxPrice = Tool.calculate(currency: "icx\(unitSymbol.lowercased())", balance: totalBalance[0]), let ethPrice = Tool.calculate(currency: "eth\(unitSymbol.lowercased())", balance: totalBalance[1]) else { return Observable.just("-") }
            
            let totalPrice = icxPrice + ethPrice
            let result = totalPrice.toString(decimal: 18, 4, true).currencySeparated()
            
            print("ICX \(icxPrice)")
            print("ETH \(ethPrice)")
            print("Balance: \(result)")
            
            return Observable.just(result)
            
        }.bind(to: self.totalExchangedBalance)
        .disposed(by: disposeBag)
    }
}

let mainViewModel = MainViewModel.shared
