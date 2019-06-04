//
//  LockSettingViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class LockSettingRadioCell: UITableViewCell {
    @IBOutlet weak var cellTitle: UILabel!
    @IBOutlet weak var radio: UISwitch!
    private(set) var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }
}

class LockSettingCell: UITableViewCell {
    @IBOutlet weak var cellTitle: UILabel!
    
}

class LockSettingViewController: UIViewController {
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var headerTop: NSLayoutConstraint!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }
    
    func initialize() {
        tableView.isScrollEnabled = false
        
        closeButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                self.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        tableView.tableFooterView = UIView()
        
        navTitle.text = "Side.ScreenLock".localized
        headerLabel.text = "LockScreen.Setting.Header".localized
        descLabel.text = "LockScreen.Setting.Desc1".localized
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
        viewWillLayoutSubviews()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if UserDefaults.standard.bool(forKey: "useLock") {
            headerTop.constant = -headerView.frame.height
        } else {
            headerTop.constant = 0
        }
        
    }
}

extension LockSettingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard UserDefaults.standard.bool(forKey: "useLock") else {
            return 1
        }
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LockSettingRadioCell", for: indexPath) as! LockSettingRadioCell
            cell.cellTitle.text = "LockScreen.Setting.useFunction".localized
            cell.radio.isOn = UserDefaults.standard.bool(forKey: "useLock")
            cell.radio.rx.controlEvent(UIControl.Event.valueChanged)
                .subscribe(onNext: {
                    let createLock = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "CreateLockView") as! CreateLockViewController
                    if cell.radio.isOn {
                        createLock.mode = CreateLockViewController.CreateLockMode.create
                    } else {
                        createLock.mode = CreateLockViewController.CreateLockMode.remove
                    }
                    self.navigationController?.pushViewController(createLock, animated: true)
                    
                    tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
                }).disposed(by: cell.disposeBag)
            return cell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LockSettingCell", for: indexPath) as! LockSettingCell
            cell.cellTitle.text = "LockScreen.Setting.ChangeCode".localized
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LockSettingRadioCell", for: indexPath) as! LockSettingRadioCell
            switch Tools.biometryType() {
            case "Touch ID":
                cell.cellTitle.text = "LockScreen.Setting.useBiometrics.TouchID".localized
                
            case "Face ID":
                cell.cellTitle.text = "LockScreen.Setting.useBiometrics.FaceID".localized
                
            default:
                break
            }
            cell.radio.isOn = UserDefaults.standard.bool(forKey: "useBio")
            cell.radio.rx.controlEvent(UIControl.Event.valueChanged)
                .subscribe(onNext: { [unowned self] in
                    if cell.radio.isOn {
                        let status = Tools.canVerificateTouchID()
                        if status == Tools.LAStatus.success {
                            let bio = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "BioAuthView")
                            self.navigationController?.pushViewController(bio, animated: true)
                        } else {
                            if status == Tools.LAStatus.locked {
                                var title = "Error.TouchID.Locked".localized
                                if Tools.biometryType() == "Face ID" {
                                    title = "Error.FaceID.Locked".localized
                                }
                                Alert.Basic(message: title).show(self)
                            } else if status == Tools.LAStatus.notUsed {
                                var title = "Error.TouchID.NotEnrolled".localized
                                if Tools.biometryType() == "Face ID" {
                                    title = "Error.FaceID.NotEnrolled".localized
                                }
                                Alert.Basic(message: title).show(self)
                            } else if status == Tools.LAStatus.passcodeNotSet {
                                Alert.Basic(message: "Alert.Bio.passcodeNotSet".localized).show(self)
                            }
                            cell.radio.isOn = false
                        }
                    } else {
                        Tools.removeTouchID()
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                }).disposed(by: cell.disposeBag)
            return cell
        }
    }
}

extension LockSettingViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 1 {
            let createLock = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "CreateLockView") as! CreateLockViewController
            createLock.mode = CreateLockViewController.CreateLockMode.change
            self.navigationController?.pushViewController(createLock, animated: true)
        }
    }
}
