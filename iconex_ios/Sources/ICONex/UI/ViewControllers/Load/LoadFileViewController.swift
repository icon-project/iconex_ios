//
//  LoadFileViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 05/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import MobileCoreServices
import RxSwift
import RxCocoa
import PanModal

enum LoadFileMode {
    case loadFile, loadPK
}

class LoadFileViewController: BaseViewController {
    @IBOutlet weak var loadFileHeader: UILabel!
    @IBOutlet weak var container1: UIStackView!
    @IBOutlet weak var inputBox1: IXInputBox!
    @IBOutlet weak var fileSelectButton: UIButton!
    
    @IBOutlet weak var container2: UIView!
    @IBOutlet weak var coinBackground: UIView!
    @IBOutlet weak var coinSelectLabel: UILabel!
    @IBOutlet weak var coinSelectButton: UIButton!
    
    @IBOutlet weak var inputBox2: IXInputBox!
    @IBOutlet weak var qrView: UIView!
    @IBOutlet weak var qrButton: UIButton!
    @IBOutlet weak var descContainer1: UIView!
    @IBOutlet weak var loadFileDesc: UILabel!
    @IBOutlet weak var descContainer2: UIView!
    @IBOutlet weak var loadPrivateDesc: UILabel!
    
    var delegate: loadWalletSequence! = nil
    var selectedFile: URL?
    var selectedType: String = "icx" {
        willSet {
            if newValue.lowercased() == "icx" {
                coinSelectLabel.size16(text: "ICON (ICX)")
            } else {
                coinSelectLabel.size16(text: "Ethereum (ETH)")
            }
        }
    }
    
    var viewMode: LoadFileMode = .loadFile {
        willSet {
            switch newValue {
            case .loadFile:
                loadFileHeader.size16(text: "LoadFile.File.Header".localized, color: .gray77, weight: .medium, align: .center)
                container1.isHidden = false
                container2.isHidden = true
                descContainer1.isHidden = false
                descContainer2.isHidden = true
                loadFileDesc.size12(text: "LoadFile.File.Desc".localized, color: .mint1, weight: .light, align: .left)
                qrView.isHidden = true
                inputBox2.set(state: .normal, placeholder: "Placeholder.InputPassword".localized)
                inputBox2.set(inputType: .confirmPassword)
                
            case .loadPK:
                loadFileHeader.size16(text: "LoadFile.PrivateKey.Header".localized, color: .gray77, weight: .medium, align: .center)
                container1.isHidden = true
                container2.isHidden = false
                descContainer1.isHidden = true
                descContainer2.isHidden = false
                loadPrivateDesc.size12(text: "LoadFile.PrivateKey.Desc".localized, color: .mint1, weight: .light, align: .left)
                qrView.isHidden = false
                inputBox2.set(state: .normal, placeholder: "Placeholder.PrivateKey".localized)
                inputBox2.set(inputType: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        fileSelectButton.rx.tap.subscribe(onNext: { [unowned self] in
            self.pickerSelected()
        }).disposed(by: disposeBag)
        
        coinSelectButton.rx.tap.subscribe(onNext: { [unowned self] in
            let picker = UIStoryboard(name: "Picker", bundle: nil).instantiateInitialViewController() as! IXPickerViewController
            picker.headerTitle = "LoadFile.SelectCoin".localized
            picker.items = ["ICON (ICX)", "Ethereum (ETH)"]
            picker.selectedAction = { index in
                self.selectedType = index == 0 ? "icx" : "eth"
            }
            picker.pop()
        }).disposed(by: disposeBag)
        
        inputBox1.set(state: .normal, placeholder: "LoadFile.File.SelectFile".localized)
        inputBox1.set(inputType: .fileSelect)
        inputBox2.set(validator: { _ in
            if self.viewMode == .loadFile {
                return self.validatePassword()
            } else {
                return self.validatePrivateKey()
            }
        })
        coinBackground.backgroundColor = .gray250
        coinBackground.border(1.0, .gray230)
        coinBackground.corner(8)
        fileSelectButton.border(1.0, .gray230)
        fileSelectButton.corner(4)
        descContainer2.border(0.5, .mint3)
        descContainer2.backgroundColor = .mint4
        descContainer2.corner(8)
        qrButton.border(1, .gray230)
        qrButton.corner(4)
        qrButton.rx.tap.subscribe(onNext: { [unowned self] in
            let reader = UIStoryboard(name: "Camera", bundle: nil).instantiateInitialViewController() as! QRReaderViewController
            reader.set(mode: .prvKey, handler: { code in
                self.inputBox2.text = code
                _ = self.validatePrivateKey()
            })
            self.present(reader, animated: true, completion: nil)
        }).disposed(by: disposeBag)
        selectedType = "icx"
    }
    
    override func refresh() {
        super.refresh()
        viewMode = delegate.selectedMode()
        
        if viewMode == .loadFile {
            if let url = self.selectedFile {
                inputBox1.text = " " + url.lastPathComponent
                
                if let _ = try? Validator.validateKeystore(urlOfData: url) {
                    let left = UIImageView(image: UIImage(named: "icKeystorefileLoad"))
                    left.contentMode = .left
                    left.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
                    inputBox1.leftAccessory = left
                    inputBox1.set(state: .focus)
                } else if Validator.checkWalletBundle(url: url) != nil {
                    let left = UIImageView(image: UIImage(named: "icKeystorefileLoad"))
                    left.contentMode = .left
                    left.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
                    inputBox1.leftAccessory = left
                    inputBox1.set(state: .focus)
                } else {
                    let left = UIImageView(image: UIImage(named: "icKeystorefileError"))
                    left.contentMode = .left
                    left.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
                    inputBox1.leftAccessory = left
                    inputBox1.setError(message: "Error.Wallet.InvalidFile".localized)
                }
            } else {
                inputBox1.set(state: .normal)
                inputBox1.text = ""
                inputBox1.leftAccessory = nil
                inputBox2.set(state: .normal)
                inputBox2.text = ""
            }
        } else {
            
        }
    }
}

extension LoadFileViewController {
    func resetData() {
        selectedFile = nil
    }
    
    func validatePassword() -> String? {
        self.delegate.set(loader: nil)
        delegate.invalidated()
        let pwd = inputBox2.text
        guard pwd.count > 0 else { return nil }
        
        guard let url = self.selectedFile else {
            return "Error.NoBackupFile".localized
        }
        
        if let keystore = try? Validator.validateKeystore(urlOfData: url) {
            if let _ = try? keystore.extractPrivateKey(password: pwd) {
                let loader = WalletLoader(keystore: keystore, password: pwd)
                delegate.set(loader: loader)
                delegate.validated()
                return nil
            } else {
                delegate.set(loader: nil)
                return "Error.Password.Wrong".localized
            }
        } else if let bundle = Validator.checkWalletBundle(url: url) {
            if Validator.validateBundlePassword(bundle: bundle, password: pwd) {
                
                let loader = WalletLoader(bundle: bundle, password: pwd)
                delegate.set(loader: loader)
                delegate.validated()
                return nil
            } else {
                delegate.set(loader: nil)
                return "Error.Password.Wrong".localized
            }
        } else {
            delegate.set(loader: nil)
            return "Error.Password.Wrong".localized
        }
    }
    
    func validatePrivateKey() -> String? {
        self.delegate.set(loader: nil)
        delegate.invalidated()
        let key = inputBox2.text
        guard key.count > 0 else {
            delegate.invalidated()
            delegate.set(loader: nil)
            return nil
        }
        
        guard key.hexToData() != nil, key.count == 64 else {
            delegate.invalidated()
            delegate.set(loader: nil)
            return "Error.PrivateKey".localized
        }
        let loader = WalletLoader(privateKey: key)
        self.delegate.set(loader: loader)
        delegate.validated()
        return nil
    }
}

extension LoadFileViewController: UIDocumentPickerDelegate {
    func pickerSelected() {
        let document = UIDocumentPickerViewController(documentTypes: ["public.text", "public.data", String(kUTTypePlainText), String(kUTTypeItem)], in: .import)
        document.delegate = self
        document.allowsMultipleSelection = false
        presentPanModal(document)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.selectedFile = urls.first
        
        refresh()
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        inputBox1.leftAccessory = nil
    }
}

extension UIDocumentPickerViewController: PanModalPresentable {
    public var panScrollable: UIScrollView? {
        return nil
    }
    
    public var showDragIndicator: Bool {
        return false
    }
    
    public func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return false
    }
    
    public var isHapticFeedbackEnabled: Bool {
        return false
    }
    
    public var backgroundAlpha: CGFloat {
        return 0.4
    }
    
    public var topOffset: CGFloat { return app.window!.safeAreaInsets.top }
    
    public var cornerRadius: CGFloat { return 18.0 }
}
