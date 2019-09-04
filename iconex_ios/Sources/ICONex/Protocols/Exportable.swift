//
//  Exportable.swift
//  iconex_ios
//
//  Created by a1ahn on 04/09/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import UIKit

protocol Exportable {
    
}

extension Exportable where Self: UIViewController {
    func export(filepath: URL, _ completion: UIActivityViewController.CompletionWithItemsHandler?) {
        let activity = UIActivityViewController(activityItems: [filepath], applicationActivities: nil)
        activity.excludedActivityTypes = [.postToVimeo, .postToWeibo, .postToFlickr, .postToTwitter, .postToFacebook, .postToTencentWeibo, .addToReadingList, .assignToContact, .openInIBooks]
        activity.completionWithItemsHandler = completion
        
        self.present(activity, animated: true, completion: nil)
    }
}
