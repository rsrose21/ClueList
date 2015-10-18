//
//  SampleData.swift
//  ClueList
//
//  Created by Ryan Rose on 10/12/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation
import CoreData

class DataHelper {
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }
    
    //add some default ToDos to start
    func seedToDos() {
        let todos = [
            (text: "feed the cat", clue: "cat", completed: false),
            (text: "pick up milk", clue: "milk", completed: true),
            (text: "buy eggs", clue: "eggs", completed: false)
        ]
        
        for todo in todos {
            let newToDo = NSEntityDescription.insertNewObjectForEntityForName("ToDoItem", inManagedObjectContext: sharedContext) as! ToDoItem
            newToDo.text = todo.text
            newToDo.clue = todo.clue
            newToDo.completed = todo.completed
        }
        
        do {
            try sharedContext.save()
        } catch _ {
        }
        /*
        var params: [String: AnyObject?] = ["text": "feed the cat", "clue": "cat", "factoid": "Cats have over 20 muscles that control their ears."]
        sampleData.append(ToDoItem(dictionary: params))
        
        params = ["text": "pick up milk", "clue": "milk", "factoid": "The average cow in the U.S. produces about 21,000 lbs. of milk per year", "completed": true]
        sampleData.append(ToDoItem(dictionary: params))
        
        params = ["text": "buy eggs", "clue": "eggs", "factoid": "Americans consume 76.5 billion eggs per year"]
        sampleData.append(ToDoItem(dictionary: params))
        */
    }
    
    func printAllToDos() {
        let toDoFetchRequest = NSFetchRequest(entityName: "ToDoItem")
        let primarySortDescriptor = NSSortDescriptor(key: "created", ascending: true)
        
        toDoFetchRequest.sortDescriptors = [primarySortDescriptor]
        
        let allToDos = (try! sharedContext.executeFetchRequest(toDoFetchRequest)) as! [ToDoItem]
        
        for todo in allToDos {
            print("ToDo: \(todo.text)\nClue: \(todo.clue) \n-------\n", terminator: "")
        }
    }
}