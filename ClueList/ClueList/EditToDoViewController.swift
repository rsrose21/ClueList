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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        textField.text = todo!.text
        textField.becomeFirstResponder()
    }
    
    @IBAction func setReminder() {
        
        appDelegate = UIApplication.sharedApplication().delegate
            as? AppDelegate
        
        //verify and/or ask for access to event store
        if appDelegate!.eventStore == nil {
            appDelegate!.eventStore = EKEventStore()
            appDelegate!.eventStore!.requestAccessToEntityType(
                EKEntityTypeReminder, completion: {(granted, error) in
                    if !granted {
                        print("Access to store not granted")
                        print(error.localizedDescription)
                    } else {
                        print("Access granted")
                    }
            })
        }
        
        if (appDelegate!.eventStore != nil) {
            self.createReminder()
        }
    }
    
    func createReminder() {
        
        let reminder = EKReminder(eventStore: appDelegate!.eventStore!)
        
        reminder.title = reminder.text
        reminder.calendar =
            appDelegate!.eventStore!.defaultCalendarForNewReminders()
        let date = myDatePicker.date
        let alarm = EKAlarm(absoluteDate: date)
        
        reminder.addAlarm(alarm)
        
        var error: NSError?
        appDelegate!.eventStore!.saveReminder(reminder,
            commit: true, error: &error)
        
        if error != nil {
            print("Reminder failed with error \(error?.localizedDescription)")
        }
    }
    
    func addNotification(item: ToDoItem) { // persist a representation of this todo item in NSUserDefaults
        // create a corresponding local notification
        ToDoList.sharedInstance.addItem(item)
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
        try! sharedContext.save()
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}