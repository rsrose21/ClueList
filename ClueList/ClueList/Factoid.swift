//
//  Factoid.swift
//  ClueList
//
//  Created by Ryan Rose on 10/18/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation
import UIKit
import CoreData

//make Factoid available to Objective-C code
@objc(Factoid)

//make Factoid a subclass of NSManagedObject
class Factoid: NSManagedObject {
    
    @NSManaged var id: String
    
    // A text description of this item.
    @NSManaged var text: String
    
    //manage relationship in Core Data
    @NSManaged var todo: ToDoItem?
    
    // Include this standard Core Data init method.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // Returns a ToDoItem initialized with the given text and default completed value.
    init(dictionary: [String : AnyObject?], todo: ToDoItem, context: NSManagedObjectContext) {
        
        // Get the entity associated with the "Factoid" type.  This is an object that contains
        // the information from the .xcdatamodeld file.
        let entity =  NSEntityDescription.entityForName("Factoid", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        //set properties
        //generate uid in swift: http://stackoverflow.com/questions/24428250/generate-uuid-in-xcode-swift
        id = NSUUID().UUIDString
        
        text = dictionary["text"] as! String

        print(text)
        self.todo = todo
    }
    
}