//
//  ToDoList.swift
//  ClueList
//
//  Created by Ryan Rose on 11/11/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class ToDoList {
    // return a singleton: http://stackoverflow.com/questions/24024549/dispatch-once-singleton-model-in-swift/24147830#24147830
    class var sharedInstance : ToDoList {
        struct Static {
            static let instance : ToDoList = ToDoList()
        }
        return Static.instance
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }
    
    func allItems() -> [ToDoItem] {
        let toDoFetchRequest = NSFetchRequest(entityName: ToDoItem.entityName)
        let primarySortDescriptor = NSSortDescriptor(key: "created", ascending: true)
        
        toDoFetchRequest.sortDescriptors = [primarySortDescriptor]
        
        let allToDos = (try! sharedContext.executeFetchRequest(toDoFetchRequest)) as! [ToDoItem]
        
        return allToDos
    }
    
    func addItem(item: ToDoItem) {
        // persist a representation of this todo item in NSUserDefaults

        
        // create a corresponding local notification
        
    }
    
    func removeItem(item: ToDoItem) {
        
    }
}