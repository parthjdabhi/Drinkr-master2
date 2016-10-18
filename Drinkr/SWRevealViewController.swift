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

class SWRevealViewController: UIViewController {
    
    @IBOutlet var barName: UILabel!
    @IBOutlet var instructions: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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