//
//  SelectableActionController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

//protocol SelectableActionDelegate {
//    func selectableAction(selectedIndex: Int)
//}

class SelectableActionController: BaseViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tabView: UIView!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    var stringList: [String]?
    var infoList: [(name: String, balance: String, symbol: String)]?
    var handler: ((_ index: Int) -> Void)?
    
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
        view.alpha = 0.0
        
    }
    
    func initializeUI() {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        
        let gesture = UITapGestureRecognizer()
        tabView.addGestureRecognizer(gesture)
        gesture.rx.event.subscribe(onNext: { [unowned self] _ in
            self.close()
        }).disposed(by: disposeBag)
    }
    
    func refresh() {
        
        tableView.reloadData()
    }

    @IBAction func clickedClose(_ sender: Any) {
        close()
    }
}

extension SelectableActionController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.15, animations: {
            self.view.alpha = 1.0
        }, completion: { (bool) in
            self.bottomConstraint.constant = 0
            UIView.animate(withDuration: 0.15, animations: {
                self.view.layoutIfNeeded()
            })
        })
    }
    
    func present(from: UIViewController, title: String, items: [String]) {
        
        self.stringList = items
        from.present(self, animated: false) {
            self.titleLabel.text = title
            self.bottomConstraint.constant = CGFloat(-((self.stringList != nil ? 60 : 72) * items.count + 46 + 16))
            self.heightConstraint.constant = CGFloat(min((self.stringList != nil ? 60 : 72) * items.count, (self.stringList != nil ? 60 : 72) * 4) + 16)
        }
    }
    
    func present(from: UIViewController, title: String, info: [(name: String, balance: String, symbol: String)]) {
        self.infoList = info
        from.present(self, animated: false) {
            self.titleLabel.text = title
            self.bottomConstraint.constant = CGFloat(-((self.stringList != nil ? 60 : 72) * info.count + 46 + 16))
            self.heightConstraint.constant = CGFloat(min((self.stringList != nil ? 60 : 72) * info.count, (self.stringList != nil ? 60 : 72) * 4) + 16)
        }
    }
    
    func close() {
        if let itemList = self.stringList {
            self.bottomConstraint.constant = CGFloat(-(60 * itemList.count + 46 + 16))
        } else {
            self.bottomConstraint.constant = CGFloat(-(72 * self.infoList!.count + 46 + 16))
        }
        UIView.animate(withDuration: 0.15, animations: {
            self.view.layoutIfNeeded()
        }) { (bool) in
            UIView.animate(withDuration: 0.15, animations: {
                self.view.alpha = 0.0
            }) { (bool) in
                self.dismiss(animated: false, completion: nil)
            }
        }
    }
}

class SelectableCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    
}

class SelectableCell2: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    
}

extension SelectableActionController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let string = stringList else {
            return infoList!.count
        }
        return string.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return stringList != nil ? 60 : 72
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let itemList = stringList {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SelectableCell", for: indexPath) as! SelectableCell

            let selectedView = UIView()
            selectedView.backgroundColor = UIColor.lightTheme.background.normal
            cell.selectedBackgroundView = selectedView
            
            cell.titleLabel.text = itemList[indexPath.row]
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SelectableCell2", for: indexPath) as! SelectableCell2
            let info = self.infoList![indexPath.row]
            cell.nameLabel.text = info.name
            cell.balanceLabel.text = info.balance
            cell.unitLabel.text = info.symbol
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let handler = self.handler else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        handler(indexPath.row)
        close()
    }
}
