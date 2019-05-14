//
//  TokenAddListViewController.swift
//  iconex_ios
//
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum TokenSelectState {
    case none, added, selected
}

class TokenAddListCell: UITableViewCell {
    @IBOutlet weak var tokenName: UILabel!
    @IBOutlet weak var checkBox: UIButton!
    @IBOutlet weak var arrow: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var arrowButton: UIButton!
    @IBOutlet weak private var bottomContainer: UIView!
    @IBOutlet weak var height: NSLayoutConstraint!
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        _isExpand = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    var state: TokenSelectState = .none {
        willSet {
            switch newValue {
            case .none:
                checkBox.isSelected = false
                checkBox.isEnabled = true
                selectButton.isEnabled = true
                tokenName.textColor = UIColor(38, 38, 38)
                addressLabel.textColor = UIColor(38, 38, 38)
                
            case .added:
                checkBox.isEnabled = false
                selectButton.isEnabled = false
                tokenName.textColor = UIColor(38, 38, 38, 0.3)
                addressLabel.textColor = UIColor(38, 38, 38, 0.3)
                
            case .selected:
                checkBox.isEnabled = true
                checkBox.isSelected = true
                selectButton.isEnabled = true
                tokenName.textColor = UIColor(38, 38, 38)
                addressLabel.textColor = UIColor(38, 38, 38)
            }
        }
    }
    
    private var _isExpand: Bool = false {
        willSet {
            arrow.isHighlighted = newValue
            height.constant = newValue ? 100 : 60
        }
    }
    
    var isExpanded: Bool {
        return _isExpand
    }
    
    func expand() {
        _isExpand = !_isExpand
    }
}

struct FixedToken: Decodable {
    var name: String
    var symbol: String
    var decimal: Int
    var address: String
}

class TokenAddListViewController: BaseViewController {
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableFooterLabel: UILabel!
    @IBOutlet weak var tableFooterButton: UIButton!
    @IBOutlet weak var actionButton: UIButton!
    
    var walletInfo: WalletInfo?
    
    private var tokenList = [FixedToken]()
    private var selectedTokens = [String: FixedToken]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }

    func initialize() {
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        
        backButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            self.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
        
        tableFooterButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            let manage = UIStoryboard(name: "Menu", bundle: nil).instantiateViewController(withIdentifier: "TokenManageView") as! TokenManageViewController
            manage.walletInfo = self.walletInfo
            manage.manageMode = .add
            self.navigationController?.pushViewController(manage, animated: true)
        }).disposed(by: disposeBag)
        
        actionButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            Log.Debug(self.selectedTokens)
            
            guard let wallet = DB.walletBy(info: self.walletInfo!) as? ICXWallet else { return }
            for info in self.selectedTokens.values {
                do {
                    let token = TokenInfo(name: info.name, defaultName: info.name, symbol: info.symbol, decimal: info.decimal, defaultDecimal: info.decimal, dependedAddress: wallet.address!, contractAddress: info.address, parentType: "icx")
                    try DB.addToken(tokenInfo: token)
                } catch {
                    continue
                }
            }
            self.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        navTitle.text = "Token.Management".localized
        
        tableFooterLabel.text = "Token.Add.InputInfo".localized
        tableFooterButton.styleDark()
        tableFooterButton.setTitle("Token.Add.Input".localized, for: .normal)
        tableFooterButton.cornered()
        
        actionButton.styleLight()
        actionButton.rounded()
        actionButton.setTitle("Common.Add".localized, for: .normal)
        actionButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadData()
    }
    
    func loadData() {
        selectedTokens.removeAll()
        tokenList.removeAll()
        guard let path = Bundle.main.path(forResource: "Tokens", ofType: "json"), let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else { return }
        let decoder = JSONDecoder()
        guard let array = try? decoder.decode([FixedToken].self, from: data) else { return }
        tokenList.append(contentsOf: array.sorted(by: { (a, b) -> Bool in
            return a.name < b.name
            }))
        tableView.reloadData()
        self.actionButton.isEnabled = false
    }
}

extension TokenAddListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tokenList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TokenAddListCell", for: indexPath) as! TokenAddListCell
        
        let info = tokenList[indexPath.row]
        
        cell.arrowButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            cell.expand()
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }).disposed(by: cell.disposeBag)
        
        cell.selectButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [ unowned self] in
            if self.selectedTokens[info.address] != nil {
                self.selectedTokens[info.address] = nil
                cell.state = .none
            } else {
                self.selectedTokens[info.address] = info
                cell.state = .selected
            }
            self.actionButton.isEnabled = self.selectedTokens.count != 0
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }).disposed(by: cell.disposeBag)
        
        cell.tokenName.text = info.name
        cell.addressLabel.text = info.address
        
        let wallet = DB.walletBy(info: walletInfo!) as! ICXWallet
        if !wallet.canSaveToken(contractAddress: info.address) {
            cell.state = .added
        } else {
            if selectedTokens[info.address] != nil {
                cell.state = .selected
            } else {
                cell.state = .none
            }
        }
        
        return cell
    }
}

extension TokenAddListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
