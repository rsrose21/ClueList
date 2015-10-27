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

class EditToDoViewController: UIViewController {
    
    @IBOutlet var textField: UITextField!
    @IBOutlet var priorityControl: UISegmentedControl!
    
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