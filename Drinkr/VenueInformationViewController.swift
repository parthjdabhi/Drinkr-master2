//
//  VenueInformationViewController.swift
//  Drinkr
//
//  Created by Dustin Allen on 10/6/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

import FBSDKCoreKit
import FBSDKLoginKit

import CoreLocation
import IQKeyboardManagerSwift
import IQDropDownTextField

import SVProgressHUD
import SDWebImage
import UIActivityIndicator_for_SDWebImage

class VenueInformationViewController: UIViewController, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, IQDropDownTextFieldDelegate {
    
    @IBOutlet var vDays: UIView!
    @IBOutlet var checkIcon: UIButton!
    @IBOutlet var editIcon: UIButton!
    @IBOutlet var header: UIImageView!
    @IBOutlet var addressField: UITextField!
    @IBOutlet var detailsField: UITextField!
    @IBOutlet var telephoneField: UITextField!
    @IBOutlet var barName: UILabel!
    @IBOutlet var drinkForCheckInBool: UISwitch!
    @IBOutlet var drinkForLikeBool: UISwitch!
    
    @IBOutlet var startTime: IQDropDownTextField?
    @IBOutlet var endTime: IQDropDownTextField?
    @IBOutlet var drinkTable: UITableView!
    
    let cellReuseIdentifier = "cell"
    let cellReuseIdentifier1 = "cell1"
    var imagePickerController: UIImagePickerController!
    
    //var drinkArray = [""]
    //var priceArray = [""]
    //var drinkString = ""
    //var priceString = ""
    
    var SelectedDayTodealsOn:String?
    var DealOnSelectedDay:[Dictionary<String,AnyObject>] = []
    var isRefreshingData = false
    
    var ref:FIRDatabaseReference = FIRDatabase.database().reference()
    var latGained:Double = Double()
    var longGained:Double = Double()
    var deleteDrinkIndexPath: NSIndexPath? = nil
    
    let alertController = UIAlertController()
    
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        drinkForCheckInBool.addTarget(self, action: #selector(VenueInformationViewController.switchIsChanged2(_:)), forControlEvents: UIControlEvents.ValueChanged)
        drinkForLikeBool.addTarget(self, action: #selector(VenueInformationViewController.switchIsChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        print("myUserID : ",myUserID)
        
        SelectedDayTodealsOn = NSDate().daysOfTheWeek().AllDays[0]
        refreshDealData()
        
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
        sControl.verticalDividerColor = UIColor.whiteColor()
        sControl.verticalDividerWidth = 1.0
        sControl.backgroundColor = UIColor.blueColor()
        
        sControl.titleFormatter = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        sControl.selectionIndicatorColor = UIColor.blackColor()
        sControl.addTarget(self, action: #selector(VenueInformationViewController.sliderControlChangedValue(_:)), forControlEvents: .ValueChanged)
        vDays.addSubview(sControl)
        
        print("2016-08-02 00:00:00".asDateUTC)
        print("2016-08-02 00:00:00".asDateUTC?.formattedWith("HH:mm"))
        print("2016-08-02 00:00:00".asDateLocal)
        print("2016-08-02 00:00:00".asDateLocal?.formattedWith("HH:mm"))
        
        let SDate = "2016-08-02 10:00:00".asDateLocal
        let EDate = "2016-08-02 22:00:00".asDateLocal
        
        startTime?.isOptionalDropDown = false
        startTime?.dropDownMode = IQDropDownMode.TimePicker
        startTime?.setDate(SDate, animated: true)
        startTime?.delegate = self
        
        endTime?.isOptionalDropDown = false
        endTime?.dropDownMode = IQDropDownMode.TimePicker
        endTime?.setDate(EDate, animated: true)
        endTime?.delegate = self
        
        addressField.userInteractionEnabled = false
        detailsField.userInteractionEnabled = false
        telephoneField.userInteractionEnabled = false
        checkIcon.hidden = true
        
        let imgTapGesture = UITapGestureRecognizer(target: self, action: #selector(VenueInformationViewController.onTapProfilePic(_:)) )
        imgTapGesture.numberOfTouchesRequired = 1
        imgTapGesture.cancelsTouchesInView = true
        header.addGestureRecognizer(imgTapGesture)
        
        drinkTable.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        drinkTable.delegate = self
        drinkTable.dataSource = self
        
        if addressField.text == "" {
            addressField.text = "Enter Your Address Information"
        }
        if detailsField.text == "" {
            detailsField.text = "Deals Until"
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        
        // Show/Save selected date
        print("Start Time : ",startTime?.date?.strDateInUTC)
        print("End Time : ",endTime?.date?.strDateInUTC)
        
        if addressField.text == "" {
            addressField.text = "Enter Your Address Information"
        }
        if detailsField.text == "" {
            detailsField.text = "Deals Until"
        }
        
        SVProgressHUD.showWithStatus("Loading..")
        ref = FIRDatabase.database().reference()
        ref.child("venues").child(myUserID ?? "").observeEventType(FIRDataEventType.Value, withBlock: { snapshot in
            
            SVProgressHUD.dismiss()
            if let venueAddress = snapshot.value!["venueAddress"] {
                self.addressField.text = venueAddress as? String
                self.forwardGeocoding(venueAddress as! String)
            }
            if let venueOpenUntil = snapshot.value!["venueOpenUntil"] {
                self.detailsField.text = venueOpenUntil as? String
            }
            if let venueTelephone = snapshot.value!["venueTelephone"] {
                self.telephoneField.text = venueTelephone as? String
            }
            if let venueName = snapshot.value!["venueName"] {
                self.barName.text = venueName as? String
            }
            if let imageUrl = snapshot.value!["imageUrl"] as? String {
                self.header?.sd_setImageWithURL(NSURL(string: imageUrl))
            }
            
            if let drinkForCheckIn = snapshot.value!["drinkForCheckIn"] as? String
                where drinkForCheckIn == "Drink For Check-In"
            {
                self.drinkForCheckInBool.setOn(true, animated: true)
            } else {
                self.drinkForCheckInBool.setOn(false, animated: true)
            }
            
            if let drinkForLike = snapshot.value!["drinkForLike"] as? String
                where drinkForLike == "Drink For Like"
            {
                self.drinkForLikeBool.setOn(true, animated: true)
            } else {
                self.drinkForLikeBool.setOn(false, animated: true)
            }
            
            if let venueOpenFrom = snapshot.value!["venueOpenFrom"] as? String {
                let SDate = "2016-08-02 \(venueOpenFrom):00".asDateUTC
                print("2016-08-02 \(venueOpenFrom):00".asDateUTC?.formattedWith("HH:mm"))
                self.startTime?.setDate(SDate, animated: true)
            }
            
            if let venueOpenUntil = snapshot.value!["venueOpenUntil"] as? String {
                let EDate = "2016-08-02 \(venueOpenUntil):00".asDateUTC
                print("2016-08-02 \(venueOpenUntil):00".asDateUTC?.formattedWith("HH:mm"))
                self.startTime?.setDate(EDate, animated: true)
            }
            
            self.detailsField.text = "\((snapshot.value!["venueOpenUntil"] as? String ?? "")!) - \((snapshot.value!["venueOpenFrom"] as? String ?? "")!)"
            
        })
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IQDropDownTextFieldDelegate Methods
    func textField(textField: IQDropDownTextField, didSelectDate date: NSDate?) {
        print(date)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        //detailsField
        // Show/Save selected date
        //venueOpenUntil
        //venueOpenFrom
        print("Start Time : ",startTime?.date?.strDateInUTC)
        print("Start Time : ",startTime?.date?.strDateInLocal)
        print("Start Time : ",startTime?.date?.formattedWith("HH:mm"))
        print("End Time : ",endTime?.date?.strDateInUTC)
        
        detailsField.text = "\((startTime?.date?.formattedWith("HH:mm") ?? "")!) - \((endTime?.date?.formattedWith("HH:mm") ?? "")!)"
        
        if let venueOpenFrom = startTime?.date?.formattedWith("HH:mm")
            where textField == startTime {
            self.ref.child("venues").child(myUserID ?? "").updateChildValues(["venueOpenFrom":venueOpenFrom])
            endTime?.minimumDate = startTime?.date
        }
        else if let venueOpenUntil = endTime?.date?.formattedWith("HH:mm")
            where textField == endTime {
            self.ref.child("venues").child(myUserID ?? "").updateChildValues(["venueOpenUntil":venueOpenUntil])
            startTime?.maximumDate = endTime?.date
        }
    }
    
    func sliderControlChangedValue(sliderControl:SlidingControl) {
        print("Selected index \(sliderControl.selectedSegmentIndex) UIControlEventValueChanged")
        print("Selected Day - \(NSDate().daysOfTheWeek().AllDays[sliderControl.selectedSegmentIndex])")
        
        SelectedDayTodealsOn = NSDate().daysOfTheWeek().AllDays[sliderControl.selectedSegmentIndex]
        
        // MARK: -
        //Load Deal For This Day
        refreshDealData()
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
        presentViewController(actionSheetController, animated: true, completion: nil)
        
    }
    
    @IBAction func editButton(sender: AnyObject) {
        
        addressField.userInteractionEnabled = true
        //detailsField.userInteractionEnabled = true
        telephoneField.userInteractionEnabled = true
        editIcon.hidden = true
        checkIcon.hidden = false
    }
    
    @IBAction func checkButton(sender: AnyObject) {
        
        addressField.userInteractionEnabled = false
        //detailsField.userInteractionEnabled = false
        telephoneField.userInteractionEnabled = false
        editIcon.hidden = false
        checkIcon.hidden = true
        
        forwardGeocoding(addressField.text!)
        
        ref = FIRDatabase.database().reference()
        self.ref.child("venues").child(myUserID ?? "").updateChildValues(["venueAddress": self.addressField.text!, "venueTelephone": self.telephoneField.text!, "lat": self.latGained, "long": self.longGained])
        
        if addressField.text == "" {
            viewDidLoad()
        }
        if detailsField.text == "" {
            viewDidLoad()
        }
    }
    
    func onTapProfilePic(sender: UILongPressGestureRecognizer? = nil) {
        // 1
        view.endEditing(true)
        
        // 2
        let imagePickerActionSheet = UIAlertController(title: "Snap/Upload Photo",
                                                       message: nil, preferredStyle: .ActionSheet)
        // 3
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let cameraButton = UIAlertAction(title: "Take Photo",
                                             style: .Default) { (alert) -> Void in
                                                self.imagePickerController = UIImagePickerController()
                                                self.imagePickerController.delegate = self
                                                self.imagePickerController.sourceType = .Camera
                                                self.imagePickerController.allowsEditing = true
                                                self.presentViewController(self.imagePickerController,
                                                                           animated: true,
                                                                           completion: nil)
            }
            imagePickerActionSheet.addAction(cameraButton)
        }
        
        let libraryButton = UIAlertAction(title: "Choose Existing",
                                          style: .Default) { (alert) -> Void in
                                            self.imagePickerController = UIImagePickerController()
                                            self.imagePickerController.delegate = self
                                            self.imagePickerController.sourceType = .PhotoLibrary
                                            self.imagePickerController.allowsEditing = true
                                            self.presentViewController(self.imagePickerController,
                                                                       animated: true,
                                                                       completion: nil)
        }
        imagePickerActionSheet.addAction(libraryButton)
        // 5
        let cancelButton = UIAlertAction(title: "Cancel",
                                         style: .Cancel) { (alert) -> Void in
        }
        imagePickerActionSheet.addAction(cancelButton)
        // 6
        presentViewController(imagePickerActionSheet, animated: true,
                              completion: nil)
    }
    
    func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
        
        var scaledSize = CGSizeMake(maxDimension, maxDimension)
        var scaleFactor:CGFloat
        
        if image.size.width > image.size.height {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        image.drawInRect(CGRectMake(0, 0, scaledSize.width, scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage
        {
            header.image = scaleImage(pickedImage, maxDimension: 300)
            AppState.sharedInstance.myProfile = header.image
            
            let base64String = (header.image!).imgToBase64()
            let strProfile = base64String as String
            let Data = ["image": strProfile]
            
            CommonUtils.sharedUtils.showProgress(self.view, label: "Updating profile..")
            FIRDatabase.database().reference().child("venues").child(myUserID ?? "").updateChildValues(Data, withCompletionBlock: { (error, ref) in
                CommonUtils.sharedUtils.hideProgress()
                if error == nil {
                    CommonUtils.sharedUtils.showAlert(self, title: "Message", message: "Profile updated succcessfully!")
                }
            })
            
            //Saving Image
            let image = CommonUtils.sharedUtils.decodeImage(base64String)
            let imgData: NSData = UIImageJPEGRepresentation(image, 0.8)!
            //CommonUtils.sharedUtils.decodeImage(userPhoto)
            saveImage(imgData,
                      onCompletion: { (downloadURL, imagePath) in
                        print("downloadURL : ",downloadURL)
                        print("imagePath : ",imagePath)
                        
                        let dictData = ["isProfileSavednStorage": "true",
                            "imageUrl": downloadURL,
                            "imagePath": imagePath]
                        FIRDatabase.database().reference().child("venues").child(myUserID ?? "").updateChildValues(dictData)
                        FIRDatabase.database().reference().child("venues").child(myUserID ?? "").child("image").removeValue()
                        CommonUtils.sharedUtils.showAlert(self, title: "Message", message: "Profile updated succcessfully!")
                    })
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController){
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    // MARK: -  Get Data
    func refreshDealData()
    {
        
        if isRefreshingData == true {
            return
        }
        
        isRefreshingData = true
        let myGroup = dispatch_group_create()
        
        //CommonUtils.sharedUtils.showProgress(self.view, label: "Getting list of bars..")
        
        dispatch_group_enter(myGroup)
        
        ref.child("venues").child(myUserID ?? "").child("drinkSpecials").child("\((self.SelectedDayTodealsOn ?? "")!)").observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
            
            self.DealOnSelectedDay.removeAll()
            
            print("\(NSDate().timeIntervalSince1970)")
            //self.tblGroups.reloadData()
            for child in snapshot.children {
                
                var DrinkDict = Dictionary<String,AnyObject>()
                let childDict = child.valueInExportFormat() as! NSDictionary
                //print(childDict)
                
                //let dealsOnDay = child.value!["dealsOnDay"] as! String!
                //if dealsOnDay == self.SelectedDayTodealsOn
                //{
                    //let jsonDic = NSJSONSerialization.JSONObjectWithData(childDict, options: NSJSONReadingOptions.MutableContainers, error: &error) as Dictionary<String, AnyObject>;
                    for key : AnyObject in childDict.allKeys {
                        let stringKey = key as! String
                        if let keyValue = childDict.valueForKey(stringKey) as? String {
                            DrinkDict[stringKey] = keyValue
                        } else if let keyValue = childDict.valueForKey(stringKey) as? Double {
                            DrinkDict[stringKey] = "\(keyValue)"
                        }
                        else if let keyValue = childDict.valueForKey(stringKey) as? Dictionary<String,AnyObject> {
                            DrinkDict[stringKey] = keyValue
                        }
                        else if let keyValue = childDict.valueForKey(stringKey) as? NSDictionary {
                            DrinkDict[stringKey] = keyValue
                        }
                    }
                    
                    DrinkDict["key"] = child.key
                    
                    self.DealOnSelectedDay.append(DrinkDict)
                    
                //}
            }
            
            dispatch_group_leave(myGroup)
        })
        dispatch_group_notify(myGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                // update UI
                CommonUtils.sharedUtils.hideProgress()
                self.isRefreshingData = false
                self.drinkTable.reloadData()
            }
        }
    }
    
    // MARK: -
    func forwardGeocoding(address: String) {
        CLGeocoder().geocodeAddressString(address, completionHandler: { (placemarks, error) in
            if error != nil {
                print(error)
                return
            }
            if placemarks?.count > 0 {
                let placemark = placemarks?[0]
                let location = placemark?.location
                let coordinate = location?.coordinate
                //print("\nlat: \(coordinate!.latitude), long: \(coordinate!.longitude)")
                let newLat = coordinate!.latitude
                let newLong = coordinate!.longitude
                self.latGained = newLat
                self.longGained = newLong
                print(self.latGained)
                print(self.longGained)
            }
        })
    }
    
    func switchIsChanged(mySwitch: UISwitch) {
        let userID = FIRAuth.auth()?.currentUser?.uid
        if mySwitch.on {
            self.ref.child("venues").child(userID!).updateChildValues(["drinkForLike": "Drink For Like"])
        } else {
            self.ref.child("venues").child(userID!).updateChildValues(["drinkForLike": "No Drink For Like Special"])
        }
    }
    
    func switchIsChanged2(mySwitch: UISwitch) {
        let userID = FIRAuth.auth()?.currentUser?.uid
        if mySwitch.on {
            self.ref.child("venues").child(userID!).updateChildValues(["drinkForCheckIn": "Drink For Check-In"])
        } else {
            self.ref.child("venues").child(userID!).updateChildValues(["drinkForCheckIn": "No Drink For Check-In Special"])
        }
    }
    
    @IBAction func addMoreDrinksButton(sender: AnyObject) {
        let alertController = UIAlertController(title: "Specials", message: "Add Your Drink Specials", preferredStyle: .Alert)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .Default) { (_) in
            
            var drinkString = ""
            var priceString = ""
            
            if let field = alertController.textFields![0] as? UITextField {
                print("drinkString")
                drinkString = field.text! as String
            } else {
                print("No Special")
            }
            if let field1 = alertController.textFields![1] as? UITextField {
                priceString = field1.text! as String
            } else {
                print("No Specials")
            }
            
            self.DealOnSelectedDay.append(["Drink" : drinkString, "Price": priceString])
            self.drinkTable.insertRowsAtIndexPaths([NSIndexPath(forRow: self.DealOnSelectedDay.count-1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
            
            self.ref.child("venues").child(myUserID ?? "").child("drinkSpecials").child("\((self.SelectedDayTodealsOn ?? "")!)").childByAutoId().updateChildValues(["Drink" : drinkString, "Price": priceString])
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Drink"
        }
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Price"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView != self.drinkTable {
            return 0
        }
        
        if DealOnSelectedDay.count == 0 {
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
        
        var cell:UITableViewCell?
        
        if tableView == self.drinkTable {
            cell = drinkTable.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
            let drinks = DealOnSelectedDay[indexPath.row]["Drink"] as? String ?? ""
            let prices = DealOnSelectedDay[indexPath.row]["Price"] as? String ?? ""
            let str = "\(drinks)     \(prices)"
            cell!.textLabel!.textAlignment = .Center
            cell!.textLabel!.text = "\(str)"
        }
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete
        {
            deleteDrinkIndexPath = indexPath
            confirmDelete(indexPath.row)
        }
    }
    
    func confirmDelete(index: Int)
    {
        let drinks = DealOnSelectedDay[index]["Drink"] as? String ?? ""
        //let prices = DealOnSelectedDay[index]["Price"] as? String ?? ""
        
        let alert = UIAlertController(title: "Delete Drink", message: "Are you sure you want to permanently delete \"\(drinks)\" ?", preferredStyle: .ActionSheet)
        
        
        let DeleteAction = UIAlertAction(title: "Delete", style: .Destructive) { (Action) in
            
            if let key = self.DealOnSelectedDay[index]["key"] as? String {
                self.ref.child("venues").child(myUserID ?? "").child("drinkSpecials").child("\((self.SelectedDayTodealsOn ?? "")!)").child(key).removeValue()
                
                self.DealOnSelectedDay.removeAtIndex(index)
                self.drinkTable.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                //self.drinkTable.reloadData()
            } else {
                self.DealOnSelectedDay.removeAtIndex(index)
                self.drinkTable.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                //self.drinkTable.reloadData()
            }
        }
        let CancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: cancelDeleteDrink)
        
        alert.addAction(DeleteAction)
        alert.addAction(CancelAction)
        
        // Support display in iPad
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func handleDeleteDrink(alertAction: UIAlertAction!) -> Void {
        if let indexPath = deleteDrinkIndexPath {
            drinkTable.beginUpdates()
            
            //drinkArray.removeAtIndex(indexPath.row)
            //priceArray.removeAtIndex(indexPath.row)
            
            // Note that indexPath is wrapped in an array:  [indexPath]
            drinkTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            
            deleteDrinkIndexPath = nil
            
            drinkTable.endUpdates()
        }
    }
    
    func cancelDeleteDrink(alertAction: UIAlertAction!) {
        deleteDrinkIndexPath = nil
        self.drinkTable.endUpdates()
    }
}