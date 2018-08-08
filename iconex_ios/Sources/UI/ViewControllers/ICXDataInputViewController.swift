//
//  ICXDataInputViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

class ICXDataInputViewController: BaseViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var stepView: UIView!
    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var stepButton: UIButton!
    @IBOutlet weak var lengthLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeUI()
        initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initializeUI() {
        
    }
    
    func initialize() {
        
    }
}
