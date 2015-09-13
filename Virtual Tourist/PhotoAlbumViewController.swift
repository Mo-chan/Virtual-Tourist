//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Mohammad Awwad on 9/10/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import Foundation

class PhotoAlbumViewController : UIViewController, UICollectionViewDelegate,  MKMapViewDelegate, UICollectionViewDataSource ,NSFetchedResultsControllerDelegate{
    
    @IBOutlet weak var newCollectionButton: UIButton!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    var latitude: Double!
    var longitude: Double!
    var pin : Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Ok", style: .Plain, target: self, action: "closePage")
        
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        
        fetchedResultsController.performFetch(nil)
        fetchedResultsController.delegate = self

        let coor = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude), span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        
        mapView.setRegion(coor, animated: true)
        
        let geoLoc = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        var annotation = MKPointAnnotation()
        annotation.coordinate = geoLoc
        mapView.addAnnotation(annotation)
       
    }
    
    func closePage() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        var error : NSError?
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
     func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        println(sectionInfo.numberOfObjects)
        return sectionInfo.numberOfObjects
    }
    
     func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCell", forIndexPath: indexPath) as! PhotoAlbumViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        configureCell(cell, photo: photo)
        
        return cell
    }
    
     func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath)
    {
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        sharedContext.deleteObject(photo)
        CoreDataStackManager.sharedInstance().saveContext()
        
    }
    
    @IBAction func newCollection(sender: AnyObject) {
        
        newCollectionButton.enabled = false
        sharedContext.deletedObjects
        Flickr.sharedInstance().flickrSearch(self.latitude, longitude: self.longitude){ (success, Photos ,errorString) in
            if success {
                if let Photos = Photos {
                    for photo in Photos {
                        
                        let dictionary: [String : AnyObject] = [
                            Photo.Keys.Id : photo["id"]!,
                            Photo.Keys.Path : photo["url_m"]! ,
                        ]
                        
                        let pic = Photo(dictionary: dictionary, context: self.sharedContext)
                        pic.pin = self.pin
                        
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                    self.newCollectionButton.enabled = true
                    self.photoCollectionView?.reloadData()
                }
            } else {
                
            }
        }
        
    }
    
    func configureCell(cell: PhotoAlbumViewCell , photo: Photo){
        var pinImage = UIImage(named: "posterPlaceHoldr")
        
        if photo.pinImage != nil {
           pinImage = photo.pinImage
        
        } else {
            
            let task = Flickr.sharedInstance().taskForImage(photo.path){ data, error in
                if let error = error {
                    println("Photo download error: \(error)")
                }
                
                if let data = data {
                    let image = UIImage(data: data)
                    photo.pinImage = image

                    dispatch_async(dispatch_get_main_queue()) {
                        cell.imageView!.image = image
                    }
                }
                
            }
        
        }
        
        cell.imageView?.image = pinImage
    }
    
}