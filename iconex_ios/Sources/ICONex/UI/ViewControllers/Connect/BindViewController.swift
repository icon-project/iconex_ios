//
//  BindViewController.swift
//  iconex_ios
//
//  Created by Seungyeon Lee on 2019/09/08.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import PanModal

class BindCell: UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var balance: UILabel!
    @IBOutlet weak var symbol: UILabel!
    @IBOutlet weak var address: UILabel!
}

class BindViewController: BaseViewController {
    @IBOutlet weak var navBar: PopableTitleView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cancelButton: UIButton!
    
    var walletList: [BaseWalletConvertible]?
    
    var selectedIndex: IndexPath? {
        didSet {
            self.cancelButton.isEnabled = self.selectedIndex != nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        initializeUI()
        loadWallet()
    }
    
    func initializeUI() {
        navBar.set(title: "Connect.Select.Title".localized)
        
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        
        self.cancelButton.gray()
        self.cancelButton.setTitle("Common.Cancel".localized, for: .normal)
        
        navBar.actionHandler = {
            Alert.basic(title: "Alert.Connect.Select.Cancel1".localized, subtitle: "Alert.Connect.Select.Cancel2".localized, confirmAction: {
                self.dismiss(animated: true, completion: nil)
                Conn.sendError(error: ConnectError.userCancel)
            }).show()
        }
        
        cancelButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: {
            self.dismiss(animated: true, completion: nil)
            Conn.sendError(error: .userCancel)
        }).disposed(by: disposeBag)
        
        balanceListDidChanged().observeOn(MainScheduler.instance).subscribe(onNext: { _ in
            self.tableView.reloadData()
        }).disposed(by: disposeBag)
    }
    
    func loadWallet() {
        self.walletList = Manager.wallet.walletList.filter({ $0 is ICXWallet })
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "bindCell") as! BindCell
        
        cell.name.text = "-"
        cell.address.text = "-"
        cell.balance.text = "-"
        cell.symbol.size14(text: "ICX", color: .gray77, align: .right)
        
        let wallet = self.walletList![indexPath.row]
        
        cell.name.size14(text: wallet.name, color: .gray77, weight: .semibold)
        cell.address.size10(text: wallet.address, color: .gray179, weight: .light)
        
        if let balance = wallet.balance {
            cell.balance.size14(text: balance.toString(decimal: wallet.decimal, 4).currencySeparated(), color: .gray77, weight: .bold)
        }
        
        return cell
    }
}

extension BindViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndex = indexPath
        
        guard let list = self.walletList, let path = self.selectedIndex else { return }
        let info = list[path.row]
        let address = info.address
        self.dismiss(animated: true, completion: nil)
        Conn.sendBind(address: address)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

extension BindViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return false
    }
    
    var isHapticFeedbackEnabled: Bool {
        return false
    }
    
    var topOffset: CGFloat {
        return app.window!.safeAreaInsets.top
    }
    
    var backgroundAlpha: CGFloat {
        return 0.4
    }
    
    var cornerRadius: CGFloat {
        return 18.0
    }
}
