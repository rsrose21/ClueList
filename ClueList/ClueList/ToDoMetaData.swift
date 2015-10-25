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
    case Low = 1
    case Medium = 2
    case High = 3
}

@objc(ToDoMetaData)
class ToDoMetaData: NSManagedObject {
    
    @NSManaged var internalOrder: NSNumber
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
        }
        sectionIdentifier = section.rawValue
    }
    
    private func sectionForCurrentState() -> ToDoSection {
        if toDo.completed.boolValue {
            return .Done
        } else if listConfiguration.listMode == ToDoListMode.Simple {
            return .ToDo
        } else {
            switch ToDoPriority(rawValue: toDo.priority.integerValue)! {
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