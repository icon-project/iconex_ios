//
//  TokenManageViewController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import web3swift

enum ManageMode {
    case add, modify
}

class TokenManageViewController: UIViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var addressTitle: UILabel!
    @IBOutlet weak var addressInputBox: IXInputBox!
    @IBOutlet weak var tokenTitle: UILabel!
    @IBOutlet weak var tokenInputBox: IXInputBox!
    @IBOutlet weak var symbolTitle: UILabel!
    @IBOutlet weak var symbolInputBox: IXInputBox!
    @IBOutlet weak var decimalTitle: UILabel!
    @IBOutlet weak var decimalInputBox: IXInputBox!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var qrButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var addressTrail: NSLayoutConstraint!
    
    var manageMode: ManageMode = .add
    
    var walletInfo: WalletInfo?
    var selectedToken: TokenInfo?
    
    private var defaultDecimal: Int?
    private var isChecked: Bool = false
    
    private let disposeBag = DisposeBag()
    
    private var editMode: Bool = false {
        willSet {
            if newValue == false {
                // normal
                editButton.setTitle("Common.Edit".localized, for: .normal)
            } else {
                // editing
                editButton.setTitle("Common.Complete".localized, for: .normal)
            }
            
            actionButton.isHidden = !newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }

    func initialize() {
        addressTitle.text = "Token.Address".localized
        tokenTitle.text = "Token.Name".localized
        symbolTitle.text = "Token.Symbol".localized
        decimalTitle.text = "Token.Decimals".localized
        
        addressInputBox.setState(.normal, nil)
        addressInputBox.textField.placeholder = "Token.EnterAddress".localized
        tokenInputBox.setState(.normal, nil)
        tokenInputBox.setType(.normal)
        tokenInputBox.textField.placeholder = "Token.EnterName".localized
        symbolInputBox.setState(.normal, nil)
        symbolInputBox.setType(.normal)
        symbolInputBox.textField.placeholder = "Token.EnterSymbol".localized
        decimalInputBox.setState(.normal, nil)
        decimalInputBox.setType(.numeric)
        decimalInputBox.textField.placeholder = "Token.EnterNumbers".localized
        actionButton.cornered()
        qrButton.cornered()
        
        confirmButton.styleDark()
        confirmButton.rounded()
        confirmButton.setTitle("Common.Add".localized, for: .normal)
        actionButton.setTitle("Token.RemoveToken".localized, for: .normal)
        
        if manageMode == .add {
            navTitle.text = "Token.Add".localized
            confirmButton.isHidden = false
            actionButton.isHidden = true
            editButton.isHidden = true
            addressTitle.isHidden = false
            addressInputBox.setType(.address)
            actionButton.isEnabled = false
            actionButton.styleLight()
            addressInputBox.isEnable = true
            tokenInputBox.isEnable = true
            symbolInputBox.isEnable = false
            decimalInputBox.isEnable = false
            qrButton.isHidden = false
            addressTrail.constant = 64
        } else {
            navTitle.text = selectedToken?.name
            confirmButton.isHidden = true
            editButton.isHidden = false
            actionButton.isHidden = false
            actionButton.styleDark()
            addressInputBox.setType(.plain)
            addressInputBox.plainLabel.text = selectedToken?.contractAddress
            tokenInputBox.textField.text = selectedToken?.name
            symbolInputBox.textField.text = selectedToken?.symbol
            decimalInputBox.textField.text = String(selectedToken!.decimal)
            addressInputBox.isEnable = false
            tokenInputBox.isEnable = false
            symbolInputBox.isEnable = false
            decimalInputBox.isEnable = false
            qrButton.isHidden = true
            addressTrail.constant = 24
            
            editMode = false
        }
        
        addressInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.addressInputBox.setState(.focus, nil)
        }).disposed(by: disposeBag)
        addressInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            if self.validateAddres() && !self.editMode && !self.isChecked {
                self.fetchTokenInfo()
            }
        }).disposed(by: disposeBag)
        addressInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            if self.validateAddres() && !self.editMode && !self.isChecked {
                self.fetchTokenInfo()
            }
        }).disposed(by: disposeBag)
        
        tokenInputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.tokenInputBox.setState(.focus, nil)
        }).disposed(by: disposeBag)
        tokenInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            if !self.editMode && !self.isChecked {
                guard self.validateName() else { return }
                guard self.validateAddres() else { return }
                self.fetchTokenInfo()
            } else {
                self.editButton.isEnabled = self.validateName()
            }
        }).disposed(by: disposeBag)
        tokenInputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            if !self.editMode && !self.isChecked {
                guard self.validateName() else { return }
                guard self.validateAddres() else { return }
                self.fetchTokenInfo()
            } else {
                self.editButton.isEnabled = self.validateName()
            }
        }).disposed(by: disposeBag)
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                if self.editMode {
                    Alert.Confirm(message: "Alert.Token.Edit.Cancel".localized, cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: {
                        self.navigationController?.popViewController(animated: true)
                    }).show(self)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }).disposed(by: disposeBag)
        
        editButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                if self.editMode == true {
                    guard self.validateName() else { return }
                    self.tokenInputBox.isEnable = false
                    self.symbolInputBox.isEnable = false
                    self.decimalInputBox.isEnable = false
                    
                    do {
                        self.selectedToken?.name = self.tokenInputBox.textField.text!
                        self.selectedToken?.symbol = self.symbolInputBox.textField.text!
                        self.selectedToken?.decimal = Int(self.decimalInputBox.textField.text!)!
                        try Ethereum.modifyToken(tokenInfo: self.selectedToken!)
                        self.navTitle.text = self.tokenInputBox.textField.text
                    } catch {
                        Log.Debug("\(error)")
                    }
                } else {
                    self.tokenInputBox.isEnable = true
                    self.symbolInputBox.isEnable = false
                }
                
                self.editMode = !self.editMode
            }).disposed(by: disposeBag)
        
        actionButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                guard let token = self.selectedToken else { return }
                Alert.Confirm(message: "\"" + token.name + "\"" + "Alert.Token.Remove".localized, cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: {
                    do {
                        try Ethereum.removeToken(tokenInfo: self.selectedToken!)
                        WManager.loadWalletList()
                        
                        self.dismiss(animated: true, completion: nil)
                    } catch {
                        Log.Debug("\(error)")
                        Alert.Basic(message: "Error.Token.Remove".localized).show(self)
                    }
                    
                }).show(self)
            }).disposed(by: disposeBag)
        
        confirmButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            do {
                guard let token = self.selectedToken else { return }
                token.name = self.tokenInputBox.textField.text!
                try Ethereum.addToken(tokenInfo: token)
                EManager.addToken(token.symbol)
                WManager.loadWalletList()
                EManager.getExchangeList()
                
                self.dismiss(animated: true, completion: nil)
            } catch {
                Log.Debug("\(error)")
                Alert.Basic(message: "Error.Token.Add".localized).show(self)
            }
        }).disposed(by: disposeBag)
        
        qrButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                let reader = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "QRReaderView") as! QRReaderViewController
                reader.mode = .address
                reader.type = .eth
                reader.handler = { code in
                    self.addressInputBox.textField.text = code
                    self.addressInputBox.textField.becomeFirstResponder()
                }
                
                reader.show(self)
            }).disposed(by: disposeBag)
        
        keyboardHeight().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] height in
                if height == 0 {
                    self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                } else {
                    var keyboardHeight: CGFloat = height
                    if #available(iOS 11.0, *) {
                        keyboardHeight = keyboardHeight - self.view.safeAreaInsets.bottom
                    }
                    self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
                }
            }).disposed(by: disposeBag)
        
        isChecked = false
    }
    
    func fetchTokenInfo() {
        guard let address = self.addressInputBox.textField.text else { return }
        if manageMode == .add {
            isChecked = true
            
            if let tokenListInfo = Ethereum.tokenListInfo(contract: address) {
                self.symbolInputBox.textField.text = tokenListInfo.symbol
                self.symbolInputBox.setState(.normal, "")
                self.decimalInputBox.textField.text = String(tokenListInfo.decimal)
                self.decimalInputBox.setState(.normal, "")
                
                self.actionButton.isEnabled = self.validation()
            } else {
                addressInputBox.isLoading = true
                Ethereum.requestTokenInformation(tokenContractAddress: address, myAddress: self.walletInfo!.address, completion: { [unowned self] result in
                    self.addressInputBox.isLoading = false
                    if let token = result {
                        
                        guard token.symbol != "" else {
                            self.isChecked = false
                            Alert.Basic(message: "Error.Token.ConnectionRefused".localized).show(self)
                            return
                        }
                        
                        self.tokenInputBox.textField.text = token.name
                        self.tokenInputBox.setState(.normal, nil)
                        self.symbolInputBox.textField.text = token.symbol
                        self.symbolInputBox.setState(.normal, nil)
                        self.decimalInputBox.textField.text = String(token.decimal)
                        
                        self.defaultDecimal = token.decimal
                        
                        self.selectedToken = TokenInfo(name: token.name, defaultName: token.name, symbol: token.symbol, decimal: token.decimal, defaultDecimal: token.decimal, dependedAddress: self.walletInfo!.address, contractAddress: self.addressInputBox.textField.text!, parentType: self.walletInfo!.type.rawValue)
                        
                        self.actionButton.isEnabled = self.validation()
                        
                    } else {
                        self.isChecked = false
                        Alert.Basic(message: "Error.Token.ConnectionRefused".localized).show(self)
                        return
                    }
                })
            }
        }
    }
    
    func validateAddres() -> Bool {
        guard let address = addressInputBox.textField.text, address != "" else {
            addressInputBox.setState(.error, "Error.Address".localized)
            return false
        }
        guard Validator.validateETHAddress(address: address) else {
            addressInputBox.setState(.error, "Error.Address.ETH.Invalid".localized)
            return false
        }
        let parentWallet = WManager.loadWalletBy(info: self.walletInfo!) as! ETHWallet
        if !parentWallet.canSaveToken(contractAddress: address) {
            addressInputBox.setState(.error, "Error.Token.Duplicated".localized)
            return false
        }
        
        addressInputBox.setState(.normal, "")
        
        return true
    }
    
    func validateName() -> Bool {
        guard let name = tokenInputBox.textField.text, name != "" else {
            tokenInputBox.setState(.error, "Error.Token.InputName".localized)
            return false
        }
        tokenInputBox.setState(.normal, "")
        return true
    }
    
    func validation() -> Bool {
        guard validateAddres() else { return false }
        guard validateName() else { return false }
        return true
    }
}
