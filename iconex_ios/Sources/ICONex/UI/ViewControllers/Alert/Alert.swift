//
//  Alert.swift
//  iconex_ios
//
//  Created by sweepty on 06/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit
import ICONKit
import BigInt

class Alert {
    static func basic(title: String, subtitle: String? = nil, hasHeaderTitle: Bool = false, isOnlyOneButton: Bool = true, leftButtonTitle: String? = nil, rightButtonTitle: String? = nil, cancelAction: (() -> Void)? = nil, confirmAction: (() -> Void)? = nil) -> AlertViewController {
        let alertVC = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "AlertView") as! AlertViewController
        alertVC.titleText = title
        alertVC.subTitleText = subtitle ?? ""
        alertVC.type = hasHeaderTitle ? .allText : .basic
        alertVC.isButtonOne = isOnlyOneButton
        
        if let leftTitle = leftButtonTitle {
            alertVC.leftButtonTitle = leftTitle
        }
        if let rightTitle = rightButtonTitle {
            alertVC.rightButtonTitle = rightTitle
        }
        alertVC.cancelHandler = cancelAction
        alertVC.confirmHandler = confirmAction
    
        return alertVC
    }
    
    static func txHash(txData: AlertTxHashInfo, confirmAction: (() -> Void)? = nil) -> AlertViewController {
        let alertVC = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "AlertView") as! AlertViewController
        alertVC.type = .txHash
        alertVC.txHashData = txData
        alertVC.confirmHandler = confirmAction
        return alertVC
    }
    
    static func password(wallet: BaseWalletConvertible, returnAction: ((_ pk: String) -> Void)? = nil) -> AlertViewController {
        let alertVC = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "AlertView") as! AlertViewController
        alertVC.type = .password
        alertVC.walletInfo = wallet
        alertVC.returnHandler = returnAction
        return alertVC
    }
    
    static func changeWalletName(wallet: BaseWalletConvertible, confirmAction: (() -> Void)? = nil) -> AlertViewController {
        let alertVC = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "AlertView") as! AlertViewController
        alertVC.type = .walletName
        alertVC.walletInfo = wallet
        alertVC.confirmHandler = confirmAction
        return alertVC
    }
    
    static func addAddress(isICX: Bool = true, confirmAction: (() -> Void)? = nil) -> AlertViewController {
        let alertVC = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "AlertView") as! AlertViewController
        alertVC.type = .addAddress
        alertVC.isICX = isICX
        alertVC.confirmHandler = confirmAction
        return alertVC
    }
    
    static func stake(stakeInfo: StakeInfo, confirmAction: (() -> Void)? = nil) -> AlertViewController {
        let alertVC = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "AlertView") as! AlertViewController
        alertVC.type = .stake
        alertVC.stakeInfo = stakeInfo
        alertVC.confirmHandler = confirmAction
        return alertVC
    }
    
    static func unstake(unstakeInfo: StakeInfo, confirmAction: (() -> Void)? = nil) -> AlertViewController {
        let alertVC = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "AlertView") as! AlertViewController
        alertVC.type = .unstake
        alertVC.stakeInfo = unstakeInfo
        alertVC.confirmHandler = confirmAction
        return alertVC
    }
    
    static func unstakeCancel(cancelInfo: StakeInfo, confirmAction: (() -> Void)? = nil) -> AlertViewController {
        let alertVC = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "AlertView") as! AlertViewController
        alertVC.type = .unstakecancel
        alertVC.stakeInfo = cancelInfo
        alertVC.confirmHandler = confirmAction
        return alertVC
    }
    
    static func send(sendInfo: SendInfo, confirmAction: ((_ isSuccess: Bool, _ txHash: String?) -> Void)? = nil) -> AlertViewController {
        let alertVC = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "AlertView") as! AlertViewController
        alertVC.type = .send
        alertVC.sendInfo = sendInfo
        alertVC.successHandler = confirmAction
        return alertVC
    }
    
    static func iScore(iscoreInfo: IScoreClaimInfo, confirmAction: (() -> Void)? = nil) -> AlertViewController {
        let alertVC = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "AlertView") as! AlertViewController
        alertVC.type = .iscore
        alertVC.iscoreInfo = iscoreInfo
        alertVC.confirmHandler = confirmAction
        return alertVC
    }
    
    static func vote(voteInfo: VoteInfo, confirmAction: ((_ isSuccess: Bool, _ txHash: String?) -> Void)? = nil) -> AlertViewController {
        let alertVC = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "AlertView") as! AlertViewController
        alertVC.type = .vote
        alertVC.voteInfo = voteInfo
        alertVC.successHandler = confirmAction
        return alertVC
    }
    
    static func prepDetail(prepInfo: PRepInfoResponse) -> AlertViewController {
        let alertVC = UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "AlertView") as! AlertViewController
        alertVC.type = .prepDetail
        alertVC.prepInfo = prepInfo
        return alertVC
    }
    
}

enum AlertType {
    case basic, txHash, password, walletName, allText, stake, unstake,
        send, iscore, unstakecancel, addAddress, vote, prepDetail
}

struct AlertBasicInfo {
    var title: String
    var subtitle: String?
}

struct AlertTxHashInfo {
    var txHash: String
    var trackerURL: String
}

struct SendInfo {
    // ICX
    var transaction: Transaction?
    var privateKey: PrivateKey?
    
    // ETH
    var ethTransaction: EthereumTransaction?
    var ethPrivateKey: String?
    
    var token: Token?
    
    var amount: String
    var stepLimit: String
    var estimatedFee: String
    var estimatedUSD: String
    var receivingAddress: String
    
    init(transaction: Transaction? = nil, ethTransaction: EthereumTransaction? = nil, privateKey: PrivateKey? = nil, ethPrivateKey: String? = nil, stepLimitPrice: String, estimatedFee: String, estimatedUSD: String, token: Token? = nil, tokenAmount: BigUInt? = nil, tokenToAddress: String? = nil) {
        
        if let icx = transaction {
            self.transaction = icx
            self.privateKey = privateKey
            
            self.token = token
            if let tokenInfo = token, let tokenValue = tokenAmount, let toAddr = tokenToAddress {
                self.amount = tokenValue.toString(decimal: tokenInfo.decimal, tokenInfo.decimal, false)
                self.receivingAddress = toAddr
            } else {
                self.amount = icx.value?.toString(decimal: 18, 18, false) ?? "0"
                self.receivingAddress = icx.to ?? ""
            }
            
            self.stepLimit = stepLimitPrice
            
            self.ethTransaction = nil
            self.ethPrivateKey = nil
            
        } else if let eth = ethTransaction {
            self.ethTransaction = eth
            self.ethPrivateKey = ethPrivateKey
            if let tokenInfo = token, let tokenValue = tokenAmount {
                self.amount = tokenValue.toString(decimal: tokenInfo.decimal)
            } else {
                self.amount = eth.value.toString(decimal: 18)
            }
            self.stepLimit = String(eth.gasLimit)
            self.receivingAddress = eth.to
            
            self.transaction = nil
            self.privateKey = nil
        } else {
            self.transaction = nil
            self.privateKey = nil
            self.amount = ""
            self.stepLimit = ""
            self.receivingAddress = ""
            
            self.ethTransaction = nil
            self.ethPrivateKey = nil
        }
        self.estimatedFee = estimatedFee
        self.estimatedUSD = estimatedUSD
    }
}

struct VoteInfo {
    var count: Int
    var estimatedFee: String
    var maxFee: String
    var usdPrice: String
    
    var wallet: ICXWallet
    var delegationList: [[String: Any]]
    var privateKey: PrivateKey
}

struct EthereumTransaction {
    var privateKey: String
    var gasPrice: BigUInt
    var gasLimit: BigUInt
    var from: String
    var to: String
    var value: BigUInt
    var data: Data
}

struct IScoreClaimInfo {
    var currentIScore: String
    var youcanReceive: String
    var stepLimit: String
    var estimatedFee: String
    var estimateUSD: String
}

struct StakeInfo {
    var timeRequired: String
    var stepLimit: String
    var estimatedFee: String
    var estimatedFeeUSD: String
}
