//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Mohammad Awwad on 9/9/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var pressRecognizer: UILongPressGestureRecognizer? = nil
    var pins : [Pin]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        
        fetchedResultsController.performFetch(nil)
        fetchedResultsController.delegate = self
        
        pressRecognizer = UILongPressGestureRecognizer(target: self, action: "addPinToMap:")
        pressRecognizer?.numberOfTapsRequired = 1

        
        let lat = NSUserDefaults.standardUserDefaults().doubleForKey("latitude")
        let long = NSUserDefaults.standardUserDefaults().doubleForKey("longitude")
        let latD = NSUserDefaults.standardUserDefaults().doubleForKey("latitudeDelta")
        let longD = NSUserDefaults.standardUserDefaults().doubleForKey("longitudeDelta")
        let coor = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: long), span: MKCoordinateSpan(latitudeDelta: latD, longitudeDelta: longD))
        
        mapView.setRegion(coor, animated: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        view.addGestureRecognizer(pressRecognizer!)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        view.removeGestureRecognizer(pressRecognizer!)
    }
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        NSUserDefaults.standardUserDefaults().setDouble(self.mapView.region.center.latitude, forKey: "latitude")
        NSUserDefaults.standardUserDefaults().setDouble(self.mapView.region.center.longitude, forKey: "longitude")
        NSUserDefaults.standardUserDefaults().setDouble(self.mapView.region.span.latitudeDelta, forKey: "latitudeDelta")
        NSUserDefaults.standardUserDefaults().setDouble(self.mapView.region.span.longitudeDelta, forKey: "longitudeDelta")
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        var error : NSError?
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let results = self.sharedContext.executeFetchRequest(fetchRequest, error: &error)
        
        if error != nil {
            println("could not fetch tourist locations: \(error?.localizedDescription)")
        } else {
            var annotations = [MKPointAnnotation]()
            let pin = results as! [Pin]
            self.pins = pin
            for dictionary in pin {
                let lat = CLLocationDegrees(dictionary.latitude as Double)
                let long = CLLocationDegrees(dictionary.longitude as Double)
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                
                
                var annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                
                annotations.append(annotation)
            
            }
            self.mapView.addAnnotations(annotations)
        }
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.enabled = true
            pinView!.draggable = true
            pinView!.pinColor = .Red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    

    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        for pin in pins {
            if pin.latitude == view.annotation.coordinate.latitude && pin.longitude == view.annotation.coordinate.longitude {
                println(pin)
                let controller = storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbum") as! PhotoAlbumViewController
                controller.pin = pin
                controller.latitude = pin.latitude
                controller.longitude = pin.longitude
                
                let nav = UINavigationController()
                nav.pushViewController(controller, animated: false)
                self.mapView.deselectAnnotation(view.annotation!, animated: true)
                dispatch_async(dispatch_get_main_queue(), {
                    self.presentViewController(nav, animated: true, completion: nil)
                })
            }
        
        }
    }

    
    func addPinToMap(gestureRecognizer: UIGestureRecognizer)
    {
        if (gestureRecognizer.state) != UIGestureRecognizerState.Ended {
            return
        }
        else {
            let touchpoint = gestureRecognizer.locationInView(mapView)
            let touchCoordinate = mapView.convertPoint(touchpoint, toCoordinateFromView: mapView)
            let geoLoc = CLLocationCoordinate2D(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude)
            
            let dictionary: [String : AnyObject] = [
                Pin.Keys.Latitude : touchCoordinate.latitude,
                Pin.Keys.Longitude : touchCoordinate.longitude,
            ]
            
            let PinToBeAdded = Pin(dictionary: dictionary, context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
            self.pins.append(PinToBeAdded)
            var annotation = MKPointAnnotation()
            annotation.coordinate = geoLoc
            mapView.addAnnotation(annotation)
            
            Flickr.sharedInstance().flickrSearch(touchCoordinate.latitude, longitude: touchCoordinate.longitude){ (success, Photos ,errorString) in
                if success {
                    if let Photos = Photos {
                        for photo in Photos {
                        
                            let dictionary: [String : AnyObject] = [
                                Photo.Keys.Id : photo["id"]!,
                                Photo.Keys.Path : photo["url_m"]! ,
                            ]
                            
                            let pic = Photo(dictionary: dictionary, context: self.sharedContext)
                            pic.pin = PinToBeAdded
                            
                            CoreDataStackManager.sharedInstance().saveContext()
                        }
                    
                    }
                } else {
                    
                }
            }
        }
    }

}