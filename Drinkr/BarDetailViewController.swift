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
import FBSDKLoginKit
import FBSDKCoreKit
import Firebase
import SVProgressHUD

class BarDetailViewController: UIViewController, FBSDKSharingDelegate {
    
    @IBOutlet var barName: UILabel!
    @IBOutlet var barAddress: UITextField!
    @IBOutlet var dealUntil: UITextField!
    @IBOutlet var telephoneField: UITextField!
    @IBOutlet var drinksTable: UITableView!
    @IBOutlet var header: UIImageView!
    @IBOutlet var vDays: UIView!
    @IBOutlet var btnCheckin: UIButton!
    @IBOutlet var btnLike: FBSDKLikeButton!
    
    //let cellReuseIdentifier = "DrinksTableviewCell"
    
    var SelectedDayTodealsOn:String?
    var DealOnSelectedDay:Dictionary<String,AnyObject> = [:]
    var isRefreshingData = false
    
    var ref:FIRDatabaseReference = FIRDatabase.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //drinksTable.registerClass(DrinksTableviewCell.self, forCellReuseIdentifier: "DrinksTableviewCell")
        
        SelectedDayTodealsOn = NSDate().daysOfTheWeek().AllDays[0]
        print("selectedBar",selectedBar)
        
        if let isDrinkAvailOnCheckIn = selectedBar["drinkForCheckIn"] as? String
            where isDrinkAvailOnCheckIn == drinkForCheckIn
        {
            self.btnCheckin.enabled = true
        } else {
            self.btnCheckin.backgroundColor = UIColor.darkGrayColor()
            self.btnCheckin.enabled = false
        }
        
        //btnLike.objectType = FBSDKLikeObjectType.Page
        //btnLike.objectID = "https://www.facebook.com/ecreateinfotech/"
        
        let likeButton:FBSDKLikeControl = FBSDKLikeControl()
        likeButton.likeControlStyle = .BoxCount
        likeButton.objectID = "https://www.facebook.com/ecreateinfotech/";
        likeButton.center = CGPoint(x: self.btnCheckin.center.x - 46, y: self.btnCheckin.center.y + 42)
        self.view.addSubview(likeButton)
        
        //let horizontalConstraint = NSLayoutConstraint(item: likeButton, attribute: .Top, relatedBy: .Equal, toItem: btnCheckin, attribute: .Bottom, multiplier: 1, constant: 1)
        //let verticalConstraint = NSLayoutConstraint(item: likeButton, attribute: .CenterY, relatedBy: .Equal, toItem: btnCheckin, attribute: .CenterY, multiplier: 1, constant: 1)
        //likeButton.addConstraints([horizontalConstraint, verticalConstraint])
        
        DealOnSelectedDay = (selectedBar["drinkSpecials"] as? Dictionary<String,AnyObject>)?[SelectedDayTodealsOn!] as? Dictionary<String,AnyObject> ?? [:]
        
        //Sliding control
        let sControl = SlidingControl(sectionTitles: NSDate().daysOfTheWeek().DaysWithToday)
        sControl.autoresizingMask = [.FlexibleRightMargin, .FlexibleWidth]
        vDays.layoutIfNeeded()
        sControl.frame = vDays.frame
        sControl.frame.origin.y = 0
        sControl.segmentEdgeInset = UIEdgeInsetsMake(0, 10, 10, 10)
        sControl.selectionStyle = SlidingControlSelectionStyle.FullWidthStripe
        sControl.selectionIndicatorLocation = .Down
        sControl.verticalDividerEnabled = true
        sControl.verticalDividerWidth = 0.5
        sControl.verticalDividerColor = clrDarkBlue
        sControl.selectionIndicatorColor = UIColor.redColor()
        sControl.backgroundColor = clrBlue
        
        sControl.titleFormatter = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        sControl.selectionIndicatorColor = UIColor.blackColor()
        sControl.addTarget(self, action: #selector(VenueInformationViewController.sliderControlChangedValue(_:)), forControlEvents: .ValueChanged)
        vDays.addSubview(sControl)
        
        
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
        
        
        if let imageUrl = selectedBar["imageUrl"] as? String {
            header.setImageWithURL(NSURL(string: imageUrl), placeholderImage: UIImage(named: "BarPlaceholder.jpg"), usingActivityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        }
        barName.text = selectedBar["venueName"] as? String ?? ""
        barAddress.text = selectedBar["venueAddress"] as? String ?? ""
        dealUntil.text = ("\((selectedBar["venueOpenUntil"] as? String ?? "")!) - \((selectedBar["venueOpenFrom"] as? String ?? "")!)")
        telephoneField.text = selectedBar["venueTelephone"] as? String ?? ""
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sliderControlChangedValue(sliderControl:SlidingControl)
    {
        print("Selected index \(sliderControl.selectedSegmentIndex) UIControlEventValueChanged")
        print("Selected Day - \(NSDate().daysOfTheWeek().AllDays[sliderControl.selectedSegmentIndex])")
        
        SelectedDayTodealsOn = NSDate().daysOfTheWeek().AllDays[sliderControl.selectedSegmentIndex]
        DealOnSelectedDay = (selectedBar["drinkSpecials"] as? Dictionary<String,AnyObject>)?[SelectedDayTodealsOn!] as? Dictionary<String,AnyObject> ?? [:]
        self.drinksTable.reloadData()
    }
    

    // MARK: - Tableview Delegates
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView != self.drinksTable {
            return 0
        }
        
        if DealOnSelectedDay.keys.count == 0 {
            let emptyLabel = UILabel(frame: tableView.frame)
            emptyLabel.text = "No deal available for \((self.SelectedDayTodealsOn ?? "")!)"
            emptyLabel.textColor = UIColor.lightGrayColor();
            emptyLabel.font = UIFont(name: emptyLabel.font?.fontName ?? "", size: 11)
            emptyLabel.textAlignment = .Center;
            emptyLabel.numberOfLines = 3
            
            tableView.backgroundView = emptyLabel
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
            return 0
        } else {
            tableView.backgroundView = nil
            return DealOnSelectedDay.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        let cell:DrinksTableviewCell = self.drinksTable.dequeueReusableCellWithIdentifier("DrinksTableviewCell") as! DrinksTableviewCell
        
        let key = ([String] (DealOnSelectedDay.keys))[indexPath.row]
        let dict = DealOnSelectedDay[key] as? Dictionary<String,AnyObject> ?? [:]
        
        //cell = self.drinksTable.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as? DrinksTableviewCell
        let drinks = dict["Drink"] as? String ?? ""
        let prices = (dict["Price"] as? String ?? "0").toDouble() ?? 0
        
        cell.lblDrinkName.text = drinks
        cell.lblPrice.text = "£\((prices == 0) ? "Free" : String(format: "%0.2f", prices))"
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: -
    @IBAction func freeDrinkFor(sender: AnyObject)
    {
        
        //---------------------------------------------
        // METHOD 1
        //---------------------------------------------
        
//        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
//            let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
//            facebookSheet.setInitialText("Share on Facebook")
//            self.presentViewController(facebookSheet, animated: true, completion: nil)
//        } else {
//            let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.Alert)
//            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
//            self.presentViewController(alert, animated: true, completion: nil)
//        }
        
        /*if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
            NSLog(@"publish_actions is already granted.");
        } else {
            FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
            [loginManager logInWithPublishPermissions:@[@"publish_actions"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            //TODO: process error or result.
            }];
        }
        
        if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
            [[[FBSDKGraphRequest alloc]
                initWithGraphPath:@"me/feed"
                parameters: @{ @"message" : @"hello world!"}
            HTTPMethod:@"POST"]
            startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    NSLog(@"Post id:%@", result[@"id"]);
                }
            }];
        }*/
        
        print("Token : \(FBSDKAccessToken.currentAccessToken().tokenString)")
        
        
        //---------------------------------------------
        // METHOD 2
        //---------------------------------------------
        
        // Share using FB SDK to identify actual sharing result.
        let content = FBSDKShareLinkContent()
        content.contentDescription = "Drinkr app"
        content.contentTitle = "I just claimed a free drink via Drinkr at \((selectedBar["venueName"] as? String ?? "")!).)!"
        //content.contentURL = NSURL(string: "https://www.google.co.in/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png")
        content.imageURL = NSURL(string: "https://www.google.co.in/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png")
        //content.imageURL = NSURL(string: selectedBar["imageUrl"] as? String ?? "https://www.google.co.in/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png")
        
        FBSDKShareDialog.showFromViewController(self, withContent: content, delegate: self)
        
        //---------------------------------------------
        // METHOD 3
        //---------------------------------------------
        // Test Purpose - TO PUBLISH USING GRAPH API
        // Require >> publish_actions << Permission
        //---------------------------------------------
        
        /*
        if (FBSDKAccessToken.currentAccessToken().hasGranted("publish_actions")) {
            print("publish_actions is already granted. Token-\(FBSDKAccessToken.currentAccessToken())")
            
            FBSDKGraphRequest.init(graphPath: "me/feed", parameters: ["message" : "hello world!"], HTTPMethod: "POST").startWithCompletionHandler({ (connection, result, error) in
                print("Post id : \(result) -- \(result["id"])")
            })
        } else {
            SVProgressHUD.showErrorWithStatus("Missing facebook permission!")
            
            let FBLoginManager = FBSDKLoginManager()
            FBLoginManager.loginBehavior = FBSDKLoginBehavior.Web;
            FBLoginManager.logInWithPublishPermissions(["publish_actions"],
                                                       fromViewController: self,
                                                       handler: { (response:FBSDKLoginManagerLoginResult!, error: NSError!) in
                if(error != nil) {
                    // Handle error
                }
                else if(response.isCancelled) {
                    // Authorization has been canceled by user
                    print("Login Cancelled  Token : \(response.token)")
                }
                else {
                    // Authorization successful
                    print(FBSDKAccessToken.currentAccessToken())
                    // no longer necessary as the token is already in the response
                    print(response.token.tokenString)
                }
            })
            //FBSDKLoginManager
        }
        */
        
        
        //Test Purpose
        //let tokenVC = self.storyboard?.instantiateViewControllerWithIdentifier("TokenViewController") as? TokenViewController
        //self.navigationController?.pushViewController(tokenVC!, animated: true)
    }
    
    @IBAction func backButton(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - FBSDKSharingDelegate!
    func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        print("Sharing success : ",results)
        //if results["postId"] != nil {
            //SVProgressHUD.showSuccessWithStatus("Thank you!")
            
            let calendar = NSCalendar.currentCalendar()
            let expirationDate = calendar.dateByAddingUnit(.Minute, value: 20, toDate: NSDate(), options: [])
            
            SVProgressHUD.showWithStatus("Loading..")
            let data:Dictionary<String,AnyObject> = ["userId" : myUserID ?? "", "postId": results["postId"] ?? "","venueId":selectedBar["key"] ?? "","venueName":selectedBar["venueName"] ?? "", "sharedAt": NSDate().timeIntervalSinceNow,"sharedDate": NSDate().strDateInUTC,"expirationDate": expirationDate!.strDateInUTC]
            ref.child("checkin").queryOrderedByChild("userId").queryEqualToValue(myUserID ?? "").queryLimitedToLast(1).observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
                
                print("\(NSDate().timeIntervalSince1970)")
                //self.tblGroups.reloadData()
                var founds = false
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
                    
                    
                    print((placeDict["sharedDate"] as? String)?.asDateUTC)
                    if ((placeDict["sharedDate"] as? String)?.asDateUTC?.isCheckinWithinSameDay() == true) {
                        founds = true
                    }
                }
                
                if founds == true {
                    SVProgressHUD.showErrorWithStatus("You can not use another deal in same day!")
                } else {
                    SVProgressHUD.showWithStatus("Loading..")
                    self.ref.child("checkin").childByAutoId().updateChildValues(data, withCompletionBlock: { (error, FRef) in
                        if error != nil {
                            print("Error : ",error)
                            SVProgressHUD.showErrorWithStatus("Failed to save coupon!")
                        } else {
                            SVProgressHUD.showSuccessWithStatus("Thank you!")
                            let tokenVC = self.storyboard?.instantiateViewControllerWithIdentifier("TokenViewController") as? TokenViewController
                            self.navigationController?.pushViewController(tokenVC!, animated: true)
                        }
                    })
                }
            })
            
//        } else {
//            SVProgressHUD.showErrorWithStatus("Sharing failed!")
//        }
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
