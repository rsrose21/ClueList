//
//  ToDoListTableViewController.swift
//  ClueList
//
//  Created by Ryan Rose on 10/12/15.
//  Copyright © 2015 GE. All rights reserved.
//

import UIKit
import CoreData

class ToDoListTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TableViewCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    let cellIdentifier = "ToDoCell"
    
    let segueIdentifier = "editToDoItem"
    
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
    
    private var tagId = 0
    
    private var editingToDo = false
    
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
        tableView.dataSource = self
        tableView.delegate = self
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
    
    // MARK: - Actions
    
    @IBAction func viewSimple(sender: AnyObject) {
        ToDoListConfiguration.defaultConfiguration(sharedContext).listMode = .Simple
    }
    
    @IBAction func viewPrioritized(sender: AnyObject) {
        ToDoListConfiguration.defaultConfiguration(sharedContext).listMode = .Prioritized
    }

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
    
    private func getFactoids(todo: ToDoItem, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        if todo.factoids.count > 0 {
            completionHandler(result: todo, error: nil)
        } else {
            print("Requesting factoids for: \(todo.text)")
            let dictionary: [String: AnyObject] = ["terms": todo.text]
            NetworkClient.sharedInstance().taskForGETMethod("factoids", params: dictionary, completionHandler: { (result) in
                if let error = result.error {
                    print(error)
                    completionHandler(result: nil, error: error)
                    return
                }
                
                for (_, subJson) in result["results"] {
                    if let title = subJson["text"].string {
                        let dictionary: [String: AnyObject?] = ["text": title]
                        _ = Factoid(dictionary: dictionary, todo: todo, context: self.sharedContext)
                        
                        do {
                            try self.sharedContext.save()
                        } catch _ {
                        }
                    }
                }
                // success
                completionHandler(result: todo, error: nil)
            })
        }
    }
    
    private func configureCell(indexPath: NSIndexPath, item: ToDoItem) -> ToDoCellTableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ToDoCellTableViewCell
        // Configure the cell for this indexPath
        cell.updateFonts()
        //configure the cell checkbox
        cell.checkbox.delegate = cell
        cell.checkbox.selected = item.completed
        cell.checkbox.toDoItem = item
        //use the UIButton label to store the id for this ToDo
        cell.checkbox.titleLabel!.text = item.id
        cell.checkbox.addTarget(self, action: "toggleToDoItem:", forControlEvents: UIControlEvents.TouchUpInside)
        
        cell.accessoryType = UITableViewCellAccessoryType.DetailButton
        getFactoids(item, completionHandler: { (result, error) in
            if let e = error {
                print(e)
            }
            // Make sure the constraints have been added to this cell, since it may have just been created from scratch
            cell.setNeedsUpdateConstraints()
            cell.updateConstraintsIfNeeded()
        })
        
        // Make sure the constraints have been added to this cell, since it may have just been created from scratch
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        
        cell.delegate = self
        cell.toDoItem = item
        
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

    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        return toDoListController.sections[section].name
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        //hide sections if currently editing a item
        if editingToDo {
            return 0.0
        } else {
            return 50.0
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
        return true
    }

    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier(segueIdentifier, sender: indexPath)
    }
    
    func cellDidBeginEditing(editingCell: ToDoCellTableViewCell) {
        editingToDo = true
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
            //toDoItemRemoved(editCell.toDoItem!)
        } else {
            editCell.titleLabel.hidden = false
            editCell.bodyLabel.hidden = false
            editCell.editLabel.hidden = true
            CoreDataManager.sharedInstance.saveContext()
        }
        editingToDo = false
        tableView.reloadData()
    }
    
    // MARK: - add, delete, edit methods
    
    func toDoItemAdded() {
        
        editingToDo = true
        let dictionary: [String: AnyObject?] = ["text": "Add To Do"]
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
    /*
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
    */
    func toggleToDoItem(sender: UIButton) {
        //get the selected ToDoItem by it's id from the UIButton title
        let id = sender.titleLabel!.text
        if let item = toDoListController.toDoById(id!) {
            //toggle the completed status
            item.completed = !item.completed.boolValue
            item.metaData.updateSectionIdentifier()
            try! item.managedObjectContext!.save()
        }
    }
    
    // MARK: - UIScrollViewDelegate methods
    
    // a cell that is rendered as a placeholder to indicate where a new item is added
    let placeHolderCell = ToDoCellTableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "ToDoCell")
    // indicates the state of this behavior
    var pullDownInProgress = false
    // table cell row heights are based on the cell's content so we use a static value here since we have no content
    let rowHeight = 50.0 as CGFloat;
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        // this behavior starts when a user pulls down while at the top of the table
        pullDownInProgress = scrollView.contentOffset.y <= 0.0
        placeHolderCell.backgroundColor = UIColor.whiteColor()
        if pullDownInProgress {
            // add the placeholder
            tableView.insertSubview(placeHolderCell, atIndex: 0)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
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
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
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
    

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdentifier {
            //get the selected ToDo by the passed index path
            if let object = toDoListController.toDoAtIndexPath(sender as! NSIndexPath) {
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! EditToDoViewController
                //set selected ToDo for our view controller
                controller.todo = object
            }
        }
    }

}
