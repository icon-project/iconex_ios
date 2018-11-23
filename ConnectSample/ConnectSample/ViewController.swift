//
//  ViewController.swift
//  ConnectSample
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import ICONKit
import BigInt

class ViewController: UIViewController {
    @IBOutlet weak var bind: UIButton!
    @IBOutlet weak var sign: UIButton!
    @IBOutlet weak var sendICX: UIButton!
    @IBOutlet weak var sendToken: UIButton!
    
    var bindAddress: String? {
        willSet {
            if let value = newValue {
                UserDefaults.standard.setValue(value, forKey: "binded")
            } else {
                UserDefaults.standard.removeObject(forKey: "binded")
            }
            UserDefaults.standard.synchronize()
        }
        
        didSet {
            checkBind()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.bindAddress = UserDefaults.standard.string(forKey: "binded")
    }

    func checkBind() {
        if let binded = bindAddress {
            sign.isEnabled = true
            sendICX.isEnabled = true
            sendToken.isEnabled = true
            bind.setTitle(binded, for: .normal)
        } else {
            sign.isEnabled = false
            sendICX.isEnabled = false
            sendToken.isEnabled = false
            bind.setTitle("Bind", for: .normal)
        }
    }

    @IBAction func bind(_ sender: Any) {
        if bindAddress != nil {
            bindAddress = nil
        } else {
            let param = ["id": 1, "method": "bind"] as [String: Any]
            
            send(params: param)
        }
    }
    
    @IBAction func sign(_ sender: Any) {
        let version = "0x3"
        guard let from = bindAddress else { return }
        let to = "hx5a05b58a25a1e5ea0f1d5715e1f655dffc1fb30a"
        let value = "0xde0b6b3a7640000"
        let stepLimit = "0x12345"
        let timestamp = "0x563a6cf330136"
        let nid = "0x3"
        let nonce = "0x1"
        
        let param = ["id": 2, "method": "sign", "params":
            ["version": version,
             "from": from,
             "to": to,
             "value": value,
             "stepLimit": stepLimit,
             "timestamp": timestamp,
             "nid": nid,
             "nonce": nonce]
            ] as [String: Any]
        
        send(params: param)
    }
    
    @IBAction func sendICX(_ sender: Any) {
        let alert = UIAlertController(title: "Send Coin", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "to"
            textField.text = "hx5a05b58a25a1e5ea0f1d5715e1f655dffc1fb30a"
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Input value"
            textField.keyboardType = .decimalPad
        }
        alert.addTextField { textField in
            textField.text = "Hello, ICON!"
            textField.placeholder = "Messages"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (action) in
            var param = ["id": 3, "method": "sendICX"] as [String: Any]
            
            var params = [String: Any]()
            
            if let valueString = alert.textFields![1].text, valueString != "", let big = BigUInt(valueString) {
                let value = "0x" + String(big, radix: 16)
                params["value"] = value
            }
            let from = self.bindAddress!
            params["from"] = from
            
            let toField = alert.textFields!.first!
            if let to = toField.text, to != "" {
                params["to"] = to
            }
            
            let mField = alert.textFields!.last!
            if let msg = mField.text, msg != "", let message = msg.data(using: .utf8)?.toHexString() {
                params["dataType"] = "message"
                params["data"] = "0x" + message
            }
            
            param["params"] = params
            
            let confirm = UIAlertController(title: "", message: "\(params)", preferredStyle: .alert)
            confirm.addAction(UIAlertAction(title: "Send", style: .cancel, handler: { action in
                self.send(params: param)
            }))
            
            self.present(confirm, animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func sendToken(_ sender: Any) {
        let alert = UIAlertController(title: "Send Token", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "to"
            textField.text = "hx5a05b58a25a1e5ea0f1d5715e1f655dffc1fb30a"
        }
        alert.addTextField { textField in
            textField.placeholder = "Contract"
            textField.text = "cx4ae65c058d35b5bb8cef668be5113354448c0264"
        }
        alert.addTextField { textField in
            textField.placeholder = "Token value"
            textField.keyboardType = .decimalPad
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (action) in
            var param = ["id": 4, "method": "sendToken"] as [String: Any]
            
            var params = [String: Any]()
            let toField = alert.textFields!.first!
            if let to = toField.text, to != "" {
                params["to"] = to
            }
            let from = self.bindAddress!
            params["from"] = from
            
            let conField = alert.textFields![1]
            if let contract = conField.text, contract != "" {
                params["contractAddress"] = contract
            }
            let valueField = alert.textFields!.last!
            if let valueString = valueField.text, valueString != "", let big = BigUInt(valueString) {
                let value = "0x" + String(big, radix: 16)
                params["value"] = value
            }
            
            param["params"] = params
            
            let confirm = UIAlertController(title: "", message: "\(param)", preferredStyle: .alert)
            confirm.addAction(UIAlertAction(title: "Send", style: .cancel, handler: { action in
                self.send(params: param)
            }))
            self.present(confirm, animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func send(params: [String: Any]) {
        
        guard let data = try? JSONSerialization.data(withJSONObject: params, options: []) else { return }
        let encoded = data.base64EncodedString()
        let items = [URLQueryItem(name: "data", value: encoded), URLQueryItem(name: "caller", value: "connect-sample://")]
        var component = URLComponents(string: "iconex://")!
        component.queryItems = items
        
        UIApplication.shared.open(component.url!, options: [:], completionHandler: { result in
            print("\(result)")
        })
    }
    
    func translate(url: URL) {
        guard let component = URLComponents(url: url, resolvingAgainstBaseURL: false), let list = component.queryItems, let dataParams = list.filter({ $0.name == "data" }).first?.value else {
            print("Invalid data")
            return }
        
        guard let encodedData = Data(base64Encoded: dataParams) else {
            print("Invalid formats")
            return }
        
        let decoder = JSONDecoder()
        
        guard let response = try? decoder.decode(Response.self, from: encodedData) else {
            print("Invalid response")
            return }
        
        print("id - \(response.id) , code - \(response.code) , result - \(response.result)")
        
        let alert = UIAlertController(title: "Response", message: "ID : \(response.id)\nCode : \(response.code)\nResult : \(response.result)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        guard response.code > 0 else { return }
        
        // Just for sample. Parameter ID would be random-generated numbers.
        if response.id == 1 {
            // method == bind
            self.bindAddress = response.result
        }
    }
}

struct Response: Decodable {
    var id: Int
    var code: Int
    var result: String
}
