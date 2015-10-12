//
//  ToDoItem.swift
//  ClueList
//
//  Created by Ryan Rose on 10/12/15.
//  Copyright © 2015 GE. All rights reserved.
//

import UIKit

class ToDoItem: NSObject {
    
    var id: String
    
    // A text description of this item.
    var text: String
    
    // A Boolean value that determines the completed state of this item.
    var completed: Bool
    
    // The subject extracted from the description text used to find a related factoid
    var subject: String
    
    // A short factoid displayed in place of text description based on keyword
    var factoid: String
    
    // The timestamp when the ToDoItem was created
    var created: NSDate
    
    // Returns a ToDoItem initialized with the given text and default completed value.
    init(dictionary: [String : AnyObject]) {
        //generate uid in swift: http://stackoverflow.com/questions/24428250/generate-uuid-in-xcode-swift
        id = NSUUID().UUIDString
        
        text = dictionary["text"] as! String
        completed = false
        if let subject = dictionary["subject"] as? String {
            self.subject = subject
        } else {
            self.subject = ""
        }
        if let factoid = dictionary["factoid"] as? String {
            self.factoid = factoid
        } else {
            self.factoid = ""
        }
        created = NSDate()
    }
}
