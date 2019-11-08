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
        alert.addTextField { (textField) in
            textField.placeholder = "Network id (0x1, 0x2, 0x3)"
            textField.text = "0x"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (action) in
            var param = ["redirect": "connect-sample://"] as [String: Any]
            guard let valueString = alert.textFields![1].text, valueString != "" else { return }
            let nidField = alert.textFields![2]
            guard let nid = nidField.text, nid != "" else { return }
            
            var bigValue: BigUInt
            
            if valueString.contains(".") {
                let value = valueString.split(separator: ".")
                
                guard let intVal = BigUInt(value[0])?.convert() else { return }
                bigValue = intVal
                
                let div = value[1].count
                if div != 0 {
                    guard let doubleVal = BigUInt(value[1])?.convert() else { return }
                    let pow = BigUInt(10).power(div)
                    bigValue += doubleVal / pow
                }
                
            } else {
                bigValue =  BigUInt(valueString)?.convert() ?? 0
            }
            
            let from = self.bindAddress!
            
            let toField = alert.textFields!.first!
            guard let to = toField.text, to != "" else { return }
            
            let coinTransfer: Transaction = Transaction()
                .from(from)
                .to(to)
                .value(bigValue)
                .nid(nid)
                .nonce("0x1")
            
            guard let txData = try? coinTransfer.toDic() else { return }
            
            let payload = self.generateJSONRPC(params: txData)
            
            param["payload"] = payload
            
            print(param)
            
            let confirm = UIAlertController(title: "", message: "\(param)", preferredStyle: .alert)
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
            textField.placeholder = "Network id (0x1, 0x2, 0x3)"
            textField.text = "0x"
        }
        alert.addTextField { textField in
            textField.placeholder = "Token decimal"
            textField.keyboardType = .decimalPad
        }
        alert.addTextField { textField in
            textField.placeholder = "Token value"
            textField.keyboardType = .decimalPad
            textField.text = "1"
        }
        alert.addTextField { textField in
            textField.placeholder = "data (optional)"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (action) in
            var param = ["redirect": "connect-sample://"] as [String: Any]
            
            let from = self.bindAddress!
            
            let toField = alert.textFields!.first!
            guard let to = toField.text, to != "" else { return }
            
            let conField = alert.textFields![1]
            guard let contract = conField.text, contract != "" else { return }
            
            let nidField = alert.textFields![2]
            guard let nid = nidField.text, nid != "" else { return }
            
            let decimalField = alert.textFields![3]
            guard let decimalString = decimalField.text, decimalString != "", let decimal = Int(decimalString) else { return }
            
            let valueField = alert.textFields![4]
            guard let valueString = valueField.text, valueString != "" else { return }
            
            let power = BigUInt(10).power(decimal)
            
            var bigValue: BigUInt

            if valueString.contains(".") {
                let value = valueString.split(separator: ".")

                guard let intVal = BigUInt(value[0])?.multiplied(by: power) else { return }
                bigValue = intVal

                let div = value[1].count
                if div != 0 {
                    guard let doubleVal = BigUInt(value[1])?.multiplied(by: power) else { return }
                    let pow = BigUInt(10).power(div)
                    bigValue += doubleVal / pow
                }

            } else {
                bigValue = BigUInt(valueString)?.multiplied(by: power) ?? 0
            }
            let value = "0x" + String(bigValue, radix: 16)
            
            let tokenTransaction = CallTransaction()
                .from(from)
                .to(contract)
                .nid(nid)
                .method("transfer")
            
            let dataField = alert.textFields!.last!
            if let dataString = dataField.text, dataString != "" {
                tokenTransaction.params(["_to": to, "_value": value, "_data": dataString])
            } else {
                tokenTransaction.params(["_to": to, "_value": value])
            }
            
            guard let txData = try? tokenTransaction.toDic() else { return }
            
            let payload = self.generateJSONRPC(params: txData)
            
            param["payload"] = payload
            
            let confirm = UIAlertController(title: "", message: "\(param)", preferredStyle: .alert)
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
        alert.addTextField { textField in
            textField.placeholder = "Network id (0x1, 0x2, 0x3)"
            textField.text = "0x"
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
            
            let from = self.bindAddress!
            
            let toField = alert.textFields!.first!
            guard let to = toField.text, to != "" else { return }
            
            let nidField = alert.textFields![1]
            guard let nid = nidField.text, nid != "" else { return }
            
            let mField = alert.textFields!.last!
            guard let msg = mField.text, msg != "" else { return }
            
            let message = MessageTransaction()
                .from(from)
                .to(to)
                .nid(nid)
                .message(msg)
            
            if let valueString = alert.textFields![2].text, valueString != "" {
                var bigValue: BigUInt
                
                if valueString.contains(".") {
                    let value = valueString.split(separator: ".")
                    
                    guard let intVal = BigUInt(value[0])?.convert() else { return }
                    bigValue = intVal
                    
                    let div = value[1].count
                    if div != 0 {
                        guard let doubleVal = BigUInt(value[1])?.convert() else { return }
                        let pow = BigUInt(10).power(div)
                        bigValue += doubleVal / pow
                    }
                    
                } else {
                    bigValue =  BigUInt(valueString)?.convert() ?? 0
                }
                
                message.value(bigValue)
            }
            
            guard let txData = try? message.toDic() else { return }
            let payload = self.generateJSONRPC(params: txData)
            
            param["payload"] = payload
            
            let confirm = UIAlertController(title: "", message: "\(param)", preferredStyle: .alert)
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
            textField.text = "cx334db6519871cb2bfd154cec0905ced4ea142de1"
        }
        alert.addTextField { textField in
            textField.placeholder = "Network id (0x1, 0x2, 0x3)"
            textField.text = "0x"
        }
        alert.addTextField { textField in
            textField.placeholder = "Method"
        }
        alert.addTextField { textField in
            textField.placeholder = "Params (optional)"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (action) in
            var param = ["redirect": "connect-sample://"] as [String: Any]
            
            let from = self.bindAddress!
            
            let conField = alert.textFields!.first!
            guard let contract = conField.text, contract != "" else { return }
            
            let nidField = alert.textFields![1]
            guard let nid = nidField.text, nid != "" else { return }
            
            let methodField = alert.textFields![2]
            guard let method = methodField.text, method != "" else { return }
            
            let callTx = CallTransaction()
                .from(from)
                .to(contract)
                .nid(nid)
                .method(method)
            
            let dataField = alert.textFields!.last!
            if let dataString = dataField.text, dataString != "" {
                guard let data = dataString.data(using: .utf8) else { return }
                guard let jsonString = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] else { return }

                callTx.params(jsonString)
            } else {
                callTx.params([:])
            }
            
            guard let txData = try? callTx.toDic() else { return }
            
            let payload = self.generateJSONRPC(params: txData)
            
            param["payload"] = payload
            
            let confirm = UIAlertController(title: "", message: "\(param)", preferredStyle: .alert)
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
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
            param["payload"] = json
            
            let confirm = UIAlertController(title: "", message: "\(param)", preferredStyle: .alert)
            confirm.addAction(UIAlertAction(title: "Send", style: .cancel, handler: { action in
                self.send(command: .jsonrpc, params: param)
            }))
            self.present(confirm, animated: true, completion: nil)
        } catch let error as NSError {
            print(error)
        }
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
    
    func generateJSONRPC(params: [String: Any]) -> [String: Any] {
        var basic = ["jsonrpc": "2.0",
                     "method": "icx_sendTransaction",
                     "id": getID()] as [String : Any]
        
        basic["params"] = params
        return basic
    }
    
    func getID() -> Int {
        return Int(arc4random_uniform(9999))
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
