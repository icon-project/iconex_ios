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
    
    var balanceList: PublishSubject<[BigUInt?]>
    
    var reload: PublishSubject<Bool>
    var noti: PublishSubject<Bool>
    
    var isBigCard: BehaviorSubject<Bool>
    
    var disposeBag = DisposeBag()
    
    init() {
        self.currencyUnit = BehaviorSubject<BalanceUnit>(value: .USD)
        
        self.totalExchangedBalance = PublishSubject<String>()
        
        self.totalVotedPower = BehaviorSubject<String>(value: "-")
        
        self.balanceList = PublishSubject<[BigUInt?]>()
        
        self.reload = PublishSubject<Bool>()
        self.noti = PublishSubject<Bool>()
        
        self.isBigCard = BehaviorSubject<Bool>(value: false)
        
        Observable.combineLatest(self.currencyUnit, self.balanceList).flatMapLatest { (unit, totalBalance) -> Observable<String> in
            let unitSymbol = unit.symbol
            
            let tempTotalPrice: BigUInt? = {
                var total: BigUInt? = nil
                if let icxBalance = totalBalance[0], let icxPrice = Tool.calculate(currency: "icx\(unitSymbol.lowercased())", balance: icxBalance) {
                    total = icxPrice
                }
                if let ethBalance = totalBalance[1], let ethPrice = Tool.calculate(currency: "eth\(unitSymbol.lowercased())", balance: ethBalance) {
                    if let t = total {
                        total = t + ethPrice
                    } else {
                        total = ethPrice
                    }
                }
                return total
            }()
            
            guard let totalPrice = tempTotalPrice else { return Observable.just("-") }
            
            let result = totalPrice.toString(decimal: 18, 4, true).currencySeparated()
            
            return Observable.just(result)
            
        }.bind(to: self.totalExchangedBalance)
        .disposed(by: disposeBag)
    }
}

let mainViewModel = MainViewModel.shared
