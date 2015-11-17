//
//  ToDoListTableViewController.swift
//  ClueList
//
//  Created by Ryan Rose on 10/12/15.
//  Copyright © 2015 GE. All rights reserved.
//

import UIKit
import CoreData
import EventKit

class ToDoListTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TableViewCellDelegate, EditToDoViewControllerDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var simpleBtn: UIBarButtonItem!
    @IBOutlet weak var prioritizedBtn: UIBarButtonItem!
    
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
    
    var detailViewController: EditToDoViewController? = nil
    
    // keeps a reference to the active cell currently edited
    var activeCell: ToDoCellTableViewCell?
    
    private var tagId = 0
    // flag to hide tableview sections when editing a cell
    var hideSectionHeaders = false
    // flag to toggle tableview editing mode
    private var edit = false
    
    private var editBarButtonItem: UIBarButtonItem!
    private var doneBarButtonItem: UIBarButtonItem!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // configure the toolbar
        toolbar.tintColor = UIColor(hexString: Constants.UIColors.TOOLBAR_ITEM)
        if (ToDoListConfiguration.defaultConfiguration(sharedContext).listMode == .Simple) {
            simpleBtn.tintColor = UIColor(hexString: Constants.UIColors.TOOLBAR_ACTIVE)
        } else {
            prioritizedBtn.tintColor = UIColor(hexString: Constants.UIColors.TOOLBAR_ACTIVE)
        }
        // create a "Edit" and "Done" button
        editBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Edit, target: self, action: "toggleEdit")
        doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "toggleEdit")
        // display an Edit button in the navigation bar for this view controller.
        navigationItem.leftBarButtonItem = editBarButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "addToDo")
        title = "To Do"
        
        self.detailViewController?.delegate = self
        
        // Looks for single taps
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        tapGesture.delegate=self
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)

        configureTableView()
    }
    
    //use the auto layout constraints to determine each cell's height
    //http://www.raywenderlich.com/87975/dynamic-table-view-cell-height-ios-8-swift
    func configureTableView() {
        // disable cell selection since we are using custom gestures
        tableView.allowsSelection = false
        
        // Self-sizing table view cells in iOS 8 require that the rowHeight property of the table view be set to the constant UITableViewAutomaticDimension
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        
        // Self-sizing table view cells in iOS 8 are enabled when the estimatedRowHeight property of the table view is set to a non-zero value.
        // Setting the estimated row height prevents the table view from calling tableView:heightForRowAtIndexPath: for every row in the table on first load;
        // it will only be called as cells are about to scroll onscreen. This is a major performance optimization.
        tableView.estimatedRowHeight = 44.0 // set this to whatever your "average" cell height is; it doesn't need to be very accurate
        
        //differentiate background when cell is dragged
        tableView.backgroundColor = UIColor(hexString: Constants.UIColors.TABLE_BG)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(ToDoCellTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // this can happen if the app font size was changed from phone settings
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshList:", name: UIContentSizeCategoryDidChangeNotification, object: nil)
        // listen for refresh events in case ToDos become overdue
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshList", name: "TodoListShouldRefresh", object: nil)
        // monitor network state changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("networkStatusChanged:"), name: ReachabilityStatusChangedNotification, object: nil)
        Reach().monitorReachabilityChanges()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIContentSizeCategoryDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "TodoListShouldRefresh", object: nil)
    }
    
    // This function will be called when the Dynamic Type user setting changes (from the system Settings app)
    func refreshList() {
        tableView.reloadData()
    }
    
    func networkStatusChanged(notification: NSNotification) {
        let status = Reach().connectionStatus()
        switch status {
        case .Unknown, .Offline:
            let message = "You are currently offline"
            self.view.makeToast(message: message, duration: HRToastDefaultDuration, position: HRToastPositionDefault, title: Constants.Messages.NETWORK_ERROR)
        default: break
            // do nothing since we have network connectivity
        }
    }
    
    // MARK: - Actions
    
    override func setEditing(editing: Bool, animated: Bool)  {
        //toggle tableview editing and update toolbar button text
        tableView.setEditing(editing, animated: animated)
        navigationItem.leftBarButtonItem = editing ? doneBarButtonItem : editBarButtonItem
    }
    
    func toggleEdit() {
        edit = !edit
        setEditing(edit, animated: true)
        toDoListController.showsEmptySections = edit
        //hide checkbox controls when editing
        let visibleCells = tableView.visibleCells as! [ToDoCellTableViewCell]
        for cell in visibleCells {
            cell.checkbox.hidden = edit
        }
    }
    
    func toggleListMode(mode: ToDoListMode) {
        if mode == ToDoListMode.Simple {
            prioritizedBtn.tintColor = UIColor(hexString: Constants.UIColors.TOOLBAR_ITEM)
            simpleBtn.tintColor = UIColor(hexString: Constants.UIColors.TOOLBAR_ACTIVE)
        } else {
            simpleBtn.tintColor = UIColor(hexString: Constants.UIColors.TOOLBAR_ITEM)
            prioritizedBtn.tintColor = UIColor(hexString: Constants.UIColors.TOOLBAR_ACTIVE)
        }
        ToDoListConfiguration.defaultConfiguration(sharedContext).listMode = mode
        // save the selected state
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(mode.rawValue as Int, forKey: Constants.Data.APP_STATE)
    }
    
    @IBAction func viewSimple(sender: AnyObject) {
        toggleListMode(.Simple)
    }
    
    @IBAction func viewPrioritized(sender: AnyObject) {
        toggleListMode(.Prioritized)
    }
    
    // MARK: - UIGestureRecognizerDelegate methods

    // called from the tap gesture recognizer to close any active textfields and hide the keyboard
    func dismissKeyboard() {
        // causes the view (or one of its embedded text fields) to resign the first responder status.
        if activeCell != nil {
            activeCell!.editLabel.resignFirstResponder()
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        // don't override the tap action if the target is a tableview control button
        if NSStringFromClass(touch.view!.classForCoder) == "UITableViewCellEditControl"{
            return false
        }

        return true
    }
    
    // MARK: - UITextFieldDelegate delegate methods
    
    func cellDidBeginEditing(editingCell: ToDoCellTableViewCell) {
        // set a reference to the current active cell
        activeCell = editingCell
        //ToDoListConfiguration.defaultConfiguration(sharedContext).listMode = .Simple
        let editingOffset = tableView.contentOffset.y - editingCell.frame.origin.y as CGFloat
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
        activeCell = nil
        let visibleCells = tableView.visibleCells as! [ToDoCellTableViewCell]
        for cell: ToDoCellTableViewCell in visibleCells {
            UIView.animateWithDuration(0.3, animations: {() in
                cell.transform = CGAffineTransformIdentity
                if cell !== editCell {
                    cell.alpha = 1.0
                }
            })
        }
        // display table section headers again
        hideSectionHeaders = false
        if isEmpty(editCell.toDoItem!.text) {
            // if the user did not enter a ToDo then we need to delete it
            removeToDo(editCell.toDoItem!)
        } else {
            editCell.toDoItem!.editing = false
            // save any updates to the ToDo
            try! editCell.toDoItem!.managedObjectContext!.save()
            // get some factoids for this updated ToDoItem from the API
            getFactoids(editCell, completionHandler: { (success) in
                // refresh the tableview to show the activity indicator
                self.tableView.reloadData()
            })
        }
    }
    
    // method to mark/unmark a ToDo by tapping the checkbox control
    func toggleToDoItem(sender: UIButton) {
        //get the selected ToDoItem by it's id from the UIButton title
        let id = sender.titleLabel!.text
        if let item = toDoListController.toDoById(id!) {
            //toggle the completed status
            item.completed = !item.completed.boolValue
            item.metaData.updateSectionIdentifier()
            CoreDataManager.sharedInstance.saveContext()
            // remove any notifications for this item if it's completed and was assigned a deadline
            if item.completed && item.deadline != nil {
                ToDoList.sharedInstance.removeItem(item)
            }
        }
    }
    
    // MARK: - UIScrollViewDelegate methods
    
    // a cell that is rendered as a placeholder to indicate where a new item is added
    let placeHolderCell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "PlaceHolderCell")
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
            placeHolderCell.textLabel!.textAlignment = .Center
            placeHolderCell.textLabel!.text = -scrollViewContentOffsetY > rowHeight ?
                "Release to update \u{2191}" : "Pull to refresh \u{2193}"
            
            placeHolderCell.alpha = min(1.0, -scrollViewContentOffsetY / rowHeight)
        } else {
            pullDownInProgress = false
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // check whether the user pulled down far enough
        if pullDownInProgress && -scrollView.contentOffset.y > rowHeight {
            //create a loading indicator to display as each ToDo downloads new factoids
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            placeHolderCell.textLabel!.hidden = true
            placeHolderCell.addSubview(activityIndicator)
            activityIndicator.frame = placeHolderCell.bounds
            activityIndicator.startAnimating()
            // maintain pull to refresh view until all async requests complete
            self.tableView.contentInset = UIEdgeInsets(top: rowHeight, left: 0, bottom: 0, right: 0)
         
            // add a new item
            refreshFactoids({ (completed) in
                // return tableview to original position when all async requests are completed
                if completed {
                    // animate the tableView back to position
                    UIView.animateWithDuration(0.3, animations: {
                        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                        //force a reload since content length may have changed
                        self.tableView.reloadData()
                        self.placeHolderCell.removeFromSuperview()
                    })
                }
            })
        } else {
            pullDownInProgress = false
            placeHolderCell.removeFromSuperview()
        }
    }
    
    func refreshFactoids(completionHandler: (success: Bool) -> Void) {
        //loop through the visible cells and select another random factoid to display
        let visibleCells = tableView.visibleCells as! [ToDoCellTableViewCell]
        var total = 0
        var completed = false
        for cell in visibleCells {
            // request factoids for this cell and increment the counter
            getFactoids(cell, completionHandler: { (success) in
                total += 1
                // did we get a response back for each cell queried?
                completed = (total == self.tableView.visibleCells.count)
                completionHandler(success: completed)
            })
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
                controller.delegate = self
            }
        }
    }
    
    // MARK: - EditToDoViewControllerDelegate methods
    
    func didSetReminder(item: ToDoItem) {
        // add or remove local notifications for any reminders
        if item.deadline != nil {
            // create a corresponding local notification
            ToDoList.sharedInstance.addItem(item)
        } else {
            ToDoList.sharedInstance.removeItem(item)
        }
        // refresh the tableview
        tableView.reloadData()
    }
    
    // MARK: - Helper methods
    
    func configureCell(indexPath: NSIndexPath, item: ToDoItem) -> ToDoCellTableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ToDoCellTableViewCell
        // Configure the cell for this indexPath
        cell.updateFonts()
        
        if (!item.editing) {
            //configure the cell checkbox
            cell.checkbox.delegate = cell
            cell.checkbox.selected = item.completed
            cell.checkbox.toDoItem = item
            //use the UIButton label to store the id for this ToDo
            cell.checkbox.titleLabel!.text = item.id
            cell.checkbox.addTarget(self, action: "toggleToDoItem:", forControlEvents: UIControlEvents.TouchUpInside)
            cell.backgroundColor = UIColor.whiteColor()
            
            //make sure we have a valid ToDo
            if !isEmpty(item.text) {
                //do we have some cached factoids to display or do we need to request some?
                if item.factoids.count > 0 {
                    cell.titleLabel.text = item.getRandomFactoid()
                }
            } else {
                //remove blank ToDoItem from db and tableview
                removeToDo(item)
            }
            
            //highlight overdue items if we have a reminder set
            if (item.isOverdue) { // the current time is later than the to-do item's deadline
                cell.bodyLabel.textColor = UIColor.redColor()
            } else {
                cell.bodyLabel.textColor = UIColor.blackColor() // we need to reset this because a cell with red subtitle may be returned by dequeueReusableCellWithIdentifier:indexPath:
            }
        }
        
        // are we currently requesting factoids?
        if item.requesting {
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            cell.accessoryView = indicator
            indicator.startAnimating()
        } else {
            //indicator.stopAnimating()
            cell.accessoryType = UITableViewCellAccessoryType.DetailButton
        }
        
        // Make sure the constraints have been added to this cell, since it may have just been created from scratch
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        
        cell.delegate = self
        cell.toDoItem = item
        
        return cell
    }
    
    // Helper to identify if textfield is empty or only contains default placeholder text as a value
    func isEmpty(str: String) -> Bool {
        if str == Constants.Messages.PLACEHOLDER_TEXT || str == "" {
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Private methods
    
    private func getFactoids(cell: ToDoCellTableViewCell, completionHandler: (success: Bool) -> Void) {
        // first test to see if we have a network connection before requesting data from the API
        let status = Reach().connectionStatus()
        switch status {
        case .Unknown, .Offline:
            let message = "Make sure your device is connected to the internet."
            self.view.makeToast(message: message, duration: HRToastDefaultDuration, position: HRToastPositionDefault, title: Constants.Messages.NETWORK_ERROR)
            completionHandler(success: false)
        default:
            let indexPath = self.tableView.indexPathForCell(cell)
            let item = cell.toDoItem!
            item.requesting = true
            item.deleteAll()
            // Begin request
            NetworkClient.sharedInstance().getFactoids(item, completionHandler: { (reload, error) in
                //we have a API response - hide the activity indicator
                item.requesting = false
                if let nserror = error {
                    // display a toast message instead of a UIAlert in case mutliple requests fail resulting in multiple alerts the user needs to dismiss
                    let title = "API Error", message = Constants.Messages.LOADING_DATA_FAILED
                    self.view.makeToast(message: message, duration: HRToastDefaultDuration, position: HRToastPositionDefault, title: title)
                    // log the error
                    NSLog("Error requesting factoids: \(nserror), \(nserror.userInfo)")
                    completionHandler(success: false)
                }
                
                // select a random factoid returned from API
                if item.factoids.count > 0 {
                    cell.titleLabel.text = item.getRandomFactoid()
                    cell.titleLabel.hidden = false
                }
                // reload table cell to turn off activity indicator and update autolayout constraints if content was changed
                if (reload != false) {
                    // reload individual table cell: http://stackoverflow.com/questions/26709537/reload-cell-data-in-table-view-with-swift
                    self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.None)
                }
                completionHandler(success: true)
            })
        }
    }
    
    
}
