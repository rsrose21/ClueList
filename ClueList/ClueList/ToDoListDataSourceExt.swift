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
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return toDoListController.sections.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toDoListController.sections[section].numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item = toDoListController.toDoAtIndexPath(indexPath)
        let cell = configureCell(indexPath, item: item!)
        
        return cell
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        if sourceIndexPath == destinationIndexPath {
            return
        }
        
        fetchControllerDelegate.ignoreNextUpdates = true // Don't let fetched results controller affect table view
        let toDo = toDoListController.toDoAtIndexPath(sourceIndexPath)! // Trust that we will get a toDo back
        
        if sourceIndexPath.section != destinationIndexPath.section {
            
            let sectionInfo = toDoListController.sections[destinationIndexPath.section]
            toDo.metaData.setSection(sectionInfo.section)
            
            // Update cell
            NSOperationQueue.mainQueue().addOperationWithBlock { // Table view is in inconsistent state, gotta wait
                self.configureCell(destinationIndexPath, item: toDo)
            }
        }
        
        updateInternalOrderForToDo(toDo, sourceIndexPath: sourceIndexPath, destinationIndexPath: destinationIndexPath)
        
        // Save
        try! toDo.managedObjectContext!.save()
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if hideSectionHeaders {
            return ""
        } else {
            return toDoListController.sections[section].name
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        //hide sections if currently editing a item
        if hideSectionHeaders {
            return 0.0
        } else {
            return Constants.UIDimensions.TABLE_SECTION_HEIGHT
        }
    }
    
    // UITableView Section Header customization: http://www.elicere.com/mobile/swift-blog-2-uitableview-section-header-color/
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        //recast your view as a UITableViewHeaderFooterView
        if let header = view as? UITableViewHeaderFooterView {
            header.contentView.backgroundColor = UIColor.whiteColor() //make the background color white
            header.textLabel!.textColor = UIColor(hexString: Constants.UIColors.SECTION_HEADER)
            header.textLabel!.text = header.textLabel!.text!.uppercaseString
            header.textLabel!.font = UIFont.boldSystemFontOfSize(18)
            header.textLabel!.frame = header.frame
        }
    }
    
    //disable table view swipe to delete since we have a custom swipe action already
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        //only show delete button if in editing mode
        if (self.tableView.editing) {
            return .Delete
        }
        return .None
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier(segueIdentifier, sender: indexPath)
    }
    
    // MARK: TableView Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let toDo = toDoListController.toDoAtIndexPath(indexPath) {
            toDo.completed = !toDo.completed.boolValue
            toDo.metaData.updateSectionIdentifier()
            CoreDataManager.sharedInstance.saveContext()
        }
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        // the delete icon was pressed, display the action sheet for delete confirmation
        let toDo = toDoListController.toDoAtIndexPath(indexPath)
        confirmDeleteForToDo(toDo!)
        
        return []
    }
    
    func confirmDeleteForToDo(item: ToDoItem) {
        let alertController = UIAlertController(title: nil, message: "Are you sure you want to permanently delete \(item.text)?", preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            // user pressed cancel
            self.tableView.reloadData()
        }
        alertController.addAction(cancelAction)
        
        let destroyAction = UIAlertAction(title: "Delete", style: .Destructive) { (action) in
            self.removeToDo(item)
        }
        alertController.addAction(destroyAction)
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }
    }
    
    // MARK: - add, delete, toggle methods
    
    func addToDo() {
        // hide table section headers before adding and animating table cells
        hideSectionHeaders = true
        
        let dictionary: [String: AnyObject?] = ["text": Constants.Messages.PLACEHOLDER_TEXT]
        let toDoItem = ToDoItem(dictionary: dictionary, context: sharedContext)
        toDoItem.editing = true
        try! toDoItem.managedObjectContext!.save()
        // we added a new cell, refresh the table
        tableView.reloadData()
        
        // enter edit mode
        var editCell: ToDoCellTableViewCell
        let visibleCells = tableView.visibleCells as! [ToDoCellTableViewCell]
        for cell in visibleCells {
            // find the toDoItem and initiate it's delegate
            if (cell.toDoItem === toDoItem) {
                editCell = cell
                editCell.editLabelOnly = true
                // initiate cellDidBeginEditing
                editCell.editLabel.becomeFirstResponder()
                break
            }
        }
    }
    
    func removeToDo(toDoItem: ToDoItem) {
        // loop over the visible cells to animate delete
        let visibleCells = tableView.visibleCells as! [ToDoCellTableViewCell]
        let lastView = visibleCells[visibleCells.count - 1] as ToDoCellTableViewCell
        var delay = 0.0
        var startAnimating = false
        for i in 0..<visibleCells.count {
            let cell = visibleCells[i]
            if startAnimating {
                UIView.animateWithDuration(0.3, delay: delay, options: .CurveEaseInOut,
                    animations: {() in
                        cell.frame = CGRectOffset(cell.frame, 0.0,
                            -cell.frame.size.height)},
                    completion: {(finished: Bool) in
                        if (cell == lastView) {
                            //we reached the end of the table cells, reload the tableview
                            self.tableView.reloadData()
                        }
                    }
                )
                delay += 0.03
            }
            //remove the cell
            if cell.toDoItem === toDoItem {
                startAnimating = true
                cell.hidden = true
                // remove any notifications for this item if it's completed and was assigned a deadline
                if toDoItem.deadline != nil {
                    ToDoList.sharedInstance.removeItem(toDoItem)
                }
                self.sharedContext.deleteObject(toDoItem)
                CoreDataManager.sharedInstance.saveContext()
            }
        }
    }

    // MARK: - Private methods
    
    private func updateInternalOrderForToDo(toDo: ToDoItem, sourceIndexPath: NSIndexPath, destinationIndexPath: NSIndexPath) {
        
        // Now update internal order to reflect new position
        
        // First get all toDos, in sorted order
        var sortedToDos = toDoListController.fetchedToDos()
        sortedToDos = sortedToDos.filter() {$0 != toDo} // Remove current toDo
        
        // Insert toDo at new place in array
        var sortedIndex = destinationIndexPath.row
        for sectionIndex in 0..<destinationIndexPath.section {
            sortedIndex += toDoListController.sections[sectionIndex].numberOfObjects
            if sectionIndex == sourceIndexPath.section {
                sortedIndex -= 1 // Remember, controller still thinks this toDo is in the old section
            }
        }
        sortedToDos.insert(toDo, atIndex: sortedIndex)
        
        // Regenerate internal order for all toDos
        for (index, toDo) in sortedToDos.enumerate() {
            toDo.metaData.internalOrder = sortedToDos.count-index
        }
    }

    
}