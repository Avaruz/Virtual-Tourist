//
//  LocationDetailViewController.swift
//  Virtual Tourist
//
//  Created by Adhemar Soria Galvarro on 28/3/16.
//  Copyright © 2016 Adhemar Soria Galvarro. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationDetailViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {

    var pin:Pin!
    
    // store updated indexes
    var selectedIndexes   = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths : [NSIndexPath]!
    var updatedIndexPaths : [NSIndexPath]!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    override func viewWillAppear(animated: Bool) {
        noImagesLabel.hidden = true
        collectionView.hidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.addAnnotation(pin)
        mapView.setCenterCoordinate(pin.coordinate, animated: true)
        
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error = error1
            print(error)
        }
        
        if error != nil  || fetchedResultsController.fetchedObjects?.count == 0 {
            // fail gracfully - download new collection
            loadNewCollectionSet()
        }
        
        //disable new collection button if we are already downloading
        if pin.isDownloading {
            newCollectionButton.enabled = false
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LocationDetailViewController.pinFinishedDownload), name: pinFinishedDownloadingNotification, object: nil)
    }

    
    func loadNewCollectionSet() {        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        self.newCollectionButton.enabled = false
        print(pin.photos.count)
    
        getPhotosForPin(pin) { (success, errorString) in
            if success {
                dispatch_async(dispatch_get_main_queue(), {
                    CoreDataStackManager.sharedInstance().saveContext()
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    print("error downloading a new set of photos")
                    self.newCollectionButton.enabled = true
                })
            }
            // Update cells
            dispatch_async(dispatch_get_main_queue(), {
                self.reFetch()
                self.collectionView.reloadData()
            })

        }
    }
    
    func pinFinishedDownload(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {
        if self.pin.isDownloading == true {
            return
        }
        self.newCollectionButton.enabled = true
        
        if let objects = self.fetchedResultsController.fetchedObjects {
            if objects.count == 0 {
                self.collectionView.hidden = true
                self.noImagesLabel.hidden = false
                self.newCollectionButton.enabled = false
            }
            }
        })
    }

    // MARK: Collection View
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCell", forIndexPath: indexPath) as! FlickrCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        cell.imageView.image = UIImage(named: "no-image")
        
        if photo.imagePath != nil {
            cell.activityIndicator.stopAnimating()
            cell.imageView.image = photo.image
        }
        
        return cell
    }
    
 
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        let alert = UIAlertController(title: "Delete Photo", message: "Do you want to remove this photo?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action: UIAlertAction) in
            collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction) in
            collectionView.deselectItemAtIndexPath(indexPath, animated: true)
            self.sharedContext.deleteObject(photo)
            CoreDataStackManager.sharedInstance().saveContext()
        }))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func newCollectionButtonTouch(sender: AnyObject) {
        loadNewCollectionSet()
    }
    
    //MARK: Core Data
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

    
    private func reFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("reFetch - \(error)")
        }
    }
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths  = [NSIndexPath]()
        updatedIndexPaths  = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
        case .Update:
            updatedIndexPaths.append(indexPath!)
        case .Delete:
            deletedIndexPaths.append(indexPath!)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView.performBatchUpdates({
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
        }, completion: nil)
    }
}
