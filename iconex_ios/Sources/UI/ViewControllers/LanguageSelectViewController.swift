//
//  LanguageSelectViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit

class LanguageSelectCell: UITableViewCell {
    @IBOutlet weak var radio: UIImageView!
    @IBOutlet weak var cellTitle: UILabel!
    
}

class LanguageSelectViewController: BaseViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }
    
    func initialize() {
        closeButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                self.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        navTitle.text = "Side.Language".localized
        tableView.tableFooterView = UIView()
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func languageChanged() {
        initializeUI()
    }
}

extension LanguageSelectViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageSelectCell", for: indexPath) as! LanguageSelectCell
        
        var language = ""
        if let selected = UserDefaults.standard.string(forKey: "selectedLanguage") {
            language = selected
        } else {
            let appleLan = UserDefaults.standard.array(forKey: "AppleLanguages")![0] as! String
            let strip = String(appleLan.prefix(2))
            language = strip
        }
        
        switch indexPath.row {
        case 0:
            cell.cellTitle.text = "Language.Korean".localized
            cell.radio.isHighlighted = language == "ko"
            
        case 1:
            cell.cellTitle.text = "Language.English".localized
            cell.radio.isHighlighted = language != "ko"
            
        default:
            break
            
        }
        return cell
    }
}

extension LanguageSelectViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        var arr = ""
        if indexPath.row == 0 {
            arr = "ko"
        } else {
            arr = "en"
        }
        
        let app = UIApplication.shared.delegate as! AppDelegate
        app.changeLanguage(language: arr)
    }
}
