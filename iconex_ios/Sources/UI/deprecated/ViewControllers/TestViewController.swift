//
//  TestViewController.swift
//  ios-iCONex
//
//  Created by Jeonghwan Ahn on 09/02/2018.
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit

class TestViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, QRReaderDelegate {

    @IBOutlet weak var createWalletButton: UIButton!
    @IBOutlet weak var manageButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    private var items: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.createWalletButton.setTitle("지갑 생성", for: .normal)
        self.manageButton.setTitle("Export/Import", for: .normal)
        
        self.loadItems()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTestQR" {
            let controller = segue.destination as! TestQRViewController
            controller.delegate = self
        }
    }
    
    func loadItems() {
        do {
//            self.items = try WManager.loadWalletNameList()
            
        } catch {
            Log.Error("error: \(error)")
        }
        
        self.tableView.reloadData()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func clickedCreateWallet(_ sender: Any) {
        self.createICXWallet()
    }
    
    @IBAction func clickedManage(_ sender: Any) {
        let alert = UIAlertController(title: "가져오기/내보내기", message: "선택해주세요", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "내보내기", style: .default, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "가져오기", style: .default, handler: { (action) in
            let importAlert = UIAlertController(title: "가져오기", message: "수단을 선택해주세요", preferredStyle: .alert)
            importAlert.addAction(UIAlertAction(title: "iCloud Drive", style: .default, handler: { (action) in
                
            }))
            importAlert.addAction(UIAlertAction(title: "QR Code", style: .default, handler: { (action) in
                self.performSegue(withIdentifier: "showTestQR", sender: self)
            }))
            importAlert.addAction(UIAlertAction(title: "취소", style: .destructive, handler: { (action) in
                
            }))
            
            self.show(importAlert, sender: self)
        }))
        alert.addAction(UIAlertAction(title: "취소", style: .destructive, handler: { (action) in
            
        }))
        
        self.show(alert, sender: self)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let items = self.items {
            return items.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "protoTest", for: indexPath)
        
        if let items = self.items {
            cell.textLabel!.text = items[indexPath.row]
        } else {
            cell.textLabel!.text = "No wallets"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let items = self.items {
            do {
                let alias = items[indexPath.row]
                let data = try WManager.getWalletInfo(alias: alias)
                
                let wallet = ICXWallet(alias: alias, from: data)
                
                let loop = LoopChainClient()
//                loop.test(address: wallet.keyStore!.address)
                
                loop.getBalance(address: wallet.keyStore!.address)
                
                
                let alert = UIAlertController(title: alias, message: "지갑의 비밀번호를 입력", preferredStyle: .alert)
                alert.addTextField(configurationHandler: { (field) in
                    field.isSecureTextEntry = true
                })
                alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
                    guard let field = alert.textFields?.first else {
                        return
                    }
                    guard let password = field.text else {
                        return
                    }
                    do {
                        let privateKey = try wallet.extractICXPrivateKey(password: password)

                        let toAddress = "hxff23dedf4439b2990279fb0fe62625b90c9680eb"
                        let sendAlert = UIAlertController(title: "송금하기", message: "100 icx를" + "\n" + toAddress + "\n로 보내기", preferredStyle: .alert)
                        sendAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                            do {
                                try loop.sendICX(amount: "100", privateKey: privateKey, from: wallet.keyStore!.address, to: toAddress)
                            } catch {
                                Log.Error("error: \(error)")
                            }
                        }))
                        sendAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                            
                        }))
                        self.show(sendAlert, sender: self)
                    } catch {
                        Log.Error("Error: \(error)")
                    }
                }))
                alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))

                self.show(alert, sender: self)
            } catch {
                Log.Error("error: \(error)")
            }
        }
    }
    
    func didCapturedCode(code: String) {
        Log.Verbose("Captured code: \(code)")
        self.createICXWallet(code)
    }
    
    func createICXWallet(_ key: String? = nil) {
        let alert = UIAlertController(title: "지갑생성", message: "지갑 이름과 비밀번호를 입력하기", preferredStyle: .alert)
        alert.addTextField { (field) in
            field.placeholder = "지갑 이름"
        }
        alert.addTextField { (passField) in
            passField.isSecureTextEntry = true
            passField.placeholder = "지갑 비밀번호"
        }
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "생성", style: .default, handler: { (action) in
            guard let aliasField = alert.textFields?.first else {
                Log.Error("WRONG!!")
                return
            }
            
            guard let passField = alert.textFields?.last else {
                Log.Error("WRONG!!")
                return
            }
            
            guard let alias = aliasField.text else {
                return
            }
            
            guard let password = passField.text else {
                return
            }
            
            var wallet = ICXWallet(alias: alias)
            
            var privateKey: String
            if let prvKey = key {
                privateKey = prvKey
            } else {
                privateKey = wallet.generatePrivateKey()
            }
            
            do {
                var result = try wallet.generateICXKeyStore(privateKey: privateKey, password: password)
                Log.Info("result: \(result)")
//                result = try wallet.saveICXWallet()
            } catch {
                Log.Error("Error: \(error)")
            }
            
            self.loadItems()
        }))
        
        self.show(alert, sender: self)
    }
}
