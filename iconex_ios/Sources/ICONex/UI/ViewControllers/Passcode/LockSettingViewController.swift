//
//  LockSettingViewController.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 05/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import LocalAuthentication
import BigInt

class SwitchTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
    
    var cellBag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cellBag = DisposeBag()
    }
}

class RightArrowTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    
}

class LockSettingViewController: BaseViewController {
    @IBOutlet weak var navBar: IXNavigationView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var headerHeight: NSLayoutConstraint!
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    let bioType = LAContext().biometricType
    
    override func initializeComponents() {
        super.initializeComponents()
        
        // header footer
        headerLabel.size16(text: "LockSetting.Header.Title".localized, color: .gray77, weight: .medium)
        footerLabel.size12(text: "LockSetting.Footer.Title".localized, color: .gray77, weight: .light)
        
        navBar.setLeft(image: #imageLiteral(resourceName: "icAppbarCloseW")) {
            self.dismiss(animated: true, completion: nil)
        }
        navBar.setTitle("LockSetting.NavBar.Title".localized)
        
        self.tableView.isScrollEnabled = false
        
    }
    
    override func refresh() {
        super.refresh()
        
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
}

extension LockSettingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard UserDefaults.standard.bool(forKey: "useLock") else {
            self.headerHeight.constant = 100
            self.headerLabel.isHidden = false
            self.footerLabel.isHidden = false
            return 1
        }
        self.headerHeight.constant = 0
        self.headerLabel.isHidden = true
        self.footerLabel.isHidden = true
        return 3
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let activateCell = tableView.dequeueReusableCell(withIdentifier: "switchCell") as! SwitchTableViewCell
            activateCell.selectionStyle = .none
            activateCell.titleLabel.size14(text: "LockSetting.Activate".localized, color: .gray77)
            activateCell.switchControl.isOn = UserDefaults.standard.bool(forKey: "useLock")
            
            activateCell.switchControl.rx.controlEvent(.valueChanged).subscribe { (_) in
                let passCodeVC = self.storyboard?.instantiateViewController(withIdentifier: "Passcode") as! PasscodeViewController
                
                if UserDefaults.standard.bool(forKey: "useLock") {
                    passCodeVC.lockType = .deactivate
                } else {
                    passCodeVC.lockType = .activate
                }
                
                self.navigationController?.pushViewController(passCodeVC, animated: true)
                
                
            }.disposed(by: activateCell.cellBag)
            
            return activateCell
            
        case 1:
            let changeCell = tableView.dequeueReusableCell(withIdentifier: "changeCell") as! RightArrowTableViewCell
            changeCell.titleLabel.size14(text: "LockSetting.Change".localized, color: .gray77)
            
            return changeCell
            
        default:
            let activateCell = tableView.dequeueReusableCell(withIdentifier: "switchCell") as! SwitchTableViewCell
            activateCell.selectionStyle = .none
            switch bioType.type {
            case .none:
                activateCell.titleLabel.text = ""
            case .touchID:
                activateCell.titleLabel.size14(text: "LockSetting.TouchID".localized, color: .gray77)
            case .faceID:
                activateCell.titleLabel.size14(text: "LockSetting.FaceID".localized, color: .gray77)
            }
            
            activateCell.switchControl.isOn = UserDefaults.standard.bool(forKey: "useBio")
            
            if Tool.canVerificateBiometry() == .notAvailable {
                activateCell.switchControl.isOn = false
            }
            
            activateCell.switchControl.rx.controlEvent(.valueChanged)
                .subscribe { (_) in
                    if activateCell.switchControl.isOn {
                        let status = Tool.canVerificateBiometry()
                        if status == Tool.LAStatus.success {
                            let bio = self.storyboard?.instantiateViewController(withIdentifier: "BioAuth") as! BioAuthViewController
                            self.navigationController?.pushViewController(bio, animated: true)
                        } else {
                            if status == Tool.LAStatus.locked {
                                
                                let title: String = {
                                    if self.bioType.type == .touchID {
                                        return "LockSetting.TouchID.Locked".localized
                                    } else {
                                        return "LockSetting.FaceID.Locked".localized
                                    }
                                }()
                                
                                Alert.basic(title: title, leftButtonTitle: "Common.Confirm".localized).show()
                                
                            } else if status == Tool.LAStatus.notUsed {
                                let title: String = {
                                    if self.bioType.type == .touchID {
                                        return "LockSetting.Alert.TouchID".localized
                                    } else {
                                        return "LockSetting.Alert.FaceID".localized
                                    }
                                }()
                                
                                Alert.basic(title: title, leftButtonTitle: "Common.Confirm".localized).show()
                                
                            } else if status == Tool.LAStatus.passcodeNotSet {
                                Alert.basic(title: "LockSetting.Alert.Password".localized, leftButtonTitle: "Common.Confirm".localized).show()
                                
                            } else if status == Tool.LAStatus.notAvailable {
                                Alert.basic(title: "LockSetting.Alert.Password".localized, leftButtonTitle: "Common.Confirm".localized).show()
                            }
                            activateCell.switchControl.isOn = false
                        }
                    } else {
                        Tool.removeBio()
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                    
            }.disposed(by: activateCell.cellBag)
            
            return activateCell
        }
    }
}

extension LockSettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 1 {
            let changeVC = self.storyboard?.instantiateViewController(withIdentifier: "Passcode") as! PasscodeViewController
            changeVC.lockType = .change
            self.navigationController?.pushViewController(changeVC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
