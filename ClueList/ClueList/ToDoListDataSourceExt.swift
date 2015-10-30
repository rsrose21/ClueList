//
//  ToDoListDataSourceExt.swift
//  ClueList
//
//  Created by Ryan Rose on 10/18/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation
import UIKit
import CoreData

extension ToDoListTableViewController {
    
    // MARK: TableView Delegate
    /*
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let todo = fetchResultsController.objectAtIndexPath(indexPath) as! ToDoItem
            confirmDeleteForToDo(todo)
        }
    }
    */
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        //the delete icon was pressed, display the action sheet for delete confirmation
        let toDo = toDoListController.toDoAtIndexPath(indexPath)
        confirmDeleteForToDo(toDo!)
        
        return []
    }
    
    func confirmDeleteForToDo(item: ToDoItem) {
        self.itemToDelete = item
        let alertController = UIAlertController(title: nil, message: "Are you sure you want to permanently delete \(item.text)?", preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            self.itemToDelete = nil
        }
        alertController.addAction(cancelAction)
        
        let destroyAction = UIAlertAction(title: "Delete", style: .Destructive) { (action) in
            self.deleteToDo()
        }
        alertController.addAction(destroyAction)
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }
    }
    
    func deleteToDo() {
        if let verseToDelete = self.itemToDelete {
            self.sharedContext.deleteObject(verseToDelete)
            do {
                try self.sharedContext.save()
            } catch {
            }
            
            self.itemToDelete = nil
        }
    }
    
}