//
//  SampleData.swift
//  ClueList
//
//  Created by Ryan Rose on 10/12/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

class DataHelper {
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }
    
    func seedDataStore() {
        seedToDos()
        //seedFactoids()
    }
    
    //add some default ToDos to start
    func seedToDos() {
        let todos = [
            (text: "feed the cat", clue: "cat", completed: false),
            (text: "pick up milk", clue: "milk", completed: true),
            (text: "buy eggs", clue: "eggs", completed: false),
            (text: "take out the trash", clue: "trash", completed: false)
        ]
        
        for todo in todos {
            let newToDo = NSEntityDescription.insertNewObjectForEntityForName(ToDoItem.entityName, inManagedObjectContext: sharedContext) as! ToDoItem
            newToDo.id = NSUUID().UUIDString
            newToDo.text = todo.text
            newToDo.clue = todo.clue
            newToDo.completed = todo.completed
            newToDo.priority = ToDoPriority.Low.rawValue
            newToDo.created = NSDate()
            newToDo.metaData.internalOrder = ToDoMetaData.maxInternalOrder(sharedContext)+1
            newToDo.metaData.updateSectionIdentifier()
            let dictionary: [String: AnyObject] = ["terms": todo.text]
            NetworkClient.sharedInstance().taskForGETMethod("factoids/search", params: dictionary, completionHandler: { (result) in
                if let error = result.error {
                    print(error)
                    //completionHandler(error)
                    return
                }
  
                for (_, subJson) in result["results"] {
                    if let title = subJson["text"].string {
                        let dictionary: [String: AnyObject?] = ["text": title]
                        _ = Factoid(dictionary: dictionary, todo: newToDo, context: self.sharedContext)
                        
                        do {
                            try self.sharedContext.save()
                        } catch _ {
                        }
                    }
                }
                // success
                //completionHandler(nil)
            })
        }
        
        do {
            try sharedContext.save()
        } catch _ {
        }
    }
    
    func seedFactoids() {
        // Grab ToDos
        let toDoFetchRequest = NSFetchRequest(entityName: "ToDoItem")
        let allToDos = (try! sharedContext.executeFetchRequest(toDoFetchRequest)) as! [ToDoItem]
        
        let cat = allToDos.filter({ (s: ToDoItem) -> Bool in
            return s.clue == "cat"
        }).first
        
        let cow = allToDos.filter({ (s: ToDoItem) -> Bool in
            return s.clue == "milk"
        }).first
        
        let egg = allToDos.filter({ (s: ToDoItem) -> Bool in
            return s.clue == "eggs"
        }).first
        
        let factoids = [
            (text: "Cats have over 20 muscles that control their ears.", todo: cat!),
            (text: "The average cow in the U.S. produces about 21,000 lbs. of milk per year.", todo: cow!),
            (text: "Americans consume 76.5 billion eggs per year.", todo: egg!),
            (text: "A group of cats is called a clowder.", todo: cat!),
            (text: "Cats sleep 70% of their lives.", todo: cat!)
        ]
     
        for item in factoids {
            let newItem = NSEntityDescription.insertNewObjectForEntityForName("Factoid", inManagedObjectContext: sharedContext) as! Factoid
            newItem.text = item.text
            newItem.todo = item.todo
        }
        
        do {
            try sharedContext.save()
        } catch _ {
        }
    }
    
    func printAllToDos() {
        let toDoFetchRequest = NSFetchRequest(entityName: "ToDoItem")
        let primarySortDescriptor = NSSortDescriptor(key: "created", ascending: true)
        
        toDoFetchRequest.sortDescriptors = [primarySortDescriptor]
        
        let allToDos = (try! sharedContext.executeFetchRequest(toDoFetchRequest)) as! [ToDoItem]
        
        for todo in allToDos {
            print("ToDo: \(todo.text)\nClue: \(todo.clue) \n-------\n", terminator: "")
            for item in todo.factoids {
                print("> \(item.text)\n", terminator: "")
            }
            print("-------\n", terminator: "")
        }
    }
}