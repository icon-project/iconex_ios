//
//  AddTokenViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 26/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AddTokenViewController: BaseViewController {

    @IBOutlet weak var navBar: IXNavigationView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    
    // footer
    @IBOutlet weak var footerLabel: UILabel!
    @IBOutlet weak var addTokenInfoButton: UIButton!
    
    var walletInfo: BaseWalletConvertible? = nil
    
    // tableview list
    var tokenList = PublishSubject<[TokenFile]>()
    
    var checkList: [Token]?
    
    var selectedList = [String: NewToken]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // navBar
        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarBack")) {
            self.navigationController?.popViewController(animated: true)
        }
        navBar.setTitle("ManageToken.Add".localized)
        
        addButton.setTitle("Token.Add".localized, for: .normal)
        addButton.isEnabled = false
        addButton.lightMintRounded()
        
        self.tableView.estimatedRowHeight = 60
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.allowsSelection = false
        
        setupBind()
        
        if let loadToken = loadTokenList()?.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.name < rhs.name
        }) {
            tokenList.onNext(loadToken)
        }
        
        guard let wallet = self.walletInfo else { return }
        self.checkList = try? DB.tokenList(dependedAddress: wallet.address)
    }
    
    private func setupBind() {
        guard let wallet = self.walletInfo else {
            return
        }
        
        tokenList.observeOn(MainScheduler.instance)
            .bind(to: tableView.rx.items(cellIdentifier: "tokenCell", cellType: AddTokenTableViewCell.self)) { index, item, cell in
                
                cell.checkButton.rx.tap.asControlEvent()
                    .subscribe({ (_) in
                        
                        if self.selectedList[item.address] == nil {
                            cell.checkButton.isSelected = true
                            self.selectedList[item.address] = NewToken.init(token: item, parent: wallet)
                        } else {
                            cell.checkButton.isSelected = false
                            self.selectedList.removeValue(forKey: item.address)
                        }
                        
                        self.addButton.rx.isEnabled.onNext(self.selectedList.count > 0)
                        
                    }).disposed(by: cell.cellBag)
                
                cell.nameLabel.size14(text: item.name, color: .gray77)
                cell.contractLabel.size12(text: item.address, color: .gray77)
                
                cell.expandButton.rx.tap.asControlEvent()
                    .subscribe({ (_) in
                        cell.isExpanded.toggle()
                        self.tableView.beginUpdates()
                        self.tableView.endUpdates()
                        
                    }).disposed(by: cell.cellBag)
                
                let checker = self.checkList?.filter({ $0.contract == item.address }).count ?? 0
                
                if checker > 0 {
                    cell.tokenState = .saved
                } else {
                    cell.tokenState = .normal
                }
                
        }.disposed(by: disposeBag)
        
        addButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                for i in self.selectedList {
                    try? wallet.addToken(token: i.value)
                }
                self.navigationController?.popViewController(animated: true)
            }.disposed(by: disposeBag)
        
        footerLabel.size12(text: "Token.Add.Footer.Description".localized, color: .gray128, weight: .light)
        
        addTokenInfoButton.roundGray230()
        addTokenInfoButton.setTitle("Token.Add.Footer.Button".localized, for: .normal)
        
        addTokenInfoButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let addTokenInfoVC = self.storyboard?.instantiateViewController(withIdentifier: "AddTokenInfo") as! AddTokenInfoViewController
                addTokenInfoVC.walletInfo = self.walletInfo
                self.navigationController?.pushViewController(addTokenInfoVC, animated: true)
                
        }.disposed(by: disposeBag)
    }
}

extension AddTokenViewController {
    func loadTokenList(isICX: Bool = true) -> [TokenFile]? {
        let fileName: String = {
            return isICX ? "Tokens" : "ethToken"
        }()

        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let json = try decoder.decode([TokenFile].self, from: data)
                return json
            } catch {
                print("error:\(error)")
            }
        }
        return nil
    }
}
