//
//  EditToDoViewController.swift
//  ClueList
//
//  Created by Ryan Rose on 10/26/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import EventKit

class EditToDoViewController: UIViewController {
    
    @IBOutlet var textField: UITextField!
    @IBOutlet var priorityControl: UISegmentedControl!
    @IBOutlet weak var reminder: UITextField!
    @IBOutlet weak var myDatePicker: UIDatePicker!
    
    var appDelegate: AppDelegate?
    var eventStore: EKEventStore?
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }
    var todo: ToDoItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // update toolbar
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancelButtonPressed")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "saveButtonPressed")
        title = "Edit Task"
        
        appDelegate = UIApplication.sharedApplication().delegate
            as? AppDelegate
        if appDelegate!.eventStore == nil {
            appDelegate!.eventStore = EKEventStore()
        }
        eventStore = appDelegate!.eventStore
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        textField.text = todo!.text
        textField.becomeFirstResponder()
        //ask user permission to access calendar to set reminders
        checkCalendarAuthorizationStatus()
    }
    
    // MARK: EventKit Access: https://www.andrewcbancroft.com/2015/05/14/beginners-guide-to-eventkit-in-swift-requesting-permission/
    
    func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityType.Reminder)
        
        switch (status) {
        case EKAuthorizationStatus.NotDetermined:
            // This happens on first-run
            requestAccessToCalendar()
        case EKAuthorizationStatus.Authorized:
            // we have permission, display the reminders controls
            enableReminders()
        case EKAuthorizationStatus.Restricted, EKAuthorizationStatus.Denied:
            // We need to help them give us permission
            needPermissionView()
        }
    }
    
    func requestAccessToCalendar() {
        eventStore!.requestAccessToEntityType(EKEntityType.Reminder, completion: {
            (accessGranted: Bool, error: NSError?) in
            
            if accessGranted == true {
                dispatch_async(dispatch_get_main_queue(), {
                    self.enableReminders()
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.needPermissionView()
                })
            }
        })
    }
    
    func enableReminders() {
        
    }
    
    func needPermissionView() {
        dispatch_async(dispatch_get_main_queue(), {
            // Create the alert controller
            let alertController = UIAlertController(title: "Title", message: "Message", preferredStyle: .Alert)
            
            // Create the actions
            let okAction = UIAlertAction(title: "Go to Settings", style: UIAlertActionStyle.Default) {
                UIAlertAction in
                let openSettingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
                UIApplication.sharedApplication().openURL(openSettingsUrl!)
            }
            let cancelAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel) {
                UIAlertAction in
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            
            // Add the actions
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            
            // Present the controller
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }
    
    @IBAction func setReminder() {
        
        
    }
    
    func createReminder(item: ToDoItem) {
        let reminder = EKReminder(eventStore: eventStore!)
        
        reminder.title = textField.text!
        reminder.calendar = eventStore!.defaultCalendarForNewReminders()
        let date = myDatePicker.date
        let alarm = EKAlarm(absoluteDate: date)
        reminder.addAlarm(alarm)
        
        // save the reminder to the event store
        dispatch_async(dispatch_get_main_queue()) {
            do {
                try self.eventStore!.saveReminder(reminder, commit: true)
                //set the deadline date to the reminder date
                item.deadline = date
                CoreDataManager.sharedInstance.saveContext()
                // create a corresponding local notification
                ToDoList.sharedInstance.addItem(item)
            } catch {
                let nserror = error as NSError
                NSLog("Reminder failed with error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    func cancelButtonPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func saveButtonPressed() {
        guard let title = textField.text else {
            presentViewController(UIAlertController(title: "Can't update Task", message: "Title can't be blank", preferredStyle: .Alert), animated: true, completion: nil)
            return
        }
        
        let toDo = NSEntityDescription.insertNewObjectForEntityForName(ToDoItem.entityName, inManagedObjectContext: sharedContext) as! ToDoItem
        toDo.text = title
        toDo.priority = toDo.selectedPriority(self.priorityControl.selectedSegmentIndex).rawValue
        toDo.metaData.internalOrder = ToDoMetaData.maxInternalOrder(sharedContext)+1
        toDo.metaData.updateSectionIdentifier()
        CoreDataManager.sharedInstance.saveContext()
        
        createReminder(todo!)
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}