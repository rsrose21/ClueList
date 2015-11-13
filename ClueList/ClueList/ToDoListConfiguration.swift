//
//  ToDoListConfiguration.swift
//  ClueList
//
//  Created by Ryan Rose on 10/25/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation
import CoreData

enum ToDoListMode: Int {
    case Simple = 1
    case Prioritized = 2
}

@objc(ToDoListConfiguration)
class ToDoListConfiguration: NSManagedObject {
    class var entityName: String {
        return "ToDoListConfiguration"
    }
    
    @NSManaged private var listModeValue: NSNumber
    @NSManaged var toDoMetaData: NSSet
    
    var listMode: ToDoListMode {
        get {
            return ToDoListMode(rawValue: listModeValue.integerValue)!
        }
        set {
            listModeValue = newValue.rawValue
            for metaData in toDoMetaData.allObjects as! [ToDoMetaData] {
                metaData.updateSectionIdentifier()
            }
        }
    }
    
    var sections: [ToDoSection] {
        switch listMode {
        case .Simple:
            return [.ToDo, .Done]
        case .Prioritized:
            return [.HighPriority, .MediumPriority, .LowPriority, .NoPriority, .Done]
        }
    }
}

//
// MARK: Class functions
//

extension ToDoListConfiguration {
    class func defaultConfiguration(context: NSManagedObjectContext) -> ToDoListConfiguration {
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        let configurations = try! context.executeFetchRequest(fetchRequest)
        return configurations.first as? ToDoListConfiguration ?? NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as! ToDoListConfiguration
    }
}