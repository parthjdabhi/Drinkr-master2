//
//  AppState.swift
//  Drinkr
//
//  Created by Dustin Allen on 10/5/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import Foundation
import Firebase
import UIKit

class AppState: NSObject {
    
    static let sharedInstance = AppState()
    
    var signedIn = false
    var displayName: String?
    var photoUrl: NSURL?    
    var currentUser: FIRDataSnapshot!
    var myProfile: UIImage?
    var venue: UserData?
    var venueInfo: String?
    
    static func MyUserID() -> String {
        return FIRAuth.auth()?.currentUser?.uid ?? ""
    }
}