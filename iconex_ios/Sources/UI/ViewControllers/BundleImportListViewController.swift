//
//  BundleImportListViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import BigInt
import ICONKit

class BundleImportCell: UITableViewCell {
    @IBOutlet weak var walletName: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var registeredView: UIView!
    @IBOutlet weak var registeredLabel: UILabel!
    @IBOutlet weak var loadingView: UIImageView!
    
    var isLoading: Bool = false {
        willSet {
            if newValue {
                balanceLabel.isHidden = newValue
                loadingView.isHidden = !newValue
                Tools.rotateAnimation(inView: loadingView)
            } else {
                balanceLabel.isHidden = newValue
                loadingView.isHidden = !newValue
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        registeredLabel.text = "BundleImport.TableHeader.Registered".localized
        registeredView.corner(registeredView.frame.height / 2)
    }
    
    func setInfo() {
        
    }
}

class BundleImportListViewController: BaseViewController {
    @IBOutlet weak var navTitle: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableHeaderLabel: UILabel!
    @IBOutlet weak var tableHeaderDesc: UILabel!
    @IBOutlet weak var tableHeaderCount: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var importButton: UIButton!
    
    private var _queue = Set<String>()
    private var _balanceList = [String: BigUInt]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let list = WCreator.newBundle else {
            return
        }
        
        let registered = list.compactMap({ value -> Int in
            let address = value.keys.first!
            return WManager.canSaveWallet(address: address) ? 0 : 1
        }).reduce(0, +)
        
        var language = ""
        if let selected = UserDefaults.standard.string(forKey: "selectedLanguage") {
            language = selected
        } else {
            let appleLan = UserDefaults.standard.array(forKey: "AppleLanguages")![0] as! String
            let strip = String(appleLan.prefix(2))
            language = strip
        }
        
        if language == "ko" {
            let former = NSAttributedString(string: String(format: "BundleImport.TableHeader.Total.Prefix".localized ,"\(list.count)"))
            let latter = NSAttributedString(string: String(format: "BundleImport.TableHeader.Total.Postfix".localized, "\(registered)"), attributes: [.foregroundColor: UIColor.lightTheme.background.normal])
            
            let attr = NSMutableAttributedString(attributedString: former)
            attr.append(latter)
            
            tableHeaderCount.attributedText = attr
        } else {
            let latter = NSAttributedString(string: String(format: "BundleImport.TableHeader.Total.Prefix".localized ,"\(list.count)"))
            let former = NSAttributedString(string: String(format: "BundleImport.TableHeader.Total.Postfix".localized + " ", "\(registered)"), attributes: [.foregroundColor: UIColor.lightTheme.background.normal])
            
            let attr = NSMutableAttributedString(attributedString: former)
            attr.append(latter)
            
            tableHeaderCount.attributedText = attr
        }
        
        for bundle in list {
            let address = bundle.keys.first!
            let value = bundle[address]!
            
            self._queue.insert(address)
            
            if value.type.lowercased() == "icx" {
                let request = WManager.service.getBalance(address: address)
                DispatchQueue.main.async {
                    let result = request.execute()
                    
                    switch result {
                    case .success(let value):
                        self._balanceList[address] = value.value
                        WManager.walletBalanceList[address] = value.value
                        
                    case .failure(let error):
                        Log.Debug("Error - \(error)")
                    }
                    
                    self._queue.remove(address)
                    
                    self.tableView.reloadData()
                }
                
            } else {
                
                DispatchQueue.global(qos: .utility).async { [unowned self] in
                    let client = EthereumClient(address: address)
                    
                    client.requestBalance { (optionalValue, _) in
                        DispatchQueue.main.async {
                            self._queue.remove(address)
                            guard let value = optionalValue else {
                                self.tableView.reloadData()
                                return
                            }
                            
                            self._balanceList[address] = value
                            WManager.walletBalanceList[address.add0xPrefix()] = value
                            self.tableView.reloadData()
                        }
                        }.fetch()
                }
            }
        }
        tableView.reloadData()
    }
    
    func initialize() {
        
        cancelButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        importButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: {
            
            
            WCreator.saveBundle()
            let app = UIApplication.shared.delegate as! AppDelegate
            if let root = app.window?.rootViewController, let main = root as? MainViewController {
                main.currentIndex = 0
                main.loadWallets()
            } else {
                let main = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                app.window?.rootViewController = main
            }
            app.window?.rootViewController?.dismiss(animated: true, completion: {
                let app = UIApplication.shared.delegate as! AppDelegate
                let root = app.window!.rootViewController!
                Alert.Basic(message: "Alert.Bundle.Import.Success".localized).show(root)
            })
            
            
            
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        navTitle.text = "BundleImport.NavTitle".localized
        tableHeaderLabel.text = "BundleImport.TableHeader.Title".localized
        tableHeaderDesc.text = "BundleImport.TableHeader.Desc".localized
        var language = ""
        if let selected = UserDefaults.standard.string(forKey: "selectedLanguage") {
            language = selected
        } else {
            let appleLan = UserDefaults.standard.array(forKey: "AppleLanguages")![0] as! String
            let strip = String(appleLan.prefix(2))
            language = strip
        }
        if language == "ko" {
            tableHeaderCount.text = String(format: "BundleImport.TableHeader.Total.Prefix".localized + "BundleImport.TableHeader.Total.Postfix".localized, "0", "0")
        } else {
            tableHeaderCount.text = String(format: "BundleImport.TableHeader.Total.Postfix".localized + "BundleImport.TableHeader.Total.Prefix".localized , "0", "0")
        }
        
        cancelButton.styleDark()
        cancelButton.setTitle("Common.Cancel".localized, for: .normal)
        cancelButton.rounded()
        importButton.styleLight()
        importButton.setTitle("Import.Step2.Button.Title".localized, for: .normal)
        importButton.rounded()
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 1))
    }
}

extension BundleImportListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let bundle = WCreator.newBundle else {
            return 0
        }
        return bundle.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BundleImportCell") as! BundleImportCell
        
        if let list = WCreator.newBundle {
            let bundle = list[indexPath.row]
            let address = bundle.keys.first!
            let canSaveAddress = WManager.canSaveWallet(address: address)
            cell.registeredView.isHidden = canSaveAddress
            
            cell.balanceLabel.textColor = canSaveAddress ? UIColor(38,38,38) : UIColor(38, 38, 38, 0.3)
            cell.walletName.textColor = canSaveAddress ? UIColor(38,38,38) : UIColor(38, 38, 38, 0.3)
            cell.unitLabel.textColor = canSaveAddress ? UIColor(38,38,38) : UIColor(38, 38, 38, 0.3)
            
            let value = bundle[address]!
            var name = value.name
            if canSaveAddress {
                var count = 0
                repeat {
                    if count != 0 {
                        name = name + " (\(count))"
                    }
                    count += 1
                } while !WManager.canSaveWallet(alias: name)
            }
            cell.walletName.text = name
            cell.unitLabel.text = value.type.uppercased()
            if let balance = _balanceList[address] {
                cell.isLoading = false
                cell.balanceLabel.text = Tools.bigToString(value: balance, decimal: 18, 18, true, true)
            } else if _queue.contains(address) {
                cell.isLoading = true
            } else {
                cell.isLoading = false
                cell.balanceLabel.text = "-"
            }
        }
        
        return cell
    }
}
