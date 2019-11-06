//
//  LoadNameViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 05/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import BigInt

class BundleLoadCell: UITableViewCell {
    @IBOutlet weak var walletNameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
}

class LoadNameViewController: BaseViewController {
    @IBOutlet weak var loadNameHeader: UILabel!
    @IBOutlet weak var inputBox1: IXInputBox!
    @IBOutlet weak var inputBox2: IXInputBox!
    @IBOutlet weak var inputBox3: IXInputBox!
    @IBOutlet weak var descContainer: UIView!
    @IBOutlet weak var bottomDesc1: UILabel!
    @IBOutlet weak var bottomDesc2: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: loadWalletSequence! = nil
    
    private var bundleBalances = [String: BigUInt]()
    private var isWorking = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        tableView.tableFooterView = UIView()
        
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerLabel)
        
        let descContainer = UIView()
        descContainer.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(descContainer)
        
        let desc1 = UILabel()
        desc1.translatesAutoresizingMaskIntoConstraints = false
        descContainer.addSubview(desc1)
        
        let desc2 = UILabel()
        desc2.translatesAutoresizingMaskIntoConstraints = false
        descContainer.addSubview(desc2)
        
        headerLabel.numberOfLines = 0
        desc1.numberOfLines = 0
        desc2.numberOfLines = 0
        
        descContainer.corner(8)
        descContainer.backgroundColor = .mint4
        descContainer.border(0.5, .mint3)
        
        tableView.tableHeaderView = headerView
        
        headerLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 40).isActive = true
        headerLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20).isActive = true
        headerLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20).isActive = true
        
        descContainer.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 30).isActive = true
        descContainer.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor, constant: 20).isActive = true
        descContainer.trailingAnchor.constraint(equalTo: headerLabel.trailingAnchor, constant: -20).isActive = true
        descContainer.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -20).isActive = true
        
        desc1.topAnchor.constraint(equalTo: descContainer.topAnchor, constant: 20).isActive = true
        desc1.leadingAnchor.constraint(equalTo: descContainer.leadingAnchor, constant: 20).isActive = true
        desc1.trailingAnchor.constraint(equalTo: descContainer.trailingAnchor, constant: -20).isActive = true
        
        desc2.topAnchor.constraint(equalTo: desc1.bottomAnchor, constant: 12).isActive = true
        desc2.leadingAnchor.constraint(equalTo: descContainer.leadingAnchor, constant: 20).isActive = true
        desc2.trailingAnchor.constraint(equalTo: descContainer.trailingAnchor, constant: -20).isActive = true
        desc2.bottomAnchor.constraint(equalTo: descContainer.bottomAnchor, constant: -10).isActive = true
        
        headerView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 0).isActive = true
        headerView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor, constant: 0).isActive = true
        headerView.widthAnchor.constraint(equalTo: tableView.widthAnchor).isActive = true
        
        headerLabel.size16(text: "LoadName.Bundle.HeaderView.Header".localized, color: .gray77, weight: .medium, align: .center)
        desc1.size12(text: "LoadName.Bundle.Desc1".localized, color: .mint1)
        desc2.size12(text: "LoadName.Bundle.Desc2".localized, color: .mint1)
        
        tableView.tableHeaderView?.layoutIfNeeded()
        
    }
    
    override func refresh() {
        super.refresh()
        
        guard let loader = delegate.loader else { return }
        
        inputBox1.set(state: .normal, placeholder: "Placeholder.WalletName".localized)
        inputBox1.set(inputType: .name)
        inputBox2.set(state: .normal, placeholder: "Placeholder.InputPassword".localized)
        inputBox2.set(inputType: .createPassword)
        inputBox3.set(state: .normal, placeholder: "Placeholder.ConfirmPassword".localized)
        inputBox3.set(inputType: .confirmPassword)
        
        switch delegate.selectedMode() {
        case .loadFile:
            inputBox2.isHidden = true
            inputBox3.isHidden = true
            descContainer.isHidden = true
            if loader.type == .wallet {
                loadNameHeader.size16(text: "LoadName.Wallet.Header".localized, color: .gray77, weight: .medium, align: .center)
                inputBox1.set(validator: { text in
                    if let nameError = self.validateName() {
                        return nameError
                    }
                    self.delegate.validated()
                    return nil
                })
                scrollView?.isHidden = false
                tableView.isHidden = true
            } else {
                scrollView?.isHidden = true
                tableView.isHidden = false
                tableView.dataSource = self
                tableView.delegate = self
            }
            
        case .loadPK:
            scrollView?.isHidden = false
            tableView.isHidden = true
            loadNameHeader.size16(text: "LoadName.PK.Header".localized, color: .gray77, weight: .medium, align: .center)
            
            inputBox2.isHidden = false
            inputBox3.isHidden = false
            descContainer.isHidden = false
            bottomDesc1.size12(text: "LoadName.PK.Desc1".localized, color: .mint1, weight: .light, align: .left)
            bottomDesc2.size12(text: "LoadName.PK.Desc2".localized, color: .mint1, weight: .light, align: .left)
            
            inputBox1.set(validator: { text in
                if let error = self.validateName() {
                    return error
                }
                if self.delegate.selectedMode() == .loadFile {
                    self.delegate.validated()
                } else {
                    if self.validatePassword() == nil, self.validateConfirm() == nil {
                        self.delegate.validated()
                    }
                }
                return nil
            })
            inputBox2.set(validator: { text in
                if let error = self.validatePassword() {
                    return error
                }
                if self.validateName() == nil, self.validateConfirm() == nil {
                    self.delegate.validated()
                }
                return nil
            })
            inputBox3.set(validator: { text in
                if let error = self.validateConfirm() {
                    return error
                }
                if self.validateName() == nil, self.validatePassword() == nil {
                    self.delegate.validated()
                }
                return nil
            })
        }
        
        if let bundles = loader.bundle {
            DispatchQueue.global().async {
                self.isWorking = true
                for bundle in bundles {
                    let address = bundle.keys.first!
                    if address.hasPrefix("hx") {
                        guard let balance = Manager.icon.getBalance(address: address) else { continue }
                        self.bundleBalances[address] = balance
                    } else {
                        guard let balance = Ethereum.requestBalance(address: address) else { continue }
                        self.bundleBalances[address] = balance
                    }
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
                DispatchQueue.main.async {
                    self.isWorking = false
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        DispatchQueue.main.async {
            self.tableView.tableHeaderView?.layoutIfNeeded()
        }
    }
}

extension LoadNameViewController {
    func validateName() -> String? {
        let text = inputBox1.text
        guard text.count > 0 else {
            self.delegate.invalidated()
            return text
        }
        guard Validator.validateBlankString(string: text) else {
            self.delegate.invalidated()
            return text
        }
        guard DB.canSaveWallet(name: text.removeContinuosCharacter(string: " ")) else {
            self.delegate.invalidated()
            return "Error.Wallet.Duplicated.Name".localized
        }
        delegate.loader?.name = text
        return nil
    }
    
    func validatePassword() -> String? {
        let text = inputBox2.text
        guard text.count > 0 else {
            self.delegate.invalidated()
            return text
        }
        guard text.count >= 8 else {
            delegate.invalidated()
            return "Error.Password.Length".localized
        }
        guard Validator.validateCharacterSet(password: text) else {
            delegate.invalidated()
            return "Error.Password.CharacterSet".localized
        }
        guard Validator.validateSequenceNumber(password: text) else {
            delegate.invalidated()
            return "Error.Password.Serialize".localized
        }
        guard Validator.validateCharacterSet(password: text) else {
            delegate.invalidated()
            return "Error.Password.Invaild.SpecialCharacter".localized
        }
        return nil
    }
    
    func validateConfirm() -> String? {
        let text1 = inputBox2.text, text2 = inputBox3.text
        guard text1 == text2 else {
            delegate.invalidated()
            return "Error.Password.Mismatch".localized
        }
        delegate.loader?.password = text1
        return nil
    }
}

extension LoadNameViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let loader = delegate.loader, let bundleList = loader.bundle else { return 0 }
        return bundleList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BundleLoadCell", for: indexPath) as! BundleLoadCell
        
        guard let loader = delegate.loader, let bundleList = loader.bundle else { return cell }
        let bundleDic = bundleList[indexPath.row]
        let key = bundleDic.keys.first!
        let bundle = bundleDic[key]!
        
        let canSave = DB.canSaveWallet(address: key)
        let textColor: (UIColor, UIColor) = {
            return canSave ? (.gray77, .gray179) : (.gray179, .mint1)
        }()
        let subtitle: String = {
            return canSave ? key : "LoadName.Bundle.DuplicatedAddress".localized + " - \(key)"
        }()
        
        cell.walletNameLabel.size14(text: bundle.name, color: textColor.0, weight: .semibold)
        cell.subtitleLabel.size10(text: subtitle, color: textColor.1, weight: .light, align: .left)
        cell.valueLabel.size14(text: "-")
        
        if let balance = bundleBalances[key] {
            cell.valueLabel.isHidden = false
            cell.indicator.isHidden = true
            cell.valueLabel.size14(text: balance.toString(decimal: 18, 4, false) + (bundle.type == "icx" ? " ICX" : " ETH"), color: textColor.0, weight: .bold)
        } else {
            if isWorking {
                cell.valueLabel.isHidden = true
                cell.indicator.isHidden = false
            } else {
                cell.valueLabel.isHidden = false
                cell.indicator.isHidden = true
                cell.valueLabel.size14(text: "-", color: textColor.0, weight: .bold)
            }
        }
        
        return cell
    }
}

extension LoadNameViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 36))
        headerView.backgroundColor = .gray250
        
        let line1 = UIView()
        line1.backgroundColor = .gray230
        headerView.addSubview(line1)
        line1.translatesAutoresizingMaskIntoConstraints = false
        line1.topAnchor.constraint(equalTo: headerView.topAnchor).isActive = true
        line1.leadingAnchor.constraint(equalTo: headerView.leadingAnchor).isActive = true
        line1.trailingAnchor.constraint(equalTo: headerView.trailingAnchor).isActive = true
        line1.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        
        let line2 = UIView()
        line2.backgroundColor = .gray230
        headerView.addSubview(line2)
        line2.translatesAutoresizingMaskIntoConstraints = false
        line2.bottomAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        line2.leadingAnchor.constraint(equalTo: headerView.leadingAnchor).isActive = true
        line2.trailingAnchor.constraint(equalTo: headerView.trailingAnchor).isActive = true
        line2.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        
        if let loader = delegate.loader, let bundleList = loader.bundle {
            let label = UILabel()
            headerView.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.topAnchor.constraint(equalTo: headerView.topAnchor).isActive = true
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20).isActive = true
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20).isActive = true
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
            label.size12(text: String(format: "LoadName.Bundle.TotalWallets".localized, "\(bundleList.count)"), color: .gray128, weight: .light)
            
            let loaded = bundleList.map { DB.canSaveWallet(address: $0.keys.first!) ? 0 : 1 }.reduce(0, +)
            if loaded > 0 {
                let loadedWallet = UILabel()
                headerView.addSubview(loadedWallet)
                loadedWallet.translatesAutoresizingMaskIntoConstraints = false
                loadedWallet.topAnchor.constraint(equalTo: headerView.topAnchor).isActive = true
                loadedWallet.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20).isActive = true
                loadedWallet.bottomAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
                loadedWallet.size12(text: String(format: "LoadName.Bundle.AlreadyLoaded".localized, "\(loaded)"), color: .mint1)
            }
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }
}
