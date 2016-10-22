//
//  TokenViewController.swift
//  Drinkr
//
//  Created by iParth on 10/22/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import SWRevealViewController
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import SVProgressHUD

class TokenViewController: UIViewController, CountdownLabelDelegate {
    
    
    // MARK: - Refrence
    @IBOutlet var lblInstructions: UILabel!
    @IBOutlet var lblBarName: UILabel!
    @IBOutlet var btnRedeem: UIButton!
    @IBOutlet var lblTime: CountdownLabel!
    
    // MARK: - Properties
    var ref:FIRDatabaseReference = FIRDatabase.database().reference()
    var LastToken: Dictionary<String,AnyObject> = [:]
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.lblTime.text = "Expires within - "
        self.lblBarName.text = "-"
        self.btnRedeem.enabled = false
        
        //lblTime.countdownDelegate = self
        //lblTime.setCountDownTime(1*60)
        lblTime.animationType = .Evaporate
        lblTime.textColor = .orangeColor()
        lblTime.font = UIFont(name:"Avenir Medium", size:17)
        //lblTime.start()
        
        lblTime.then(30) { [unowned self] in
            //self.lblTime.animationType = .Pixelate
            self.lblTime.textColor = .greenColor()
        }
        lblTime.then(10) { [unowned self] in
            self.lblTime.animationType = .Sparkle
            self.lblTime.textColor = .yellowColor()
        }
        
        lblTime.start() {
            self.lblTime.textColor = .whiteColor()
        }
        
        print("selectedBar",selectedBar)
        
        self.refreshData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
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
                
                self.LastToken = placeDict
                
                self.lblBarName.text = placeDict["venueName"] as? String ?? ""
                
                print((placeDict["sharedDate"] as? String)?.asDateUTC)
                print((placeDict["expirationDate"] as? String)?.asDateUTC)
                
                print(NSDate().strDateInUTC)
                print(NSDate().strDateInUTC.asDateUTC)
                
                print((placeDict["sharedDate"] as? String)?.asDateUTC?.isCheckinWithinSameDay())
                //expirationDate
                
                print((placeDict["sharedDate"] as? String)?.asDateUTC?.isExpiredDate(NSDate()))
                print(NSDate().timeIntervalSinceDate(((placeDict["sharedDate"] as? String)?.asDateUTC)!))
                
                print((placeDict["expirationDate"] as? String)?.asDateUTC?.isExpiredDate(NSDate()))
                print(NSDate().timeIntervalSinceDate(((placeDict["expirationDate"] as? String)?.asDateUTC)!))
                
                print(NSDate().isExpiredDate(((placeDict["sharedDate"] as? String)?.asDateUTC)!))
                print((placeDict["sharedDate"] as? String)?.asDateUTC?.timeIntervalSinceDate(NSDate()))
                
                print(NSDate().isExpiredDate(((placeDict["expirationDate"] as? String)?.asDateUTC)!))
                print((placeDict["expirationDate"] as? String)?.asDateUTC?.timeIntervalSinceDate(NSDate()))
                
                if let RemainingTime = (placeDict["expirationDate"] as? String)?.asDateUTC?.timeIntervalSinceDate(NSDate())
                    where RemainingTime > 0
                {
                    self.lblTime.countdownDelegate = self
                    self.lblTime.setCountDownTime(RemainingTime)
                    self.lblTime.start()
                }
                
                
                CardAvailable = true
            }
            if CardAvailable == false {
                SVProgressHUD.showWithStatus("You do not have any deal!")
            }
        })
    }
    
    // MARK: - Countdown label
    func countdownFinished()
    {
        SVProgressHUD.showInfoWithStatus("Your card is expired!")
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - Action
    @IBAction func actionGoToBack(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func actionRedeemToken(sender: AnyObject)
    {
        SVProgressHUD.showWithStatus("Loading..")
        let data:Dictionary<String,AnyObject> = ["isRedeemed" : "true","redeemedDate": NSDate().strDateInUTC]
        self.ref.child("checkin").child(self.LastToken["key"] as? String ?? "").updateChildValues(data, withCompletionBlock: { (error, FRef) in
            if error != nil {
                print("Error : ",error)
                SVProgressHUD.showErrorWithStatus("Failed to redeem!")
            } else {
                SVProgressHUD.showSuccessWithStatus("Card redeemed!\nThank you!")
                self.navigationController?.popViewControllerAnimated(true)
            }
        })
        
        //self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - other Methods
}
