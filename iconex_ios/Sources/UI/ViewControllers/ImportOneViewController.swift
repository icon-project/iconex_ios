//
//  ImportOneViewController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit

class ImportOneCell: UITableViewCell {
    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var itemTitle: UILabel!
}

class ImportOneViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableHeaderTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nextButton: UIButton!
    
    var delegate: ImportStepDelegate?
    
    private var selected: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeUI()
        selected = IndexPath(row: 0, section: 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initializeUI() {
        tableHeaderTitle.text = Localized(key: "Import.Step1.Header")
        
        nextButton.styleDark()
        nextButton.setTitle(Localized(key: "Common.Next"), for: .normal)
        nextButton.rounded()
        
        tableView.tableFooterView = UIView()
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImportOneCell", for: indexPath) as! ImportOneCell
        
        if indexPath.row == 0 {
            cell.itemTitle.text = Localized(key: "Wallet.Keystore")
        } else {
            cell.itemTitle.text = Localized(key: "Wallet.PrivateKey")
        }
        
        
        if let selected = selected {
            if selected == indexPath {
                cell.checkImage.isHighlighted = true
            } else {
                cell.checkImage.isHighlighted = false
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        var rows = [indexPath]
        if let prevSelected = selected {
            rows.append(prevSelected)
        }
        
        selected = indexPath
        
        tableView.reloadRows(at: rows, with: .none)
        
//        if indexPath.row == 0 {
//            nextButton.isEnabled = false
//        } else {
//            nextButton.isEnabled = true
//        }
    }
    
    @IBAction func clickedNext(_ sender: Any) {        
        if let delegate = self.delegate {
            WCreator.resetData()
            WCreator.importStyle = selected!.row
            delegate.next()
        }
    }
}
