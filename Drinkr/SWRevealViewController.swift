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

    @IBAction func logoutButton(sender: AnyObject) {
        try! FIRAuth.auth()?.signOut()
        AppState.sharedInstance.signedIn = false
        let loginViewController = self.storyboard?.instantiateViewControllerWithIdentifier("InitialViewController") as! InitialViewController!
        self.navigationController?.pushViewController(loginViewController, animated: true)
    }
}
