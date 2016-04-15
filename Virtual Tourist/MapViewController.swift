//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Stella Su on 2/7/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var pin: Pin? = nil
    
    // Flag for deleting pictures
    var isDeleting = false
    
    var editingFlag: Bool = false
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var multiUseButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    // Array of IndexPath - keeping track of index of selected cells
    var selectedIndexofCollectionViewCells = [NSIndexPath]()
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // Mark: - Fetched Results Controller
    
    // Lazily computed property pointing to the Photos entity objects, sorted by title, predicated on the pin.
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        // Create fetch request for photos which match the sent Pin.
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        // Limit the fetch request to just those photos related to the Pin.
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)
        
        // Sort the fetch request by title, ascending.
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        // Create fetched results controller with the new fetch request.
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        multiUseButton.hidden = false
        noImagesLabel.hidden = true
        
        mapView.delegate = self
        
        // Load the map
        loadMapView()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Perform the fetch
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("\(error)")
        }
        
        // Set the delegate to this view controller
        fetchedResultsController.delegate = self
        
        // Subscirbe to notification so photos can be reloaded - catches the notification from FlickrConvenient
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MapViewController.photoReload(_:)), name: "downloadPhotoImage.done", object: nil)
    }
    
    // Inserting dispatch_async to ensure the closure always run in the main thread
    func photoReload(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {
            self.collectionView.reloadData()
            
            // If no photos remaining, show the 'New Collection' button
            let numberRemaining = FlickrClient.sharedInstance().numberOfPhotoDownloaded
            print("numberRemaining is from photoReload \(numberRemaining)")
            if numberRemaining <= 0 {
                self.multiUseButton.hidden = false
            }
        })
    }
    
    private func reFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("reFetch - \(error)")
        }
    }
    
    
    // Note: "new' images might overlap with previous collections of images
    @IBAction func multiUseButtonTapped(sender: UIButton) {
        
        // Hiding the button once it's tapped, because I want to finish either deleting or reloading first
        multiUseButton.hidden = true
        
        // If deleting flag is true, delete the photo
        if isDeleting == true
        {
            // Removing the photo that user selected one by one
            for indexPath in selectedIndexofCollectionViewCells {
                
                // Get photo associated with the indexPath.
                let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
                
                print("Deleting this -- \(photo)")
                
                // Remove the photo
                sharedContext.deleteObject(photo)
                
            }
            
            // Empty the array of indexPath after deletion
            selectedIndexofCollectionViewCells.removeAll()
            
            // Save the chanages to core data
            CoreDataStackManager.sharedInstance().saveContext()
            
            // Update cells
            reFetch()
            collectionView.reloadData()
            
            // Change the button to say 'New Collection' after deletion
            multiUseButton.setTitle("New Collection", forState: UIControlState.Normal)
            multiUseButton.hidden = false
            
            isDeleting = false
            
            // Else "New Collection" button is tapped
        } else {
            
            // 1. Empty the photo album from the previous set
            for photo in fetchedResultsController.fetchedObjects as! [Photo]{
                sharedContext.deleteObject(photo)
            }
            
            // 2. Save the chanages to core data
            CoreDataStackManager.sharedInstance().saveContext()
            
            // 3. Download a new set of photos with the current pin
            FlickrClient.sharedInstance().downloadPhotosForPin(pin!, completionHandler: {
                success, error in
                
                if success {
                    dispatch_async(dispatch_get_main_queue(), {
                        CoreDataStackManager.sharedInstance().saveContext()
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        print("error downloading a new set of photos")
                        self.multiUseButton.hidden = false
                    })
                }
                // Update cells
                dispatch_async(dispatch_get_main_queue(), {
                    self.reFetch()
                    self.collectionView.reloadData()
                })
                
            })
        }
    }
    
    // Load map view for the current pin
    // Reference: http://studyswift.blogspot.com/2014/09/mkpointannotation-put-pin-on-map.html
    func loadMapView() {
        
        let point = MKPointAnnotation()
        
        point.coordinate = CLLocationCoordinate2DMake((pin?.latitude)!, (pin?.longitude)!)
        mapView.addAnnotation(point)
        mapView.centerCoordinate = point.coordinate
        
        // Select the annotation so the title can be shown
        mapView.selectAnnotation(point, animated: true)
        
    }
    
    // Return the number of photos from fetchedResultsController
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        
        let sectionInfo = self.fetchedResultsController.sections![section]
        print("Number of photos returned from fetchedResultsController #\(sectionInfo.numberOfObjects)")
        // If numberOfObjects is not zero, hide the noImagesLabel
        noImagesLabel.hidden = sectionInfo.numberOfObjects != 0
        
        return sectionInfo.numberOfObjects
    }
    
    @IBAction func editButtonTapped(sender: AnyObject) {
        
        if editingFlag == false {
            editingFlag = true
            navigationItem.rightBarButtonItem?.title = "Done"
            multiUseButton.setTitle("Tap photos to delete", forState: UIControlState.Normal)
        }
            
        else if editingFlag {
            navigationItem.rightBarButtonItem?.title = "Edit"
            editingFlag = false
            multiUseButton.hidden = false
        }
        
    }
    // Remove photos from an album when user select a cell or multiple cells
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        
        if editingFlag == false{
            
            let myImageViewPage: ImageScrollView = self.storyboard?.instantiateViewControllerWithIdentifier("ImageScrollView") as! ImageScrollView
            let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            
            // Pass the selected image
            myImageViewPage.selectedImage = photo.url!
            
            self.navigationController?.pushViewController(myImageViewPage, animated: true)
        }
            
        else if (editingFlag) {
            
            // Configure the UI of the collection item
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FlickrCell
            
            // When user deselect the cell, remove it from the selectedIndexofCollectionViewCells array
            if let index = selectedIndexofCollectionViewCells.indexOf(indexPath){
                selectedIndexofCollectionViewCells.removeAtIndex(index)
                cell.deleteButton.hidden = true
            } else {
                // Else, add it to the selectedIndexofCollectionViewCells array
                selectedIndexofCollectionViewCells.append(indexPath)
                cell.deleteButton.hidden = false
                multiUseButton.setTitle("New Collection", forState: UIControlState.Normal)
            }
            
            // If the selectedIndexofCollectionViewCells array is not empty, show the 'Delete # photo(s)' button
            if selectedIndexofCollectionViewCells.count > 0 {
                
                print("Delete array has \(selectedIndexofCollectionViewCells.count) photo(s).")
                if selectedIndexofCollectionViewCells.count == 1{
                    multiUseButton.setTitle("Delete \(selectedIndexofCollectionViewCells.count) photo", forState: UIControlState.Normal)
                } else {
                    multiUseButton.setTitle("Delete \(selectedIndexofCollectionViewCells.count) photos", forState: UIControlState.Normal)
                }
                isDeleting = true
            } else{
                multiUseButton.setTitle("New Collection", forState: UIControlState.Normal)
                isDeleting = false
            }
            
        } // End of else if editingFlag = true
        
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCell", forIndexPath: indexPath) as! FlickrCell
        cell.photoView.image = UIImage(named: "noimage")
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if (photo.url != nil)
        {
            cell.photoView.image = photo.image
            cell.activityIndicator.stopAnimating()
        }
        
        
        cell.deleteButton.hidden = true
        cell.deleteButton.layer.setValue(indexPath, forKey: "indexPath")
        
        // Trigger the action 'deletePhoto' when the button is tapped
        cell.deleteButton.addTarget(self, action: #selector(MapViewController.deletePhoto(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        return cell
    }
    
    func deletePhoto(sender: UIButton){
        
        // I want to know if the cell is selected giving the indexPath
        let indexOfTheItem = sender.layer.valueForKey("indexPath") as! NSIndexPath
        
        // Get the photo associated with the indexPath
        let photo = fetchedResultsController.objectAtIndexPath(indexOfTheItem) as! Photo
        print("Delete cell selected from 'deletePhoto' is \(photo)")
        
        // When user deselected it, remove it from the selectedIndexofCollectionViewCells array
        if let index = selectedIndexofCollectionViewCells.indexOf(indexOfTheItem){
            selectedIndexofCollectionViewCells.removeAtIndex(index)
        }
        
        // Remove the photo
        sharedContext.deleteObject(photo)
        
        // Save to core data
        CoreDataStackManager.sharedInstance().saveContext()
        
        // Update selected cell
        reFetch()
        collectionView.reloadData()
    }
    
    
    
} // The end

