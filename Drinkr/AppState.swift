//
//  AppState.swift
//  Drinkr
//
//  Created by Dustin Allen on 10/5/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import CoreLocation

class AppState: NSObject {
    
    static let sharedInstance = AppState()
    
    var signedIn = false
    var displayName: String?
    var photoUrl: NSURL?    
    var currentUser: FIRDataSnapshot!
    var myProfile: UIImage?
    var venue: UserData?
    var venueInfo: String?
    
}


//FireBase Storage
let storage = FIRStorage.storage()
let storageRef = storage.reference()

let myUserID = {
    return FIRAuth.auth()?.currentUser?.uid
}()

//Globals
var bars:[Dictionary<String,AnyObject>] = []
var filteredBars:[Dictionary<String,AnyObject>] = []
var selectedBar: Dictionary<String,AnyObject> = [:]

