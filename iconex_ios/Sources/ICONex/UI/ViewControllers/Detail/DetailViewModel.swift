//
//  DetailViewModel.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 29/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import ICONKit
import Web3swift
import BigInt

class DetailViewModel {
    static let shared = DetailViewModel()
    
    var wallet: PublishSubject<BaseWalletConvertible>
    var token: PublishSubject<Token?>
    
    var balance: PublishSubject<BigUInt>
    
    var fullName: PublishSubject<String>
    var symbol: BehaviorSubject<String>
    var coinTokenType: PublishSubject<DetailType>
    
    // usd, btc, eth..
    var currencyUnit: BehaviorSubject<BalanceUnit>
    var currencyPrice: BehaviorSubject<String>
    
    // icxusd, icxeth.... price
    var unitBalancePrice: PublishSubject<String>
    
    var reload: PublishSubject<Bool>
    var filter: BehaviorSubject<TxFilter>
    
    var disposeBag = DisposeBag()
    
    var tracker: Tracker {
        switch Config.host {
        case .main:
            return Tracker.main()
            
        case .euljiro:
            return Tracker.euljiro()
            
        case .yeouido:
            return Tracker.yeouido()
            #if DEBUG
        case .localTest:
            return Tracker.localTest()
            #endif
        }
    }
    
    init() {
        self.wallet = PublishSubject<BaseWalletConvertible>()
        self.token = PublishSubject<Token?>()
        
        self.balance = PublishSubject<BigUInt>()
        
        self.fullName = PublishSubject<String>()
        self.symbol = BehaviorSubject<String>(value: "ICX")
        self.coinTokenType = PublishSubject<DetailType>()
        
        self.currencyUnit = BehaviorSubject<BalanceUnit>(value: .USD)
        let exchangeUnit = try? self.currencyUnit.value().symbol
        
        self.currencyPrice = BehaviorSubject<String>(value: "-")
        self.unitBalancePrice = PublishSubject<String>()
        self.reload = PublishSubject<Bool>()
        self.filter = BehaviorSubject<TxFilter>(value: .all)

        Observable.combineLatest(self.currencyUnit, self.symbol).flatMapLatest { (unit, symbol) -> Observable<String> in
            let unitSymbol = unit.symbol.lowercased()
            let queryString = symbol.lowercased()+unitSymbol
            let currencyPrice = Manager.exchange.exchangeInfoList[queryString]?.price ?? "-"
            return Observable.just(currencyPrice)
        }.bind(to: self.currencyPrice)
        .disposed(by: disposeBag)
        
        self.reload.subscribe { (_) in
            self.currencyPrice.onNext(Manager.exchange.exchangeInfoList["icx\(exchangeUnit ?? "")"]?.price ?? "-")
        }.disposed(by: disposeBag)
    }
}

let detailViewModel = DetailViewModel.shared
