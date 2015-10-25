//
//  ToDoItem.swift
//  ClueList
//
//  Created by Ryan Rose on 10/12/15.
//  Copyright © 2015 GE. All rights reserved.
//

import UIKit
import CoreData

//make ToDoItem available to Objective-C code
@objc(ToDoItem)

//make ToDoItem a subclass of NSManagedObject
class ToDoItem: NSManagedObject {
    
    @NSManaged var id: String
    
    // A text description of this item.
    @NSManaged var text: String
    
    // A Boolean value that determines the completed state of this item.
    @NSManaged var completed: Bool
    
    // The subject extracted from the description text used to find a related factoid
    @NSManaged var clue: String
    
    // A short factoid displayed in place of text description based on keyword
    @NSManaged var factoids: [Factoid]
    
    // The timestamp when the ToDoItem was created
    @NSManaged var created: NSDate
    
    // The user assigned priority - used for tableview section sorting
    @NSManaged var priority: NSNumber
    
    @NSManaged var metaData: ToDoMetaData
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        metaData = NSEntityDescription.insertNewObjectForEntityForName(ToDoMetaData.entityName, inManagedObjectContext: managedObjectContext!) as! ToDoMetaData
    }
    
    // Include this standard Core Data init method.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // Returns a ToDoItem initialized with the given text and default completed value.
    init(dictionary: [String : AnyObject?], context: NSManagedObjectContext) {
        
        // Get the entity associated with the "Pin" type.  This is an object that contains
        // the information from the VirtualTourist.xcdatamodeld file.
        let entity =  NSEntityDescription.entityForName("ToDoItem", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Pin class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // After the Core Data work has been taken care of we can init the properties from the
        // dictionary. This works in the same way that it did before we started on Core Data
        
        //generate uid in swift: http://stackoverflow.com/questions/24428250/generate-uuid-in-xcode-swift
        id = NSUUID().UUIDString
        
        text = dictionary["text"] as! String
        if let completed = dictionary["completed"] as? Bool {
            self.completed = completed
        } else {
            self.completed = false
        }
        if let clue = dictionary["clue"] as? String {
            self.clue = clue
        } else {
            self.clue = ""
        }
        created = NSDate()
    }
}
