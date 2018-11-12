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
    
    var selectedIndex: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeUI()
    }

    func initializeUI() {
        navTitle.text = "Connect.Select.Title".localized
        
        self.tableView.reloadData()
    }
}

extension BindViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let infoList = WManager.walletInfoList
        
        return infoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BindCell") as! BindCell
        
        cell.name.text = "-"
        cell.address.text = "-"
        cell.amount.text = "-"
        
        let info = WManager.walletInfoList[indexPath.row]
        if let wallet = WManager.loadWalletBy(info: info) {
            cell.name.text = wallet.alias
            cell.address.text = wallet.address
            if let balance = wallet.balance {
                cell.amount.text = Tools.bigToString(value: balance, decimal: wallet.decimal, 4, false, true)
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
        
    }
}
