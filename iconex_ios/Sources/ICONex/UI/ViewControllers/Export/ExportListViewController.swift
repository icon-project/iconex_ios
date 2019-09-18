//
//  ExportListViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 03/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ExportListCell: UITableViewCell {
    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var walletName: UILabel!
    @IBOutlet weak var walletBalance: UILabel!
    
}

class ExportListViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: ExportWalletSequence!
    
    private var selected = [String: (BaseWalletConvertible, String)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.numberOfLines = 0
        
        let descContainer = UIView()
        descContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let desc1 = UILabel()
        desc1.translatesAutoresizingMaskIntoConstraints = false
        desc1.numberOfLines = 0
        
        let desc2 = UILabel()
        desc2.translatesAutoresizingMaskIntoConstraints = false
        desc2.numberOfLines = 0
        
        tableView.tableHeaderView = headerView
        
        headerView.addSubview(headerLabel)
        headerView.addSubview(descContainer)
        descContainer.addSubview(desc1)
        descContainer.addSubview(desc2)
        
        headerLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 40).isActive = true
        headerLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 40).isActive = true
        headerLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -40).isActive = true
        
        descContainer.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 30).isActive = true
        descContainer.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20).isActive = true
        descContainer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20).isActive = true
        descContainer.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -20).isActive = true
        
        desc1.topAnchor.constraint(equalTo: descContainer.topAnchor, constant: 20).isActive = true
        desc1.leadingAnchor.constraint(equalTo: descContainer.leadingAnchor, constant: 20).isActive = true
        desc1.trailingAnchor.constraint(equalTo: descContainer.trailingAnchor, constant: -20).isActive = true
        
        desc2.topAnchor.constraint(equalTo: desc1.bottomAnchor, constant: 12).isActive = true
        desc2.leadingAnchor.constraint(equalTo: descContainer.leadingAnchor, constant: 20).isActive = true
        desc2.trailingAnchor.constraint(equalTo: descContainer.trailingAnchor, constant: -20).isActive = true
        desc2.bottomAnchor.constraint(equalTo: descContainer.bottomAnchor, constant: -20).isActive = true
        
        headerView.topAnchor.constraint(equalTo: tableView.topAnchor).isActive = true
        headerView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        headerView.widthAnchor.constraint(equalTo: tableView.widthAnchor).isActive = true
        
        headerLabel.size16(text: "ExportList.TableHeader.Header".localized, color: .gray77, weight: .medium, align: .center, lineBreakMode: .byWordWrapping)
        
        desc1.size12(text: "ExportList.TableHeader.Desc1".localized, color: .mint1, align: .left, lineBreakMode: .byWordWrapping)
        desc2.size12(text: "ExportList.TableHeader.Desc2".localized, color: .mint1, align: .left, lineBreakMode: .byWordWrapping)
        
        descContainer.border(1.0, .mint3)
        descContainer.backgroundColor = .mint4
        descContainer.corner(8)
        
        tableView.tableHeaderView?.layoutIfNeeded()
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        tableView.tableHeaderView?.layoutIfNeeded()
    }
    
    func resetData() {
        selected.removeAll()
        delegate.set(bundle: nil)
        tableView.reloadData()
    }
}

extension ExportListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Manager.wallet.walletList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExportListCell", for: indexPath) as! ExportListCell
        
        let wallet = Manager.wallet.walletList[indexPath.row]
        cell.walletName.text = wallet.name
        let balance: String = {
            if let bString = wallet.balance?.toString(decimal: 18, 4, false) {
                return bString + (wallet.address.hasPrefix("hx") ? " ICX" : " ETH")
            } else {
                return "-"
            }
        }()
        cell.walletBalance.text = balance
        cell.checkImage.isHighlighted = selected[wallet.address] != nil
        Log("Wallet address \(wallet.address)")
        return cell
    }
}

extension ExportListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let wallet = Manager.wallet.walletList[indexPath.row]
        
        if self.selected[wallet.address] != nil {
            self.selected[wallet.address] = nil
            if self.selected.count == 0 {
                self.delegate.set(bundle: nil)
                self.delegate.invalidated()
            }
            tableView.reloadData()
        } else {
            Alert.password(wallet: wallet) { (prv) in
                
                if let icx = wallet as? ICXWallet {
                    self.selected[wallet.address] = (icx, prv)
                    
                } else if let eth = wallet as? ETHWallet {
                    self.selected[wallet.address] = (eth, prv)
                    
                } else {
                    
                }
                
                Log("selected \(self.selected)")
                
                let bundleList = self.selected.map { $1 }
                
                self.delegate.set(bundle: bundleList)
                self.delegate.validated()
                
                tableView.reloadData()
                }.show()
        }
    }
}
