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
    class var entityName: String {
        return "ToDoItem"
    }
    
    let DEFAULT_PRIORITY = 1
    
    // current selected random factoid displayed for this ToDoItem
    var factoid: String?
    
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
    
    // The timestamp when the ToDoItem is due
    @NSManaged var deadline: NSDate
    
    @NSManaged var metaData: ToDoMetaData
    
    //convenience method that returns whether or not an item is overdue
    var isOverdue: Bool {
        return (NSDate().compare(self.deadline) == NSComparisonResult.OrderedDescending) // deadline is earlier than current date
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        //each todo has a mandatory relation with a meta data object, which is created upon insert
        metaData = NSEntityDescription.insertNewObjectForEntityForName(ToDoMetaData.entityName, inManagedObjectContext: managedObjectContext!) as! ToDoMetaData
    }
    
    // remove any scheduled notifications for this ToDoItem when deleted
    override func prepareForDeletion() {
        super.prepareForDeletion()
        print("remove scheduled notifications")
        for notification in UIApplication.sharedApplication().scheduledLocalNotifications! { // loop through notifications...
            if (notification.userInfo!["UUID"] as! String == self.id) { // ...and cancel the notification that corresponds to this TodoItem instance (matched by UUID)
                UIApplication.sharedApplication().cancelLocalNotification(notification) // there should be a maximum of one match on UUID
                break
            }
        }
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
        //set created timestamp to current date/time
        created = NSDate()
        if let priority = dictionary["priority"] as? Int {
            self.priority = selectedPriority(priority).rawValue
        } else {
            self.priority = selectedPriority(DEFAULT_PRIORITY).rawValue
        }
        //set the order for the table row
        metaData.internalOrder = ToDoMetaData.maxInternalOrder(context)+1
        metaData.updateSectionIdentifier()
    }
    
    func selectedPriority(priority: Int) -> ToDoPriority {
        switch priority {
        case 0:  return .Low
        case 1:  return .Medium
        case 2:  return .High
        default: return .Medium
        }
    }
    
    func getRandomFactoid() -> String? {
        //return the currently selected factoid if available
        if let item = factoid {
            return item
        }
        //select a random factoid from our saved array
        if factoids.count > 0 {
            let randomIndex = Int(arc4random_uniform(UInt32(factoids.count)))
            
            //decode the Base64 encoded string from the API
            factoid = factoids[randomIndex].text.htmlDecoded()
            
            return factoid!
        }
        return nil
    }
    
    func refreshFactoid() -> String? {
        var newFactoid: String
        if let item = factoid {
            //reset value so we get a new random factoid
            factoid = nil
            newFactoid = getRandomFactoid()!
            //if we randomly selected the same factoid and there is more than one to choose, choose another
            if factoids.count > 1 && newFactoid == item {
                factoid = nil
                //iterate through factoids, exiting loop once we find a different factoid
                for f in factoids {
                    if (f != item) {
                        factoid = f.text.htmlDecoded()

                        return factoid
                    }
                }
            }
        } else {
            //nothing previously selected, choose a random factoid and select it
            newFactoid = getRandomFactoid()!
        }

        return newFactoid
    }
}
