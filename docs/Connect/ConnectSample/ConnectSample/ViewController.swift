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
    @IBOutlet weak var sendICX: UIButton!
    @IBOutlet weak var sendToken: UIButton!
    @IBOutlet weak var sendMessage: UIButton!
    @IBOutlet weak var sendCall: UIButton!
    @IBOutlet weak var developer: UIButton!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewSendButton: UIButton!
    
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.view.endEditing(true)
    }
    
    func checkBind() {
        if let binded = bindAddress {
            sendICX.isEnabled = true
            sendToken.isEnabled = true
            sendMessage.isEnabled = true
            sendCall.isEnabled = true
            bind.setTitle(binded, for: .normal)
        } else {
            sendICX.isEnabled = false
            sendToken.isEnabled = false
            sendMessage.isEnabled = false
            sendCall.isEnabled = false
            bind.setTitle("Bind", for: .normal)
        }
    }
    
    @IBAction func bind(_ sender: Any) {
        if bindAddress != nil {
            bindAddress = nil
        } else {
            let param = ["redirect": "connect-sample://"] as [String: Any]
            
            send(command: .bind, params: param)
        }
    }
    
    @IBAction func sendICX(_ sender: Any) {
        let alert = UIAlertController(title: "Send Coin", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "to"
            textField.text = "hx2e26d96bd7f1f46aac030725d1e302cf91420458"
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Input value"
            textField.text = "1"
            textField.keyboardType = .decimalPad
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (action) in
            var param = ["redirect": "connect-sample://"] as [String: Any]

            var payload = [String: Any]()

            if let valueString = alert.textFields![1].text, valueString != "", let big = BigUInt(valueString) {
                let value = "0x" + String(big, radix: 16)
                payload["value"] = value
            }
            let from = self.bindAddress!
            payload["from"] = from

            let toField = alert.textFields!.first!
            if let to = toField.text, to != "" {
                payload["to"] = to
            }
            param["payload"] = payload

            let confirm = UIAlertController(title: "", message: "\(payload)", preferredStyle: .alert)
            confirm.addAction(UIAlertAction(title: "Send", style: .cancel, handler: { action in
                self.send(command: .jsonrpc, params: param)
            }))

            self.present(confirm, animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func sendToken(_ sender: Any) {
        let alert = UIAlertController(title: "Send Token", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "to"
            textField.text = "hx2e26d96bd7f1f46aac030725d1e302cf91420458"
        }
        alert.addTextField { textField in
            textField.placeholder = "Contract"
            textField.text = "cxb1253480720b91a4a7417b0b08d7feb81bd7f0fb"
        }
        alert.addTextField { textField in
            textField.placeholder = "Token value"
            textField.keyboardType = .decimalPad
            textField.text = "1"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (action) in
            var param = ["redirect": "connect-sample://"] as [String: Any]
            
            var payload = [String: Any]()
            var params = [String: Any]()
            
            let toField = alert.textFields!.first!
            if let to = toField.text, to != "" {
                params["_to"] = to
            }
            let from = self.bindAddress!
            payload["from"] = from
            
            let conField = alert.textFields![1]
            if let contract = conField.text, contract != "" {
                payload["to"] = contract
            }
            let valueField = alert.textFields!.last!
            if let valueString = valueField.text, valueString != "", let big = BigUInt(valueString) {
                let value = "0x" + String(big, radix: 8)
                params["_value"] = value
            }
            payload["data"] = ["method": "transfer", "params": params]
            param["payload"] = payload
            
            print(param)
            let confirm = UIAlertController(title: "", message: "\(payload)", preferredStyle: .alert)
            confirm.addAction(UIAlertAction(title: "Send", style: .cancel, handler: { action in
                self.send(command: .jsonrpc, params: param)
            }))
            self.present(confirm, animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        let alert = UIAlertController(title: "Send Message", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "to"
            textField.text = "hx2e26d96bd7f1f46aac030725d1e302cf91420458"
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Input value"
            textField.text = "1"
            textField.keyboardType = .decimalPad
        }
        alert.addTextField { textField in
            textField.text = "Hello, ICON!"
            textField.placeholder = "Messages"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (action) in
            var param = ["redirect": "connect-sample://"] as [String: Any]
            
            var payload = [String: Any]()
            
            if let valueString = alert.textFields![1].text, valueString != "", let big = BigUInt(valueString) {
                let value = "0x" + String(big, radix: 16)
                payload["value"] = value
            }
            let from = self.bindAddress!
            payload["from"] = from
            
            let toField = alert.textFields!.first!
            if let to = toField.text, to != "" {
                payload["to"] = to
            }
            
            let mField = alert.textFields!.last!
            if let msg = mField.text, msg != "" {
                payload["dataType"] = "message"
                payload["data"] = msg
            }
            
            param["payload"] = payload
            
            let confirm = UIAlertController(title: "", message: "\(payload)", preferredStyle: .alert)
            confirm.addAction(UIAlertAction(title: "Send", style: .cancel, handler: { action in
                self.send(command: .jsonrpc, params: param)
            }))
            self.present(confirm, animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func sendCall(_ sender: Any) {
        let alert = UIAlertController(title: "Send Call", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Contract(to)"
        }
        alert.addTextField { textField in
            textField.placeholder = "Method"
        }
        alert.addTextField { textField in
            textField.placeholder = "Params"
            textField.text = ""
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (action) in
            var param = ["redirect": "connect-sample://"] as [String: Any]
            var payload = [String: Any]()
            
            let from = self.bindAddress!
            payload["from"] = from
            
            let conField = alert.textFields!.first!
            if let contract = conField.text, contract != "" {
                payload["to"] = contract
            }
            let methodField = alert.textFields![1]
            guard let method = methodField.text, method != "" else { return }
            
            let dataField = alert.textFields!.last!
            if let dataString = dataField.text, dataString != "" {
                guard let data = dataString.data(using: .utf8) else { return }
                guard let jsonString = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] else { return }
                payload["data"] = ["method": method, "params": jsonString]
            } else {
                payload["data"] = ["method": method]
                
            }
            param["payload"] = payload
            let confirm = UIAlertController(title: "", message: "\(payload)", preferredStyle: .alert)
            confirm.addAction(UIAlertAction(title: "Send", style: .cancel, handler: { action in
                self.send(command: .jsonrpc, params: param)
            }))
            self.present(confirm, animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func activateDeveloper(_ sender: Any) {
        let url = URL(string: "iconex://developer")!
        UIApplication.shared.open(url, options: [:]) { (result) in
            print("Request developer mode : \(result)")
        }
    }
    
    @IBAction func testTextView(_ sender: Any) {
        var param = ["redirect": "connect-sample://"] as [String: Any]
        
        guard let data = self.textView.text.data(using: .utf8) else { return }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] else { return }
        
        param["payload"] = json
        
        send(command: .jsonrpc, params: param)
        
    }
    
    func send(command: Command, params: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) else { return }
        
        let encoded = data.base64EncodedString()
        let items = [URLQueryItem(name: "data", value: encoded)]
        
        var component = URLComponents(string: "iconex://")!
        component.host = command.rawValue
        component.queryItems = items
        
        print(component)
        
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
        
        let alert = UIAlertController(title: "Response", message: "Code : \(response.code)\nResult : \(response.result ?? "")\nMessage: \(response.message)", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        guard response.code >= 0 else { return }
        
        // Just for sample.
        if response.result?.hasPrefix("hx") == true {
            self.bindAddress = response.result
        }
    }
}

struct Response: Decodable {
    var code: Int
    var message: String
    var result: String?
}

enum Command: String {
    case bind = "bind"
    case jsonrpc = "JSON-RPC"
}
