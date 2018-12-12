//
//  AddressManageViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class AddressBookCell: UITableViewCell {
    @IBOutlet weak var addressTitle: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }
}

class RecentAddressCell: UITableViewCell {
    @IBOutlet weak var addressTitle: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    
}

class MyWalletCell: UITableViewCell {
    @IBOutlet weak var walletName: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    
}


class AddressManageViewController: UIViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var topTitle: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var segmentView: UIView!
    @IBOutlet weak var segAddressButton: UIButton!
    @IBOutlet weak var segWalletButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var noItemContainer: UIView!
    @IBOutlet weak var noItemLabel: UILabel!
    @IBOutlet weak var addContainer: UIView!
    
    let disposeBag = DisposeBag()
    
    var walletInfo: WalletInfo!
    var walletList: [WalletInfo]!
    var addressBookList = [AddressBookInfo]()
    
    var selectHandler: ((_ address: String) -> Void)?
    
    var selectedIndex: Int = 0 {
        didSet {
            switch selectedIndex {
            case 0:
                segAddressButton.isSelected = true
                segWalletButton.isSelected = false
                editButton.isHidden = addressBookList.count == 0
                addContainer.isHidden = false
                
            case 1:
                segAddressButton.isSelected = false
                segWalletButton.isSelected = true
                editButton.isHidden = true
                tableView.isEditing = false
                addContainer.isHidden = true
                
            default:
                break
            }
            
            setUnderlineView(index: selectedIndex)
            
            tableView.reloadData()
            
            if selectedIndex == 0 {
                noItemContainer.isHidden = addressBookList.count != 0
                noItemLabel.text = "AddressBook.Empty".localized
                noItemLabel.textColor = UIColor(38, 38, 38, 0.5)
            } else {
                noItemLabel.text = "AddressBook.NoWallets".localized
                noItemContainer.isHidden = walletList.count != 0
            }
            
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeUI()
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initializeUI() {
        topTitle.text = "AddressBook.Select".localized
        editButton.setTitle("Common.Edit".localized, for: .normal)
        
        let addressNormal = NSAttributedString(string: "AddressBook.AddressBook".localized, attributes: [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.black])
        let addressSelected = NSAttributedString(string: "AddressBook.AddressBook".localized, attributes: [.font: UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.bold), .foregroundColor: UIColor.black])
        let walletNormal = NSAttributedString(string: "AddressBook.MyWallet".localized, attributes: [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.black])
        let walletSelected = NSAttributedString(string: "AddressBook.MyWallet".localized, attributes: [.font: UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.bold), .foregroundColor: UIColor.black])
        
        segAddressButton.setAttributedTitle(addressNormal, for: .normal)
        segAddressButton.setAttributedTitle(addressSelected, for: .selected)
        segWalletButton.setAttributedTitle(walletNormal, for: .normal)
        segWalletButton.setAttributedTitle(walletSelected, for: .selected)
        
        tableView.tableFooterView = UIView()
        
        addButton.styleDark()
        addButton.cornered()
        addButton.setTitle("AddressBook.Add".localized, for: .normal)
    }
    
    func initialize() {
        closeButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [weak self] in
            self?.view.endEditing(true)
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        editButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            self.tableView.setEditing(!self.tableView.isEditing, animated: true)
            self.tableView.isEditing ? self.editButton.setTitle("Common.Done".localized, for: .normal) : self.editButton.setTitle("Common.Edit".localized, for: .normal)
            self.tableView.reloadData()
        }).disposed(by: disposeBag)
        
        segAddressButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            self.selectedIndex = 0
        }).disposed(by: disposeBag)
        segWalletButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            self.selectedIndex = 1
        }).disposed(by: disposeBag)
        
        addButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                Alert.editingAddress(mode: .add, type: self.walletInfo.type, handler: {
                    
                    self.loadWalletList()
                    
                }).show(self)
            }).disposed(by: disposeBag)
        
        loadWalletList()
        
        selectedIndex = 0
    }
    
    func setUnderlineView(index: Int) {
        if let view = segmentView.viewWithTag(8) {
            view.removeFromSuperview()
        }
        
        let width = segmentView.frame.size.width / 2
        let y = segmentView.frame.size.height - 4
        let underView = UIView(frame: CGRect(x: width * CGFloat(index), y: y, width: width, height: 4))
        underView.backgroundColor = UIColor.black
        underView.tag = 8
        segmentView.addSubview(underView)
    }

    func loadWalletList() {
        addressBookList = AddressBook.loadAddressBookList(by: self.walletInfo.type).filter { $0.address.lowercased() != self.walletInfo.address.lowercased() }
        walletList = WManager.walletInfoList.filter { $0.address.lowercased() != walletInfo.address.lowercased() && $0.type == walletInfo.type }
        
        let value = selectedIndex
        selectedIndex = value
        
        tableView.reloadData()
    }
}

extension AddressManageViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectedIndex == 0 {
            return addressBookList.count
        } else {
            return walletList.count
        }
    }
    
    func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        return 24
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if selectedIndex == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddressBookCell", for: indexPath) as! AddressBookCell
            
            let info = addressBookList[indexPath.row]
            
            cell.addressTitle.text = info.name
            cell.addressLabel.text = info.address
            cell.editButton.isHidden = !tableView.isEditing
            cell.editButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
                let info = self.addressBookList[indexPath.row]
                Alert.editingAddress(name: nil, address: info.address, mode: .edit, type: self.walletInfo.type, handler: {
                    self.loadWalletList()
                }).show(self)
            }).disposed(by: cell.disposeBag)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyWalletCell", for: indexPath) as! MyWalletCell
            
            let walletInfo = walletList[indexPath.row]
            let wallet = WManager.loadWalletBy(info: walletInfo)!
            cell.walletName.text = wallet.alias
            cell.addressLabel.text = wallet.address
            if let balance = WManager.walletBalanceList[wallet.address!] {
                cell.amountLabel.text = Tools.bigToString(value: balance, decimal: wallet.decimal, wallet.decimal, false)
            } else if let balance = WManager.walletBalanceList[wallet.address!] {
                cell.amountLabel.text = Tools.bigToString(value: balance, decimal: wallet.decimal, wallet.decimal, false)
            } else {
                cell.amountLabel.text = "-"
            }
            
            switch wallet.type {
            case .icx:
                cell.unitLabel.text = "ICX"
                
            case .eth:
                cell.unitLabel.text = "ETH"
                
            default:
                break
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var address: String = ""
        switch selectedIndex {
        case 0:
            let addressInfo = addressBookList[indexPath.row]
            address = addressInfo.address
            
        case 1:
            let wallet = walletList[indexPath.row]
            address = wallet.address
            
        default:
            break
        }
        
        if let handler = selectHandler {
            handler(address)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if selectedIndex == 0 { return true }
        
        return false
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Common.Remove".localized) { [unowned self] (action, indexPath) in
            if self.selectedIndex == 0 {
                Alert.Confirm(message: "Alert.AddressBook.Remove".localized, cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: {
                    let address = self.addressBookList[indexPath.row]
                    do {
                        try AddressBook.deleteAddressBook(name: address.name)
                    } catch {
                        Log.Debug("Delete AddressBook Error: \(error)")
                    }
                    
                    self.loadWalletList()
                }).show(self)
            }
        }
        
        return [deleteAction]
    }
}
