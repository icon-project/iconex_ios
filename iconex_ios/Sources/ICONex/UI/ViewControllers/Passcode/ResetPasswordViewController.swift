//
//  ResetPasswordViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 18/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import BigInt
import PanModal

class WalletListTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var symbolLabel: UILabel!
}

class ResetPasswordViewController: BaseViewController {
    
    @IBOutlet weak var navBar: PopableTitleView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var closeButton: UIButton!
    
    var walletList: BehaviorSubject<[BaseWalletConvertible]>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rx.setDelegate(self).disposed(by: disposeBag)
        
        walletList = BehaviorSubject<[BaseWalletConvertible]>(value: Manager.wallet.walletList)
        
        setupUI()
        setupBind()
    }
    
    private func setupUI() {
        navBar.actionHandler = {
            self.dismiss(animated: true, completion: nil)
        }
        navBar.setButtonImage(image: #imageLiteral(resourceName: "icAppbarClose"))
        
        navBar.set(title: "Passcode.Reset".localized)
        headerLabel.size16(text: "Passcode.Reset.withWallet".localized, color: .gray77, weight: .medium, align: .center)
        
        closeButton.round02()
    }
    
    private func setupBind() {
        
        closeButton.rx.tap.asControlEvent().subscribe { (_) in
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        walletList.observeOn(MainScheduler.instance)
            .bind(to: tableView.rx.items(cellIdentifier: "walletCell", cellType: WalletListTableViewCell.self)) {
                (_, item, cell) in

                cell.nameLabel.size14(text: item.name, color: .gray77, weight: .semibold)
                
                let balance = item.balance ?? 0
                cell.balanceLabel.size14(text: balance.toString(decimal: 18, 4).currencySeparated(), color: .gray77, weight: .bold, align: .right)

                if let _ = item as? ICXWallet {
                    cell.symbolLabel.size14(text: "ICX", color: .gray77, weight: .bold, align: .right)
                } else {
                    cell.symbolLabel.size14(text: "ETH", color: .gray77, weight: .bold, align: .right)
                }
                
            }.disposed(by: disposeBag)
        
        tableView.rx.modelSelected(BaseWalletConvertible.self).asControlEvent()
            .subscribe(onNext: { (wallet) in
                Alert.password(wallet: wallet, returnAction: { (_) in
                    let setPassword = self.storyboard?.instantiateViewController(withIdentifier: "Passcode") as! PasscodeViewController
                    setPassword.lockType = .activate
                    setPassword.modalPresentationStyle = .fullScreen
                    self.present(setPassword, animated: true, completion: nil)
                }).show()
            }).disposed(by: disposeBag)
    }
}
extension ResetPasswordViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let count = try? self.walletList.value().count else { return nil }
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 36))
        
        let label = UILabel()
        label.size12(text: String(format: "Passcode.Count".localized, "\(count)"), color: .gray77, weight: .light)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 3).isActive = true
        
        view.backgroundColor = .gray250
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

extension ResetPasswordViewController: PanModalPresentable {
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
