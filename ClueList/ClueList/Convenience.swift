//
//  Convenience.swift
//  ClueList
//
//  Created by Ryan Rose on 11/11/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation
import UIKit
import CoreData

extension NetworkClient {
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }
    
    func getFactoids(todo: ToDoItem, completionHandler: (reload: Bool!, error: NSError?) -> Void) {
        if todo.factoids.count > 0 {
            completionHandler(reload: false, error: nil)
        } else {
            print("Requesting factoids for: \(todo.text)")
            let dictionary: [String: AnyObject] = ["terms": todo.text]
            self.taskForGETMethod("factoids/search", params: dictionary, completionHandler: { (result) in
                if let error = result.error {
                    print("getFactoids result error: \(error)")
                    completionHandler(reload: false, error: error)
                    return
                }
                
                //find the clue and save to ToDo (clue used for highlighting)
                if let clue = result["clue"].string {
                    todo.clue = clue
                    // save the clue, if we have no factoids this identifies a successful API request was returned if a refresh is executed
                    CoreDataManager.sharedInstance.saveContext()
                }
                
                //loop through factoid results and save with associated ToDoItem
                for (_, subJson) in result["items"] {
                    if let title = subJson["text"].string {
                        let dictionary: [String: AnyObject?] = ["text": title]
                        _ = Factoid(dictionary: dictionary, todo: todo, context: self.sharedContext)
                        //persist factoids to db
                        CoreDataManager.sharedInstance.saveContext()
                    }
                }
                // success
                completionHandler(reload: true, error: nil)
            })
        }
    }
}