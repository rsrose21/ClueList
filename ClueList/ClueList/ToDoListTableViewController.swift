//
//  ToDoListTableViewController.swift
//  ClueList
//
//  Created by Ryan Rose on 10/12/15.
//  Copyright © 2015 GE. All rights reserved.
//

import UIKit
import CoreData

class ToDoListTableViewController: UITableViewController, TableViewCellDelegate {

    var toDoItems = [ToDoItem]()
    let cellIdentifier = "ToDoCell"
    
    // Mark: CoreData properties
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }
    
    lazy var fetchControllerDelegate: FetchControllerDelegate = {
        
        let delegate = FetchControllerDelegate(tableView: self.tableView)
        delegate.onUpdate = {
            (indexPath: NSIndexPath?, object: AnyObject) in
            self.configureCell(indexPath!, item: object as! ToDoItem)
        }
        
        return delegate
    }()
    
    lazy var toDoListController: ToDoListController = {
        
        let controller = ToDoListController(managedObjectContext: self.sharedContext)
        controller.delegate = self.fetchControllerDelegate
        
        return controller
    }()
    
    lazy var fetchResultsController: NSFetchedResultsController = {
        
        let controller = self.toDoListController.toDosController
        
        return controller
    }()
    
    var itemToDelete: ToDoItem?
    

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // display an Edit button in the navigation bar for this view controller.
        navigationItem.leftBarButtonItem = self.editButtonItem()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "toDoItemAdded")
        
        configureTableView()
    }
    
    //use the auto layout constraints to determine each cell's height
    //http://www.raywenderlich.com/87975/dynamic-table-view-cell-height-ios-8-swift
    func configureTableView() {
        tableView.allowsSelection = false
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 160.0
        
        //differentiate background when cell is dragged
        //tableView.backgroundColor = UIColor.blackColor()
        
        tableView.registerClass(ToDoCellTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //this can happen if the app font size was changed from phone settings
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contentSizeCategoryChanged:", name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }
    
    // This function will be called when the Dynamic Type user setting changes (from the system Settings app)
    func contentSizeCategoryChanged(notification: NSNotification) {
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return toDoListController.sections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toDoListController.sections[section].numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item = toDoListController.toDoAtIndexPath(indexPath)
        let cell = configureCell(indexPath, item: item!)
        
        return cell
    }
    
    private func configureCell(indexPath: NSIndexPath, item: ToDoItem) -> ToDoCellTableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ToDoCellTableViewCell
        // Configure the cell for this indexPath
        cell.updateFonts()
        
        cell.checkbox.selected = item.completed
        cell.checkbox.tag = indexPath.row
        cell.checkbox.addTarget(self, action: "toggleToDoItem:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Make sure the constraints have been added to this cell, since it may have just been created from scratch
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        
        cell.delegate = self
        cell.toDoItem = item
        
        return cell
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
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

    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        return toDoListController.sections[section].name
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
    
    //disable table view swipe to delete since we have a custom swipe action already
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        //only show delete button if in editing mode
        if (self.tableView.editing) {
            return .Delete
        }
        return .None
    }
    
    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func cellDidBeginEditing(editingCell: ToDoCellTableViewCell) {
        let editingOffset = 0.0 - editingCell.frame.origin.y as CGFloat
        let visibleCells = tableView.visibleCells as! [ToDoCellTableViewCell]
        for cell in visibleCells {
            UIView.animateWithDuration(0.3, animations: {() in
                cell.transform = CGAffineTransformMakeTranslation(0, editingOffset)
                if cell !== editingCell {
                    cell.alpha = 0.3
                }
            })
        }
    }
    
    func cellDidEndEditing(editCell: ToDoCellTableViewCell) {
        let visibleCells = tableView.visibleCells as! [ToDoCellTableViewCell]
        for cell: ToDoCellTableViewCell in visibleCells {
            UIView.animateWithDuration(0.3, animations: {() in
                cell.transform = CGAffineTransformIdentity
                if cell !== editCell {
                    cell.alpha = 1.0
                }
            })
        }
        if editCell.toDoItem!.text == "" {
            toDoItemRemoved(editCell.toDoItem!)
        } else {
            editCell.titleLabel.hidden = false
            editCell.bodyLabel.hidden = false
            editCell.editLabel.hidden = true
            CoreDataManager.sharedInstance.saveContext()
        }
    }
    
    // MARK: - add, delete, edit methods
    
    func toDoItemAdded() {
        let dictionary: [String: AnyObject?] = ["text": "", "created": NSDate(), "completed": false]
        let toDoItem = ToDoItem(dictionary: dictionary, context: sharedContext)
        CoreDataManager.sharedInstance.saveContext()
        tableView.reloadData()
        // enter edit mode
        var editCell: ToDoCellTableViewCell
        let visibleCells = tableView.visibleCells as! [ToDoCellTableViewCell]
        for cell in visibleCells {
            if (cell.toDoItem === toDoItem) {
                editCell = cell
                editCell.titleLabel.hidden = true
                editCell.bodyLabel.hidden = true
                editCell.editLabel.hidden = false
                editCell.editLabel.becomeFirstResponder()
                break
            }
        }
    }
    
    func toDoItemRemoved(toDoItem: ToDoItem) {
        let index = (toDoItems as NSArray).indexOfObject(toDoItem)
        if index == NSNotFound { return }
        
        toDoItemDeleted(index)
    }
    
    //Custom table cell delete: http://www.raywenderlich.com/77975/making-a-gesture-driven-to-do-list-app-like-clear-in-swift-part-2
    func toDoItemDeleted(index: NSInteger) {
        // could removeAtIndex in the loop but keep it here for when indexOfObject works
        let toDoItem = toDoItems.removeAtIndex(index)
        
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
                            self.tableView.reloadData()
                        }
                    }
                )
                delay += 0.03
            }
            if cell.toDoItem === toDoItem {
                startAnimating = true
                cell.hidden = true
            }
        }
        
        // use the UITableView to animate the removal of this row
        tableView.beginUpdates()
        let indexPathForRow = NSIndexPath(forRow: index, inSection: 0)
        tableView.deleteRowsAtIndexPaths([indexPathForRow], withRowAnimation: .Fade)
        tableView.endUpdates()
    }
    
    func toggleToDoItem(sender: UIButton) {
        //get hold of selected ToDoItem from the UIButton tag
        let indexPath = NSIndexPath(forRow: sender.tag, inSection: 0)
        if let item = toDoListController.toDoAtIndexPath(indexPath) {
            item.completed = !item.completed.boolValue
            item.metaData.updateSectionIdentifier()
            try! item.managedObjectContext!.save()
            
            //indicate to user this item has been updated
            let indexPathRow = NSIndexPath(forRow: sender.tag, inSection: 0)
            let cell = tableView.cellForRowAtIndexPath(indexPathRow) as! ToDoCellTableViewCell
            cell.toggleCompleted(item.completed)
        }
    }
    
    // MARK: - UIScrollViewDelegate methods
    
    // a cell that is rendered as a placeholder to indicate where a new item is added
    let placeHolderCell = ToDoCellTableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "ToDoCell")
    // indicates the state of this behavior
    var pullDownInProgress = false
    // table cell row heights are based on the cell's content so we use a static value here since we have no content
    let rowHeight = 50.0 as CGFloat;
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        // this behavior starts when a user pulls down while at the top of the table
        pullDownInProgress = scrollView.contentOffset.y <= 0.0
        placeHolderCell.backgroundColor = UIColor.whiteColor()
        if pullDownInProgress {
            // add the placeholder
            tableView.insertSubview(placeHolderCell, atIndex: 0)
        }
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let scrollViewContentOffsetY = scrollView.contentOffset.y
        
        if pullDownInProgress && scrollView.contentOffset.y <= 0.0 {
            // maintain the location of the placeholder
            placeHolderCell.frame = CGRect(x: 0, y: -rowHeight,
                width: tableView.frame.size.width, height: rowHeight)
            
            placeHolderCell.titleLabel.text = -scrollViewContentOffsetY > rowHeight ?
                "Release to add item" : "Pull to add item"
            placeHolderCell.resetConstraints()
            placeHolderCell.alpha = min(1.0, -scrollViewContentOffsetY / rowHeight)
        } else {
            pullDownInProgress = false
        }
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // check whether the user pulled down far enough
        if pullDownInProgress && -scrollView.contentOffset.y > rowHeight {
            // add a new item
            toDoItemAdded()
        }
        pullDownInProgress = false
        placeHolderCell.removeFromSuperview()
    }
    
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
