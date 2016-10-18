//
//  VenueInformationViewController.swift
//  Drinkr
//
//  Created by Dustin Allen on 10/6/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import CoreLocation
import IQKeyboardManagerSwift
import IQDropDownTextField

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
    
    var drinkArray = [""]
    var priceArray = [""]
    var drinkString = ""
    var priceString = ""
    
    var ref:FIRDatabaseReference!
    var user: FIRUser!
    
    var latGained:Double = Double()
    var longGained:Double = Double()
    
    var deleteDrinkIndexPath: NSIndexPath? = nil
    
    let alertController = UIAlertController()
    
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        drinkForCheckInBool.addTarget(self, action: #selector(VenueInformationViewController.switchIsChanged2(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        drinkForLikeBool.addTarget(self, action: #selector(VenueInformationViewController.switchIsChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
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
        
        startTime?.isOptionalDropDown = false
        startTime?.dropDownMode = IQDropDownMode.TimePicker
        startTime?.setDate(NSDate(), animated: true)
        startTime?.delegate = self
        
        endTime?.isOptionalDropDown = false
        endTime?.dropDownMode = IQDropDownMode.TimePicker
        endTime?.setDate(NSDate(), animated: true)
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
        
        ref = FIRDatabase.database().reference()
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        ref.child("venues").child(userID!).observeEventType(FIRDataEventType.Value, withBlock: { snapshot in
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
            if let base64String = snapshot.value!["image"] as? String {
                AppState.sharedInstance.myProfile = CommonUtils.sharedUtils.decodeImage(base64String)
                self.header?.image = AppState.sharedInstance.myProfile ?? UIImage(named: "BarPlaceholder.jpg")
            }
        })
        
        if addressField.text == "" {
            addressField.text = "Enter Your Address Information"
        }
        if detailsField.text == "" {
            detailsField.text = "Deals Until"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IQDropDownTextFieldDelegate Methods
    func textField(textField: IQDropDownTextField, didSelectDate date: NSDate?) {
        print(date)
    }
    
    func sliderControlChangedValue(sliderControl:SlidingControl) {
        print("Selected index \(sliderControl.selectedSegmentIndex) UIControlEventValueChanged")
        print("Selected Day - \(NSDate().daysOfTheWeek().AllDays[sliderControl.selectedSegmentIndex])")
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
        detailsField.userInteractionEnabled = true
        telephoneField.userInteractionEnabled = true
        editIcon.hidden = true
        checkIcon.hidden = false
    }
    
    @IBAction func checkButton(sender: AnyObject) {
        
        addressField.userInteractionEnabled = false
        detailsField.userInteractionEnabled = false
        telephoneField.userInteractionEnabled = false
        editIcon.hidden = false
        checkIcon.hidden = true
        
        ref = FIRDatabase.database().reference()
        user = FIRAuth.auth()?.currentUser
        
        forwardGeocoding(addressField.text!)
        
        self.ref.child("venues").child(user!.uid).updateChildValues(["venueAddress": self.addressField.text!, "venueOpenUntil": self.detailsField.text!, "venueTelephone": self.telephoneField.text!, "lat": self.latGained, "long": self.longGained])
        
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
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController){
        self.dismissViewControllerAnimated(true, completion: nil);
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
            if let field = alertController.textFields![0] as? UITextField {
                self.drinkString = field.text! as String
                print(self.drinkString)
                self.drinkArray.append("\(self.drinkString)")
                self.drinkTable.reloadData()
            } else {
                print("No Special")
            }
            if let field1 = alertController.textFields![1] as? UITextField {
                self.priceString = field1.text! as String
                print(self.priceString)
                self.priceArray.append("\(self.priceString)")
                self.drinkTable.reloadData()
            } else {
                print("No Specials")
            }
            self.ref = FIRDatabase.database().reference()
            let userID = FIRAuth.auth()?.currentUser?.uid
            
            self.ref.child("venues").child(userID!).child("drinkSpecials").childByAutoId().updateChildValues(["Drink" : self.drinkString, "Price": self.priceString])
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
        var count:Int?
        
        if tableView == self.drinkTable {
            count = drinkArray.count
        }
        return count!
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell:UITableViewCell?
        
        if tableView == self.drinkTable {
            cell = drinkTable.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
            let drinks = drinkArray[indexPath.row] as String
            let prices = priceArray[indexPath.row] as String
            let str = "\(drinks)     \(prices)"
            cell!.textLabel!.textAlignment = .Center
            cell!.textLabel!.text = "\(str)"
        }
        return cell!
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            deleteDrinkIndexPath = indexPath
            let drinkToDelete = drinkArray[indexPath.row]
            let priceToDelete = priceArray[indexPath.row]
            confirmDelete(drinkToDelete)
            confirmDelete(priceToDelete)
        }
    }
    
    func confirmDelete(drink: String) {
        let alert = UIAlertController(title: "Delete Drink", message: "Are you sure you want to permanently delete \(drink)?", preferredStyle: .ActionSheet)
        
        let DeleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: handleDeleteDrink)
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
            
            drinkArray.removeAtIndex(indexPath.row)
            priceArray.removeAtIndex(indexPath.row)
            
            // Note that indexPath is wrapped in an array:  [indexPath]
            drinkTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            
            deleteDrinkIndexPath = nil
            
            drinkTable.endUpdates()
        }
    }
    
    func cancelDeleteDrink(alertAction: UIAlertAction!) {
        deleteDrinkIndexPath = nil
    }
}