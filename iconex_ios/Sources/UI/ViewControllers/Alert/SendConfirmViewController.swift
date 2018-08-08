//
//  SendConfirmViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SendConfirmViewController: UIViewController {
    @IBOutlet weak var alertContainer: UIView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var amountTitle: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var feeTitle: UILabel!
    @IBOutlet weak var feeLabel: UILabel!
    @IBOutlet weak var addressTitle: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    var type: String!
    var value: String!
    var fee: String!
    var feeType: String!
    var address: String!
    
    var handler: (() -> Void)?
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initialize() {
        alertContainer.corner(12)
        
        topLabel.text = "Alert.Transfer.Title".localized
        amountTitle.text = "Alert.Transfer.Amount".localized + " (" + self.type.uppercased() + ")"
        amountLabel.text = self.value
        feeTitle.text = "Alert.Transfer.Fee".localized + " (" + self.feeType.uppercased() + ")"
        feeLabel.text = self.fee
        addressTitle.text = "Alert.Transfer.Address".localized
        addressLabel.text = self.address
        
        cancelButton.setTitle("Common.Cancel".localized, for: .normal)
        cancelButton.styleDark()
        confirmButton.setTitle("Transfer.Transfer".localized, for: .normal)
        confirmButton.styleLight()
        
        cancelButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        confirmButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                if let completion = self.handler {
                    self.confirmButton.isEnabled = false
                    self.confirmButton.setTitle("", for: .normal)
                    let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: self.confirmButton.frame.width / 2 - 20, y: self.confirmButton.frame.height / 2 - 20), size: CGSize(width: 40, height: 40)))
                    imageView.image = #imageLiteral(resourceName: "icRefresh01")
                    imageView.tag = 999
                    self.confirmButton.addSubview(imageView)
                    Tools.rotateAnimation(inView: imageView)
                    
                    completion()
                }
            }).disposed(by: disposeBag)
    }

}
