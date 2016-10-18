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
import SVProgressHUD

class ViewBarViewController: UIViewController, FBSDKSharingDelegate {
    
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
//        ref.child("venues").child(selectedBar["key"] as? String ?? "").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
//            if let venueName = snapshot.value!["venueName"] {
//                self.barName.text = venueName as! String!
//            }
//            if let venueAddress = snapshot.value!["venueAddress"] {
//                self.barAddress.text = venueAddress as! String!
//            }
//            if let dealsEnd = snapshot.value!["venueOpenUntil"] {
//                self.dealUntil.text = dealsEnd as! String!
//            }
//            if let telephone = snapshot.value!["venueTelephone"] {
//                self.telephoneField.text = telephone as! String!
//            }
//        })
        
        
        barName.text = selectedBar["venueName"] as? String ?? ""
        barAddress.text = selectedBar["venueAddress"] as? String ?? ""
        dealUntil.text = selectedBar["venueOpenUntil"] as? String ?? ""
        telephoneField.text = selectedBar["venueTelephone"] as? String ?? ""
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func freeDrinkFor(sender: AnyObject)
    {
//        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
//            let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
//            facebookSheet.setInitialText("Share on Facebook")
//            self.presentViewController(facebookSheet, animated: true, completion: nil)
//        } else {
//            let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.Alert)
//            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
//            self.presentViewController(alert, animated: true, completion: nil)
//        }
        
        
        //Share using FB SDK to identify actual sharing result.
        let content = FBSDKShareLinkContent()
        content.contentTitle = "I’m Checking In At \((selectedBar["venueName"] as? String ?? "")!)!"
        //content.contentURL = NSURL(string: "https://www.google.co.in/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png")
        content.imageURL = NSURL(string: "https://www.google.co.in/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png")
        
        FBSDKShareDialog.showFromViewController(self, withContent: content, delegate: self)
        
    }
    
    @IBAction func backButton(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - FBSDKSharingDelegate!
    func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        print("Sharing success : ",results)
        if results["postId"] != nil {
            SVProgressHUD.showSuccessWithStatus("Thank you!")
        } else {
            SVProgressHUD.showErrorWithStatus("Sharing failed!")
        }
    }
    
    func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!) {
        print("Sharing Failed, error : ",error)
        SVProgressHUD.showErrorWithStatus("Sharing failed!")
    }
    
    func sharerDidCancel(sharer: FBSDKSharing!) {
        print("Sharing Canceled")
        SVProgressHUD.showInfoWithStatus("Opps, It seems like you canceled sharing and you will not eligible for free deal")
    }
    
}
