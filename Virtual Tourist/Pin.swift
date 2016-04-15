//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Adhemar Soria Galvarro on 28/3/16.
//  Copyright © 2016 Adhemar Soria Galvarro. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class Pin: NSManagedObject, MKAnnotation {

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var numPages: NSNumber?
    @NSManaged var photos:[Photo]
    
    var isDownloading = false
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2DMake(latitude, longitude)
        }
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
    }
}
