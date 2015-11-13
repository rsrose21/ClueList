//
//  ToDoMetaData.swift
//  ClueList
//
//  Created by Ryan Rose on 10/25/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation
import CoreData

enum ToDoPriority: Int {
    case None = 0
    case Low = 1
    case Medium = 2
    case High = 3
}

@objc(ToDoMetaData)
class ToDoMetaData: NSManagedObject {
    
    //Orders the todos within a section and is updated when the user reorders the list
    @NSManaged var internalOrder: NSNumber
    
    //Used to divide the todos into sections
    //NSFetchedResultsController requires that the sections are sorted in the same order as the rows so they can be fetched in batches
    @NSManaged var sectionIdentifier: NSString
    
    @NSManaged var toDo: ToDoItem
    
    @NSManaged var listConfiguration: ToDoListConfiguration
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        listConfiguration = ToDoListConfiguration.defaultConfiguration(managedObjectContext!)
    }
    
    func updateSectionIdentifier() {
        sectionIdentifier = sectionForCurrentState().rawValue
    }
    
    //Every time a property affecting a todo's displayed section changes (such as priority or completed status), the section identifier must be updated.
    func setSection(section: ToDoSection) {
        switch section {
        case .ToDo:
            toDo.completed = false
        case .Done:
            toDo.completed = true
        case .HighPriority:
            toDo.completed = false
            toDo.priority = ToDoPriority.High.rawValue
        case .MediumPriority:
            toDo.completed = false
            toDo.priority = ToDoPriority.Medium.rawValue
        case .LowPriority:
            toDo.completed = false
            toDo.priority = ToDoPriority.Low.rawValue
        case .NoPriority:
            toDo.completed = false
            toDo.priority = ToDoPriority.None.rawValue
        }
        sectionIdentifier = section.rawValue
    }
    
    //Manually trigger an update when doing drag 'n' drop or marking a todo as completed
    private func sectionForCurrentState() -> ToDoSection {
        if toDo.completed.boolValue {
            return .Done
        } else if listConfiguration.listMode == ToDoListMode.Simple {
            return .ToDo
        } else {
            switch ToDoPriority(rawValue: toDo.priority.integerValue)! {
            case .None:     return .NoPriority
            case .Low:      return .LowPriority
            case .Medium:   return .MediumPriority
            case .High:     return .HighPriority
            }
        }
    }
}

//
// MARK: Class functions
//

extension ToDoMetaData {
    class var entityName: String {
        return "ToDoMetaData"
    }
    
    class func maxInternalOrder(context: NSManagedObjectContext) -> Int {
        
        let maxInternalOrderExpression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "internalOrder")])
        
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = "maxInternalOrder"
        expressionDescription.expression = maxInternalOrderExpression
        expressionDescription.expressionResultType = .Integer32AttributeType
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.propertiesToFetch = [expressionDescription]
        fetchRequest.resultType = .DictionaryResultType
        
        guard let results = try? context.executeFetchRequest(fetchRequest) else {
            return 0
        }
        
        if let toDoMetaData = results.first as? ToDoMetaData {
            return toDoMetaData.valueForKey("maxInternalOrder") as! Int
        }
        
        return 0
    }
}