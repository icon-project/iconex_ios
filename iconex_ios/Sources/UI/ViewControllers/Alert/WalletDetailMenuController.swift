//
//  WalletDetailMenuController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class WalletDetailMenuCell: UITableViewCell {
    @IBOutlet weak var cellIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
}

class WalletDetailMenuController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tabView: UIView!
    
    @IBOutlet weak var tableHeight: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    private var walletInfo: WalletInfo!
    private var items: [(UIImage, String, Int)]?
    private let disposeBag = DisposeBag()
    
    var handler: ((_ index: Int) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initialize() {
        view.alpha = 0.0
        
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [weak self] in
            self?.close(handler: nil)
        }).disposed(by: disposeBag)
        
        let gesture = UITapGestureRecognizer()
        tabView.addGestureRecognizer(gesture)
        gesture.rx.event.subscribe(onNext: { [unowned self] _ in
            self.close()
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        titleLabel.text = "Main.Menu.WalletManage".localized
        let wallet = WManager.loadWalletBy(info: walletInfo)!
        if walletInfo.type == .icx {
            self.items = [(#imageLiteral(resourceName: "icEdit"), wallet.alias!, 0), (#imageLiteral(resourceName: "icBackup"), "Main.Menu.Backup".localized, 2), (#imageLiteral(resourceName: "icSideLock"), "Main.Menu.ChangePassword".localized, 3), (#imageLiteral(resourceName: "icDelete"), "Main.Menu.RemoveWallet".localized, 4)]
        } else if walletInfo.type == .eth {
            self.items = [(#imageLiteral(resourceName: "icEdit"), wallet.alias!, 0), (#imageLiteral(resourceName: "icSetting"), "Main.Menu.TokenManage".localized, 1), (#imageLiteral(resourceName: "icBackup"), "Wallet.Backup".localized, 2), (#imageLiteral(resourceName: "icSideLock"), "Main.Menu.ChangePassword".localized, 3), (#imageLiteral(resourceName: "icDelete"), "Main.Menu.RemoveWallet".localized, 4)]
        }
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1))
        tableHeight.constant = CGFloat(self.items!.count * 60)// + CGFloat(46 + 16)
        
        tableView.reloadData()
    }
}

extension WalletDetailMenuController {
    func present(from: UIViewController, walletInfo: WalletInfo) {
        self.walletInfo = walletInfo
        from.present(self, animated: false) {
            self.bottomConstraint.constant = (CGFloat((60 * self.items!.count + 46 + 16)))
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        initializeUI()
        
        UIView.animate(withDuration: 0.15, animations: {
            self.view.alpha = 1.0
        }) { (bool) in
            self.bottomConstraint.constant = 0
            UIView.animate(withDuration: 0.15, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func close(handler: (() -> Void)? = nil) {
        self.walletInfo = nil
        self.bottomConstraint.constant = (CGFloat((60 * 5 + 46 + 16)))
        UIView.animate(withDuration: 0.15, animations: {
            self.view.layoutIfNeeded()
        }) { (bool) in
            UIView.animate(withDuration: 0.15, animations: {
                self.view.alpha = 0.0
            }) { (bool) in
                self.dismiss(animated: false, completion: {
                    if let completion = handler {
                        completion()
                    }
                })
            }
        }
    }
}

extension WalletDetailMenuController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let items = self.items else {
            return 0
        }
        
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WalletDetailMenuCell", for: indexPath) as! WalletDetailMenuCell
        
        guard let items = self.items else {
            return cell
        }
        
        let item = items[indexPath.row]
        
        cell.cellIcon.image = item.0
        cell.titleLabel.text = item.1
        
        return cell
    }
}

extension WalletDetailMenuController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = self.items![indexPath.row]
        
        guard let handler = self.handler else {
            return
        }
        close {
            handler(item.2)
        }
    }
}
