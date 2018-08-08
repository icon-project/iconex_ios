//
//  ImportStepViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

protocol ImportStepDelegate {
    func prev()
    func next()
}

class ImportStepViewController: UIViewController, ImportStepDelegate {

    @IBOutlet weak var topTitle: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var importOne: ImportOneViewController!
    var importTwo: ImportTwoViewController!
    var importThree: ImportThreeViewController!
    
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
    
    func initialize() {
        let stepOne = childViewControllers[0] as! ImportOneViewController
        stepOne.delegate = self
        self.importOne = stepOne
        
        let stepTwo = childViewControllers[1] as! ImportTwoViewController
        stepTwo.delegate = self
        self.importTwo = stepTwo
        
        let stepThree = childViewControllers[2] as! ImportThreeViewController
        stepThree.delegate = self
        self.importThree = stepThree
    }
    
    func initializeUI() {
        topTitle.text = Localized(key: "Wallet.Load")
    }
    
    @IBAction func clickedClose(_ sender: Any) {
        let current = scrollView.contentOffset.x / scrollView.frame.width
        if current == 0 {
            WCreator.resetData()
            self.dismiss(animated: true, completion: nil)
        } else {
            Alert.Confirm(message: "Alert.Wallet.Import.Cancel".localized, cancel: "Common.No".localized, confirm: "Common.Yes".localized, handler: {
                WCreator.resetData()
                self.dismiss(animated: true, completion: nil)
            }).show(self)
        }
    }
    
}

extension ImportStepDelegate where Self: ImportStepViewController {
    func prev() {
        let x = scrollView.contentOffset.x - view.frame.width
        let offset = CGPoint(x: x, y: 0)
        scrollView.setContentOffset(offset, animated: true)
    }
    
    func next() {
        let x = scrollView.contentOffset.x + view.frame.width

        if x == view.frame.width {
            self.importTwo.refreshItem()
        } else if x == view.frame.width * 2 {
            self.importThree.refreshItem()
        }
        
        let offset = CGPoint(x: x, y: 0)
        scrollView.setContentOffset(offset, animated: true)
    }
}
