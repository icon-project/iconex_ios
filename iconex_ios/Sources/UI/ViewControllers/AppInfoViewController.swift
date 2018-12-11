//
//  AppInfoViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

class AppInfoViewController: BaseViewController {

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var currentVersion: UILabel!
    @IBOutlet weak var latestVersion: UILabel!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var openTitle: UILabel!
    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var developer: UIView!
    @IBOutlet weak var developerTitle: UILabel!
    @IBOutlet weak var developerButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initializeUI()
        initialize()
    }
    
    func initialize() {
        closeButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        openButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            let opensource = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "OpenLicenseView")
            self.navigationController?.pushViewController(opensource, animated: true)
        }).disposed(by: disposeBag)
        
        developerButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: { [unowned self] in
            let developer = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "DeveloperView")
            self.navigationController?.pushViewController(developer, animated: true)
        }).disposed(by: disposeBag)
        
        updateButton.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: {
            UIApplication.shared.open(URL(string: "itms-apps://itunes.apple.com/app/iconex-icon-wallet/id1368441529?mt=8")!, options: [:], completionHandler: nil)
        }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        let app = UIApplication.shared.delegate as! AppDelegate
        let latest = app.all!
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        icon.corner(12)
        navTitle.text = "AppInfo.Title".localized
        currentVersion.text = "AppInfo.Current".localized + " " + version
        latestVersion.text = "AppInfo.Latest".localized + " " + latest
        updateButton.styleDark()
        updateButton.cornered()
        updateButton.setTitle("AppInfo.Update".localized, for: .normal)
        openTitle.text = "AppInfo.License".localized
        developerTitle.text = "AppInfo.DeveloperMode".localized
        
        updateButton.isHidden = !(latest > version)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        developer.isHidden = UserDefaults.standard.object(forKey: "Developer") == nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
