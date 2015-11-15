//
//  ToDoList.swift
//  ClueList: Convenience class for handling local notifications
//  Based on: http://jamesonquave.com/blog/local-notifications-in-ios-8-with-swift-part-2/
//
//  Created by Ryan Rose on 11/11/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class ToDoList {
    // return a singleton: http://stackoverflow.com/questions/24024549/dispatch-once-singleton-model-in-swift/24147830#24147830
    class var sharedInstance : ToDoList {
        struct Static {
            static let instance : ToDoList = ToDoList()
        }
        return Static.instance
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }
    
    func allItems() -> [ToDoItem] {
        let toDoFetchRequest = NSFetchRequest(entityName: ToDoItem.entityName)
        let primarySortDescriptor = NSSortDescriptor(key: "created", ascending: true)
        
        toDoFetchRequest.sortDescriptors = [primarySortDescriptor]
        
        let allToDos = (try! sharedContext.executeFetchRequest(toDoFetchRequest)) as! [ToDoItem]
        
        return allToDos
    }
    
    func addItem(item: ToDoItem) {
        // create a corresponding local notification
        let notification = UILocalNotification()
        notification.alertBody = "Todo Item \"\(item.text)\" Is Overdue" // text that will be displayed in the notification
        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
        notification.fireDate = item.deadline // todo item due date (when notification will be fired)
        notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        notification.userInfo = ["UUID": item.id, ] // assign a unique identifier to the notification so that we can retrieve it later
        notification.category = "TODO_CATEGORY"
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        
        setBadgeNumbers()
    }
    
    func removeItem(item: ToDoItem) {
        for notification in UIApplication.sharedApplication().scheduledLocalNotifications! { // loop through notifications...
            if (notification.userInfo!["UUID"] as! String == item.id) { // ...and cancel the notification that corresponds to this TodoItem instance (matched by UUID)
                UIApplication.sharedApplication().cancelLocalNotification(notification) // there should be a maximum of one match on UUID
                break
            }
        }
        setBadgeNumbers()
    }
    
    // schedule a reminder
    func scheduleReminderforItem(item: ToDoItem) {
        let notification = UILocalNotification() // create a new reminder notification
        notification.alertBody = "Reminder: Todo Item \"\(item.text)\" Is Overdue" // text that will be displayed in the notification
        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
        notification.fireDate = NSDate().dateByAddingTimeInterval(30 * 60) // 30 minutes from current time
        notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        notification.userInfo = ["title": item.text, "UUID": item.id] // assign a unique identifier to the notification that we can use to retrieve it later
        notification.category = "TODO_CATEGORY"
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        // update the ToDoItem's extended deadline
        item.deadline = notification.fireDate
        CoreDataManager.sharedInstance.saveContext()
    }
    
    // automatically update badge numbers when ToDoItems become overdue: http://jamesonquave.com/blog/local-notifications-in-ios-8-with-swift-part-2/
    func setBadgeNumbers() {
        let notifications = UIApplication.sharedApplication().scheduledLocalNotifications! // all scheduled notifications
        let todoItems: [ToDoItem] = self.allItems()
        for notification in notifications {
            let overdueItems = todoItems.filter({ (todoItem) -> Bool in // array of to-do items...
                if (todoItem.deadline != nil) {
                    return (todoItem.deadline!.compare(notification.fireDate!) != .OrderedDescending) // ...where item deadline is before or on notification fire date
                } else {
                    return false
                }
            })
            UIApplication.sharedApplication().cancelLocalNotification(notification) // cancel old notification
            notification.applicationIconBadgeNumber = overdueItems.count // set new badge number
            UIApplication.sharedApplication().scheduleLocalNotification(notification) // reschedule notification
        }
    }
}