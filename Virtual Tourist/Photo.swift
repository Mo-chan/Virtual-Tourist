//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Mohammad Awwad on 9/10/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import Foundation
import CoreData
import UIKit
@objc(Photo)

class Photo : NSManagedObject {

    struct Keys {
        static let Id = "id"
        static let Path = "path"
        static let Location = "location"
    }
    
    @NSManaged var id: String
    @NSManaged var path: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        path = dictionary[Keys.Path] as! String
        id = dictionary[Keys.Id] as! String
    }

    var pinImage: UIImage? {
        
        get {
                return Flickr.Caches.imagecache.imageWithIdentifier(path)
        }
        
        set {
            self.sharedContext.performBlockAndWait({
                Flickr.Caches.imagecache.storeImage(newValue, withIdentifier: self.path)
            })
        }
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
}