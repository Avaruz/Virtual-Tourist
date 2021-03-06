//
//  Virtual Tourist
//
//  Created by Adhemar Soria Galvarro on 28/3/16.
//  Copyright © 2016 Adhemar Soria Galvarro. All rights reserved.
//

import UIKit
import CoreData

class BaseViewController: UIViewController {
    
    let pinFinishedDownloadingNotification = "pinFinishedDownloadNotification"
    
    func shakeScreen() {
        let anim = CAKeyframeAnimation( keyPath:"transform" )
        anim.values = [
            NSValue( CATransform3D:CATransform3DMakeTranslation(-5, 0, 0 ) ),
            NSValue( CATransform3D:CATransform3DMakeTranslation( 5, 0, 0 ) )
        ]
        anim.autoreverses = true
        anim.repeatCount = 2
        anim.duration = 7/100
        
        view.layer.addAnimation( anim, forKey:nil )
    }
    
    // We only have two subclasses and both need to download a new set, so making it available here
    func getPhotosForPin(pin: Pin, completionHandler: (success: Bool, errorString: String?) -> Void) {
        if (pin.isDownloading) {
            return
        }
        pin.isDownloading = true
        FlickrClient.sharedInstance.getPhotosForPin(pin) { (success, errorString) in
            pin.isDownloading = false
            
            CoreDataStackManager.sharedInstance().saveContext()
            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: self.pinFinishedDownloadingNotification, object: self))
            completionHandler(success: success, errorString: errorString)
        }
    }
    
    func showAlert(title: String, message: String, buttonText: String = "Ok", shake: Bool = false) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: buttonText, style: UIAlertActionStyle.Default, handler: nil))
        if shake {
            self.shakeScreen()
        }
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //MARK: Core Data
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
}
