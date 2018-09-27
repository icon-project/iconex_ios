//
//  WalletExportViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class WalletExportCell: UITableViewCell {
    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    
}

class WalletExportViewController: UIViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var content1: UILabel!
    @IBOutlet weak var content2: UILabel!
    @IBOutlet weak var selectedLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nextButton: UIButton!
    
    var selectedWallet = [IndexPath: WalletBundleItem]()
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            
            if height != headerFrame.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
    }
    
    func initialize() {
        var height = CGFloat(30 + 12 + 12 + 30 + 16 + 2)
        
        navTitle.text = "BundleExport.Step1.NavTitle".localized

        let header = "BundleExport.Step1.Header".localized
        headerLabel.text = header
        height = height + header.boundingRect(size: CGSize(width: headerLabel.frame.width, height: 999), font: headerLabel.font).height
        
        let con1 = "BundleExport.Step1.Desc_1".localized
        content1.text = con1
        height = height + con1.boundingRect(size: CGSize(width: content1.frame.width, height: 999), font: content1.font).height
        
        let con2 = "BundleExport.Step1.Desc_2".localized
        content2.text = con2
        height = height + con2.boundingRect(size: CGSize(width: content2.frame.width, height: 999), font: content2.font).height
        
        let rect = headerView.frame
        let newRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: height)
        headerView.frame = newRect
        
        nextButton.styleDark()
        nextButton.rounded()
        nextButton.setTitle("Common.Next".localized, for: .normal)
        
        tableView.tableFooterView = UIView()
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        nextButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                Alert.Confirm(message: "Alert.Bundle.Export.Instruction".localized, handler: {
                    let password = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WalletExportPasswordView") as! WalletExportPasswordViewController
                    var items = [WalletBundleItem]()
                    for item in self.selectedWallet {
                        items.append(item.value)
                    }
                    password.items = items
                    self.navigationController?.pushViewController(password, animated: true)
                }).show(self)
            }).disposed(by: disposeBag)
        
        refreshSelection()
        
        if #available(iOS 11, *) {
            tableView.contentInset = UIEdgeInsetsMake(0, 0, (72 + view.safeAreaInsets.bottom), 0)
            tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, (72 + view.safeAreaInsets.bottom), 0)
        } else {
            tableView.contentInset = UIEdgeInsetsMake(0, 0, 72, 0)
            tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 72, 0)
        }
    }

    func refreshSelection() {
        let count = tableView.indexPathsForSelectedRows == nil ? 0 : tableView.indexPathsForSelectedRows!.count
        let attr = NSMutableAttributedString(string: "\(count)", attributes: [.foregroundColor: UIColor.lightTheme.background.normal, .font: UIFont.systemFont(ofSize: 14, weight: .medium)])
        attr.append(NSAttributedString(string: "BundleExport.Step1.Selected".localized, attributes: [.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
        selectedLabel.attributedText = attr
        
        nextButton.isEnabled = count == 0 ? false : true
    }
}

extension WalletExportViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return WManager.walletInfoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WalletExportCell", for: indexPath) as! WalletExportCell
        
        let view = UIView(frame: cell.frame)
        view.backgroundColor = UIColor.clear
        let line = UIView(frame: CGRect(x: 24, y: cell.frame.height, width: cell.frame.width - 24 * 2, height: 1 / UIScreen.main.nativeScale))
        line.backgroundColor = tableView.separatorColor
        view.addSubview(line)
        
        cell.selectedBackgroundView = view
        
        let info = WManager.walletInfoList[indexPath.row]
        let wallet = WManager.loadWalletBy(info: info)!
        cell.nameLabel.text = wallet.alias
        if let balance = WManager.walletBalanceList[wallet.address!] {
            cell.valueLabel.text = Tools.bigToString(value: balance, decimal: wallet.decimal, 4)
        } else {
            cell.valueLabel.text = "-"
        }
        cell.checkImage.isHighlighted = cell.isSelected
        cell.unitLabel.text = wallet.type.rawValue.uppercased()
        
        return cell
    }
}

extension WalletExportViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
        let info = WManager.walletInfoList[indexPath.row]
        Alert.checkPassword(walletInfo: info) { [unowned self] (isSuccess, privKey) in
            if isSuccess {
                let wallet = WManager.loadWalletBy(info: info)!
                self.selectedWallet[indexPath] = (wallet.alias!, privKey, info.type)
            } else {
                self.selectedWallet.removeValue(forKey: indexPath)
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
            self.refreshSelection()
        }.show(self)
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        self.refreshSelection()
    }
}


