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
    
    var totalICXBalance: BehaviorSubject<BigUInt>
    var totalExchangedBalance: PublishSubject<String>
    
    var reload: PublishSubject<Bool>
    var noti: PublishSubject<Bool>
    
    var isBigCard: BehaviorSubject<Bool>
    
    var disposeBag = DisposeBag()
    
    init() {
        self.currencyUnit = BehaviorSubject<BalanceUnit>(value: .USD)
        
        self.totalICXBalance = BehaviorSubject<BigUInt>(value: Manager.balance.getTotalBalance())
        self.totalExchangedBalance = PublishSubject<String>()
        
        self.reload = PublishSubject<Bool>()
        self.noti = PublishSubject<Bool>()
        
        self.isBigCard = BehaviorSubject<Bool>(value: false)
        
        Observable.combineLatest(self.noti, self.reload)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .default))
            .flatMapLatest { (_, _) -> Observable<BigUInt> in
                
                let balance = Manager.balance.getTotalBalance()
                return Observable.just(balance)
                
        }.bind(to: self.totalICXBalance)
        .disposed(by: disposeBag)
        
        Observable.combineLatest(self.currencyUnit, self.totalICXBalance).flatMapLatest { (unit, totalBalance) -> Observable<String> in
            let unitSymbol = unit.symbol
            let price = Tool.calculatePrice(decimal: 18, currency: "icx\(unitSymbol.lowercased())", balance: totalBalance)
            return Observable.just(price)
        }.bind(to: self.totalExchangedBalance)
        .disposed(by: disposeBag)
    }
}

let mainViewModel = MainViewModel.shared
