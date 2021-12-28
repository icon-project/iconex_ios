//
//  StepOneViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

class StepOneCell: UITableViewCell {
    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var itemTitle: UILabel!
    
//    override func awakeFromNib() {
//        let back = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
//        back.backgroundColor = UIColor.clear
//
//        let line = UIView(frame: CGRect(x: 24, y: back.frame.size.height - 1 / UIScreen.main.nativeScale, width: back.frame.size.width - 24, height: 1 / UIScreen.main.nativeScale))
//        line.backgroundColor = UIColor(230, 230, 230)
//        back.addSubview(line)
//        self.selectedBackgroundView = back
//    }
}

class StepOneViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var headerLabel1: UILabel!
    @IBOutlet weak var descLabel1: UILabel!
    @IBOutlet weak var headerLabel2: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    
    var delegate: CreateStepDelegate?
    
    private var itemList: [(String, COINTYPE)]?
    private var selected: IndexPath?
    
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
        itemList = [("ICON (ICX)", .icx), ("Ethereum (ETH)", .eth)]
        selected = IndexPath(row: 0, section: 0)
    }
    
    func initializeUI() {
        headerLabel1.text = "Create.Wallet.Step1.CreateSelected".localized
        descLabel1.text = "Create.Wallet.Step1.Instruction".localized
        headerLabel2.text = "Create.Wallet.Step1.SelectCoin".localized
        nextButton.setTitle(Localized(key: "Common.Next"), for: .normal)
        nextButton.styleDark()
        nextButton.rounded()
    }
    
    @IBAction func clickedNext(_ sender: Any) {
        guard let delegate = delegate else {
            return
        }
        
        let item = itemList![selected!.row]
        
        WCreator.newType = item.1
        delegate.nextStep(currentStep: .one)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let itemList = itemList else {
            return 1
        }
        
        return itemList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StepOneCell", for: indexPath) as! StepOneCell
        
        if let list = itemList {
            cell.itemTitle.text = list[indexPath.row].0
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
    }
}
