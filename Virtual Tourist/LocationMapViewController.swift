//
//  LocationDetailViewController.swift
//  Virtual Tourist
//
//  Created by Adhemar Soria Galvarro on 04/04/16.
//  Copyright © 2016 Adhemar Soria Galvarro. All rights reserved.
//
import UIKit
import MapKit
import CoreLocation
import CoreData

class LocationMapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var editButton: UINavigationItem!
    
    var pins = [Pin]()
    var selectedPin: Pin? = nil
    
    // Is Editing mode
    var editingPins: Bool = false
    
    // Core Data
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func fetchAllPins() -> [Pin] {
        
        // Create request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Execute request
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch {
            print("error in fetch")
            return [Pin]()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(LocationMapViewController.handleLongPress(_:)))
        
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
        
        // Map view delegate
        mapView.delegate = self
        deleteLabel.hidden = true
        
        addSavedPinsToMap()
    }
    
    // Find all the saved pins and show it on the mapView
    func addSavedPinsToMap() {
        
        pins = fetchAllPins()
        
        for pin in pins {
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = pin.coordinate
            mapView.addAnnotation(annotation)
        }
    }
    
    @IBAction func editClicked(sender: UIBarButtonItem) {
        
        if editingPins == false {
            editingPins = true
            deleteLabel.hidden = false
                // Show the 'Done' button and flag the editingPins to true
            navigationItem.rightBarButtonItem?.title = "Done"
            
        }
            
        else if editingPins {
            navigationItem.rightBarButtonItem?.title = "Edit"
            editingPins = false
            deleteLabel.hidden = true
        }
        
    }
    
    // Reference: http://stackoverflow.com/questions/5182082/mkmapview-drop-a-pin-on-touch
    func handleLongPress(getstureRecognizer : UIGestureRecognizer){
        
        // If it's in editing mode, do nothing
        if (editingPins) {
            return
        } else {
            
            if getstureRecognizer.state != .Began { return }
            
            let touchPoint = getstureRecognizer.locationInView(self.mapView)
            let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchMapCoordinate
            
            let newPin = Pin(lat: annotation.coordinate.latitude, long: annotation.coordinate.longitude, context: sharedContext)
  
            CoreDataStackManager.sharedInstance().saveContext()
            pins.append(newPin)
            mapView.addAnnotation(annotation)
            
            //If it's new pint Download the photos
            FlickrClient.sharedInstance().downloadPhotosForPin(newPin) { (success, error) in print("downloadPhotosForPin is success:\(success) - error:\(error)") }
            
        }
    }
    
    // Mark: - When a pin is tapped, it will transition to the Phone Album View Controller
    
    // Start by updating the view for the annotation. This is necessary because it allows you to intercept taps on the annotation's view (the pin).
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.canShowCallout = false
        
        return annotationView
    }
    
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        guard let annotation = view.annotation else { /* no annotation */ return }

        
        selectedPin = nil
        
        for pin in pins {
            
            if annotation.coordinate.latitude == pin.latitude && annotation.coordinate.longitude == pin.longitude {
                
                selectedPin = pin
                
                if editingPins {
                    print("Deleting pin - verify core data is deleting as well")
                    sharedContext.deleteObject(selectedPin!)
                    
                    // Deleting selected pin on map
                    self.mapView.removeAnnotation(annotation)
                    
                    // Save the chanages to core data
                    CoreDataStackManager.sharedInstance().saveContext()
                    
                } else {
                    // Move to the Phone Album View Controller
                    self.performSegueWithIdentifier("toMapView", sender: nil)
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "toMapView") {
            let viewController = segue.destinationViewController as! MapViewController
            viewController.pin = selectedPin
        }
    }
    
 } // End of LocationMapViewController.swift


