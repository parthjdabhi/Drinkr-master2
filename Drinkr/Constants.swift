//
//  Constants.swift
//  Drinkr
//
//  Created by Dustin Allen on 10/5/16.
//  Copyright © 2016 Harloch. All rights reserved.
//



struct Constants {
    
    struct NotificationKeys {
        static let SignedIn = "onSignInCompleted"
    }
    
    struct Segues {
        static let AddSocial = "AddSocial"
        static let FpToSignIn = "FPToSignIn"
    }
    
    struct MessageFields {
        static let name = "name"
        static let text = "text"
        static let photoUrl = "photoUrl"
        static let imageUrl = "imageUrl"
    }
}

let clrBlack = UIColor.init(rgb: 0x222831)
let clrBlue = UIColor.init(rgb: 0x3CA0DD)
let clrDarkBlue = UIColor(red: 35/255.0, green: 98/255.0, blue: 163/255.0, alpha: 0.8)

let clrPurple = UIColor(red: 154/255.0, green: 88/255.0, blue: 186/255.0, alpha: 1.0)