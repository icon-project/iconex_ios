//
//  LicenseViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 02/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AcknowList

class LicenseViewController: PopableViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var closeButton: UIButton!
    
    var list: [Acknow]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        titleContainer.set(title: "AppInfo.License".localized)
        titleContainer.actionHandler = {
            self.dismiss(animated: true, completion: nil)
        }
        
        closeButton.setTitle("Common.Close".localized, for: .normal)
        closeButton.round02()
        
        closeButton.rx.tap.subscribe(onNext: { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let parser = AcknowParser(plistPath: Bundle.main.path(forResource: "Pods-iconex_ios-acknowledgements", ofType: "plist")!)
        
        list = parser.parseAcknowledgements()
        tableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

extension LicenseViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LicenseCell", for: indexPath)
        cell.textLabel?.text = list[indexPath.row].title
        return cell
    }
}

extension LicenseViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let ack = AcknowViewController(acknowledgement: list[indexPath.row])
        
    }
}
