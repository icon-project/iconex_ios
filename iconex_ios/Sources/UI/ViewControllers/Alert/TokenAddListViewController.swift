//
//  TokenAddListViewController.swift
//  iconex_ios
//
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit

class TokenAddListCell: UITableViewCell {
    @IBOutlet weak var tokenName: UILabel!
    @IBOutlet weak var checkBox: UIImageView!
    @IBOutlet weak var arrow: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var arrowButton: UIButton!
    
}

class TokenAddListViewController: UIViewController {
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
