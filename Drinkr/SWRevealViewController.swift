//
//  SWRevealViewController.swift
//  Drinkr
//
//  Created by Dustin Allen on 10/14/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import SWRevealViewController
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import SVProgressHUD

class SWRevealViewController: UIViewController {
    
    @IBOutlet var barName: UILabel!
    @IBOutlet var instructions: UILabel!
    
    var ref:FIRDatabaseReference = FIRDatabase.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        refreshData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshData()
    {
        //firebaseRef.childByAppendingPath("registered_users")
        //registeredUserRef.queryOrderedByChild("name")
        
        ref.child("checkin").queryOrderedByChild("userId").queryEqualToValue(myUserID ?? "").queryLimitedToLast(1).observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
            
            var CardAvailable = false
            
            print("\(NSDate().timeIntervalSince1970)")
            //self.tblGroups.reloadData()
            for child in snapshot.children {
                
                var placeDict = Dictionary<String,AnyObject>()
                let childDict = child.valueInExportFormat() as! NSDictionary
                //print(childDict)
                
                //let jsonDic = NSJSONSerialization.JSONObjectWithData(childDict, options: NSJSONReadingOptions.MutableContainers, error: &error) as Dictionary<String, AnyObject>;
                for key : AnyObject in childDict.allKeys {
                    let stringKey = key as! String
                    if let keyValue = childDict.valueForKey(stringKey) as? String {
                        placeDict[stringKey] = keyValue
                    } else if let keyValue = childDict.valueForKey(stringKey) as? Double {
                        placeDict[stringKey] = "\(keyValue)"
                    }
                    else if let keyValue = childDict.valueForKey(stringKey) as? Dictionary<String,AnyObject> {
                        placeDict[stringKey] = keyValue
                    }
                    else if let keyValue = childDict.valueForKey(stringKey) as? NSDictionary {
                        placeDict[stringKey] = keyValue
                    }
                }
                placeDict["key"] = child.key
                
                self.barName.text = placeDict["venueName"] as? String ?? ""
                
                print((placeDict["sharedDate"] as? String)?.asDateUTC)
                print((placeDict["sharedDate"] as? String)?.asDateUTC?.isCheckinWithinSameDay())
                
                CardAvailable = true
            }
            if CardAvailable == false {
                SVProgressHUD.showWithStatus("You do not have any deal!")
            }
        })
    }
    
    @IBAction func redeemButton(sender: AnyObject) {
        
    }

    @IBAction func logoutButton(sender: AnyObject)
    {
        let actionSheetController = UIAlertController (title: "Message", message: "Are you sure want to logout?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        actionSheetController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        actionSheetController.addAction(UIAlertAction(title: "Logout", style: UIAlertActionStyle.Destructive, handler: { (actionSheetController) -> Void in
            print("handle Logout action...")
            //Firebase
            try! FIRAuth.auth()?.signOut()
            
            //Facebook
            let loginManager: FBSDKLoginManager = FBSDKLoginManager()
            loginManager.logOut()
            
            //App States
            AppState.sharedInstance.signedIn = false
            let loginViewController = self.storyboard?.instantiateViewControllerWithIdentifier("InitialViewController") as! InitialViewController!
            self.navigationController?.pushViewController(loginViewController, animated: true)
        }))
        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }
}
