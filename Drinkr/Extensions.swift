//
//  Extensions.swift
//  Drinkr
//
//  Created by Dustin Allen on 10/5/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import Foundation
import UIKit


extension UIApplication {
    class func tryURL(urls: [String]) {
        let application = UIApplication.sharedApplication()
        for url in urls {
            if application.canOpenURL(NSURL(string: url)!) {
                application.openURL(NSURL(string: url)!)
                return
            }
        }
    }
}

extension UIColor {
    convenience init(rgb: UInt) {
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension UIImage {
    func imgToBase64() -> String {
        let imageData:NSData = UIImageJPEGRepresentation(self, 0.8)!
        let base64String = imageData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        print(base64String)
        
        return base64String
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}


let weekdays = [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday"
]

extension NSDate {
    
    func daysOfTheWeek() -> (DaysWithToday:Array<String>,AllDays:Array<String>)
    {
        let calendar: NSCalendar = NSCalendar.currentCalendar()
        let components: NSDateComponents = calendar.components(.Weekday, fromDate: self)
        var DaysWithToday:Array<String> = []
        var AllDays:Array<String> = []
        
        //Days.append("Today")
        AllDays.append(self.dayOfTheWeek())
        DaysWithToday.append("Today")
        
        AllDays.appendContentsOf(weekdays.suffixFrom(components.weekday))
        DaysWithToday.appendContentsOf(weekdays.suffixFrom(components.weekday))
        
        if components.weekday > 0 {
            AllDays.appendContentsOf(weekdays.prefixUpTo(components.weekday - 1))
            DaysWithToday.appendContentsOf(weekdays.prefixUpTo(components.weekday - 1))
        }
        
        print("daysOfTheWeek Days : \(DaysWithToday)")
        print("All Week Days : \(AllDays)")
        
        return (DaysWithToday,AllDays)
        //return Days
        //return weekdays[components.weekday - 1]
    }
    func dayOfTheWeek() -> String
    {
        let calendar: NSCalendar = NSCalendar.currentCalendar()
        let components: NSDateComponents = calendar.components(.Weekday, fromDate: self)
        return weekdays[components.weekday - 1]
    }
}

extension String {
    func toDouble() -> Double? {
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }
}


extension NSDateFormatter {
    convenience init(dateFormat: String) {
        self.init()
        self.dateFormat =  dateFormat
    }
}

extension NSDate {
    struct Formatter {
        //user_upload_time : Format (YYYY-MM-DD HH:MM:SS) 2016-08-02 11:22:11 (24 hours)    //"yyyy-MM-dd, HH:mm:ss"
        static let custom = NSDateFormatter(dateFormat: "yyyy-MM-dd HH:mm:ss")
        static let customUTC = NSDateFormatter(dateFormat: "yyyy-MM-dd HH:mm:ss")
    }
    var strDateInLocal: String {
        //formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)  // you can set GMT time
        //formatter.timeZone = NSTimeZone.localTimeZone()        // or as local time
        return Formatter.custom.stringFromDate(self)
    }
    var strDateInUTC: String {
        Formatter.customUTC.timeZone = NSTimeZone(name: "UTC")
        return Formatter.customUTC.stringFromDate(self)
    }
    func formattedWith(format:String? = "dd MMM yyyy")-> String {
        let formatter = NSDateFormatter()
        //formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)  // you can set GMT time
        formatter.timeZone = NSTimeZone.localTimeZone()        // or as local time
        formatter.dateFormat = format
        return formatter.stringFromDate(self)
    }
}

extension String {
    
    
    var asDateLocal: NSDate? {
        return NSDate.Formatter.custom.dateFromString(self)
    }
    var asDateUTC: NSDate? {
        NSDate.Formatter.customUTC.timeZone = NSTimeZone(name: "UTC")
        return NSDate.Formatter.customUTC.dateFromString(self)
    }
    func asDateFormatted(with dateFormat: String) -> NSDate? {
        return NSDateFormatter(dateFormat: dateFormat).dateFromString(self)
    }
    var asDateFromMiliseconds: NSDate? {
        if let interval = Double(self) {
            return NSDate.init(timeIntervalSince1970: interval)
        }
        return nil
    }
    
    func convertToDictionary() -> [String:AnyObject]? {
        if let data = self.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: [.AllowFragments]) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
}

extension Double {
    var asDateFromMiliseconds: NSDate {
        return NSDate.init(timeIntervalSince1970: self)
    }
}

extension Dictionary {
    subscript(i:Int) -> (key:Key,value:Value) {
        get {
            return self[startIndex.advancedBy(i)]
        }
    }
}

extension NSDate {
    func isCheckinWithinSameDay() -> Bool {
        return (self.formattedWith("DD") == NSDate().formattedWith("DD")) ? true : false
    }
}

