//
//  MyAnnotation.swift
//  Drinkr
//
//  Created by iParth on 10/18/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class MyAnnotation: MKPointAnnotation {
    var pinImage: UIImage
    
    init(pinImage: UIImage) {
        self.pinImage = pinImage
        super.init()
    }
}