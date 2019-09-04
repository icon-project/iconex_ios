//
//  ExportMainViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 03/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol ExportWalletSequence {
    func set(bundle: [(BaseWalletConvertible, String)]?)
    func set(password: String?)
    func validated()
    func invalidated()
}

class ExportMainViewController: PopableViewController, Exportable {
    @IBOutlet weak var stepImage1: UIImageView!
    @IBOutlet weak var stepLabel1: UILabel!
    @IBOutlet weak var stepImage2: UIImageView!
    @IBOutlet weak var stepLabel2: UILabel!
    
    @IBOutlet weak var centerLine: UIView!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    @IBOutlet weak var stepScroll: UIScrollView!
    
    let exportor = BundleExport()
    
    private var exportList: ExportListViewController!
    private var exportPassword: ExportPasswordViewController!
    
    var scrollIndex: Int = 0 {
        willSet {
            switch newValue {
            case 0:
                stepLabel1.textColor = .mint1
                stepLabel2.textColor = .gray230
                centerLine.backgroundColor = .gray230
                stepImage1.image = #imageLiteral(resourceName: "icStep01On")
                stepImage2.image = #imageLiteral(resourceName: "icStep02Off")
                leftButton.setTitle("Common.Cancel".localized, for: .normal)
                rightButton.setTitle("Common.Next".localized, for: .normal)
                rightButton.isEnabled = false
                
            default:
                stepLabel1.textColor = .mint1
                stepLabel2.textColor = .mint1
                centerLine.backgroundColor = .mint1
                stepImage1.image = #imageLiteral(resourceName: "icStepCheck")
                stepImage2.image = #imageLiteral(resourceName: "icStep02On")
                leftButton.setTitle("Common.Back".localized, for: .normal)
                rightButton.setTitle("ExportMain.Button.BackupDownload".localized, for: .normal)
                rightButton.isEnabled = false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        titleContainer.set(title: "ExportMain.Title".localized)
        titleContainer.actionHandler = {
            self.dismiss(animated: true, completion: nil)
        }
        
        stepLabel1.text = "ExportMain.Display.Step1.Title".localized
        stepLabel2.text = "ExportMain.Display.Step2.Title".localized
        
        leftButton.round02()
        rightButton.lightMintRounded()
        
        stepScroll.rx.didEndScrollingAnimation.subscribe(onNext: { [unowned self] in
            self.scrollIndex = (Int)(self.stepScroll.contentOffset.x / self.view.frame.width)
        }).disposed(by: disposeBag)
        
        leftButton.rx.tap.subscribe(onNext: {
            self.exportList.refresh()
            self.exportPassword.refresh()
            switch self.scrollIndex {
            case 0:
                self.dismiss(animated: true, completion: nil)
                
            default:
                let value = (CGFloat)(self.scrollIndex - 1)
                let x = value * self.view.frame.width
                self.stepScroll.setContentOffset(CGPoint(x: x, y: 0), animated: true)
                self.exportPassword.resetData()
            }
        }).disposed(by: disposeBag)
        
        rightButton.rx.tap.subscribe(onNext: {
            guard self.exportor.bundles != nil else { return }
            self.exportList.refresh()
            self.exportPassword.refresh()
            
            switch self.scrollIndex {
            case 0:
                Alert.basic(title: "", subtitle: "ExportMain.Alert.WarnPassword".localized, hasHeaderTitle: false, isOnlyOneButton: false, leftButtonTitle: "Common.Cancel".localized, rightButtonTitle: "Common.Confirm".localized, confirmAction: {
                    self.scrollNext()
                }).show()
                
            default:
                Alert.basic(title: "ExportMain.Alert.DownloadKeystore".localized, subtitle: nil, hasHeaderTitle: false, isOnlyOneButton: false, leftButtonTitle: "Common.Cancel".localized, rightButtonTitle: "Common.Confirm".localized, confirmAction: {
                    self.backupBundles()
                }).show()
                
            }
            
        }).disposed(by: disposeBag)
        
        for child in children {
            if let list = child as? ExportListViewController {
                list.delegate = self
                exportList = list
            } else if let password = child as? ExportPasswordViewController {
                password.delegate = self
                exportPassword = password
            }
        }
        
        scrollIndex = 0
    }
    
    override func refresh() {
        super.refresh()
    }
    
    func scrollNext() {
        let value = (CGFloat)(self.scrollIndex + 1)
        let x = value * self.view.frame.width
        self.stepScroll.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }
    
    func backupBundles() {
        do {
            guard let bundles = exportor.export() else { return }
            
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(bundles)
            let filename = "ICONex_\(Date.currentZuluTime)"
            let fm = FileManager.default
            var path = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
            path = path.appendingPathComponent("ICONex")
            var isDirectory = ObjCBool(false)
            if !fm.fileExists(atPath: path.path, isDirectory: &isDirectory) {
                try fm.createDirectory(at: path, withIntermediateDirectories: false, attributes: nil)
            }
            
            let filePath = path.appendingPathComponent(filename)
            try encoded.write(to: filePath, options: .atomic)
            
            export(filepath: filePath) { (type, isCompleted, _, error) in
                if isCompleted {
                    Alert.basic(title: "ExportMain.Alert.BackedUp".localized).show()
                }
            }
        } catch {
            Log("Error - \(error)")
        }
    }
}

extension ExportMainViewController: ExportWalletSequence {
    func set(bundle: [(BaseWalletConvertible, String)]?) {
        exportor.bundles = bundle
    }
    
    func set(password: String?) {
        exportor.password = password
    }
    
    func validated() {
        rightButton.isEnabled = true
    }
    
    func invalidated() {
        rightButton.isEnabled = false
    }
}
