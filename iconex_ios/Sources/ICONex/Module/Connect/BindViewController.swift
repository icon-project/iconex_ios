//
//  BindViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 08/11/2018.
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

class BindCell: UITableViewCell {
    @IBOutlet weak var radio: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var amount: UILabel!
    
}

class BindViewController: BaseViewController {
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var confirmButton: UIButton!
    
    var walletList: [WalletInfo]?
    
    var selectedIndex: IndexPath? {
        didSet {
            self.confirmButton.isEnabled = self.selectedIndex != nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeUI()
        
        loadWallet()
    }

    func initializeUI() {
        navTitle.text = "Connect.Select.Title".localized
        
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        
        self.confirmButton.styleDark()
        self.confirmButton.rounded()
        self.confirmButton.setTitle("Common.Confirm".localized, for: .normal)
        self.confirmButton.isEnabled = false
        
        closeButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: {
            Alert.Confirm(message: "Alert.Connect.Select.Cancel".localized, handler: {
                self.dismiss(animated: true, completion: nil)
                Conn.sendError(error: ConnectError.userCancel)
                
            }).show(self)
        }).disposed(by: disposeBag)
        
        confirmButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: {
            guard let list = self.walletList, let path = self.selectedIndex else { return }
            let info = list[path.row]
            let address = info.address
            self.dismiss(animated: true, completion: nil)
            Conn.sendBind(address: address)
        }).disposed(by: disposeBag)
    }
    
    func loadWallet() {
        self.walletList = WManager.walletInfoList.filter({ $0.type == .icx })
        self.tableView.reloadData()
    }
}

extension BindViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let infoList = self.walletList else { return 0 }
        
        return infoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BindCell") as! BindCell
        
        cell.name.text = "-"
        cell.address.text = "-"
        cell.amount.text = "-"
        
        let info = self.walletList![indexPath.row]
        if let wallet = WManager.loadWalletBy(info: info) {
            cell.name.text = wallet.alias
            cell.address.text = wallet.address
            if let balance = wallet.balance {
                cell.amount.text = Tools.bigToString(value: balance, decimal: wallet.decimal, 4, false).currencySeparated()
            }
        }
        
        cell.radio.isHighlighted = false
        if let path = self.selectedIndex {
            if indexPath.row == path.row {
                cell.radio.isHighlighted = true
            }
        }

        return cell
    }
}

extension BindViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndex = indexPath
        
        tableView.reloadData()
    }
}
