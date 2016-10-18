//
//  ViewBarViewController.swift
//  Drinkr
//
//  Created by Dustin Allen on 10/17/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import Social
import FBSDKShareKit
import Firebase

class ViewBarViewController: UIViewController {
    
    @IBOutlet var barName: UILabel!
    @IBOutlet var barAddress: UITextField!
    @IBOutlet var dealUntil: UITextField!
    @IBOutlet var telephoneField: UITextField!
    @IBOutlet var drinksTable: UITableView!
    @IBOutlet var header: UIImageView!
    @IBOutlet var vDays: UIView!
    
    var ref:FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        let userID = AppState.sharedInstance.venue?.getUid()
        ref.child("venues").child(userID!).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let venueName = snapshot.value!["venueName"] {
                self.barName.text = venueName as! String!
            }
            if let venueAddress = snapshot.value!["venueAddress"] {
                self.barAddress.text = venueAddress as! String!
            }
            if let dealsEnd = snapshot.value!["venueOpenUntil"] {
                self.dealUntil.text = dealsEnd as! String!
            }
            if let telephone = snapshot.value!["venueTelephone"] {
                self.telephoneField.text = telephone as! String!
            }
        })
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func freeDrinkFor(sender: AnyObject) {
        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
            let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            facebookSheet.setInitialText("Share on Facebook")
            self.presentViewController(facebookSheet, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func backButton(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
}
