//
//  AppDelegate.swift
//  ClueList
//
//  Created by Ryan Rose on 10/12/15.
//  Copyright © 2015 GE. All rights reserved.
//

import UIKit
import CoreData
import EventKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    //store event store object so we don't request if multiple times
    var eventStore: EKEventStore?

    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Change navigation bar color: https://coderwall.com/p/dyqrfa/customize-navigation-bar-appearance-with-swift
        let navigationBarAppearace = UINavigationBar.appearance();
        
        navigationBarAppearace.tintColor = UIColor(hexString: Constants.UIColors.WHITE)
        navigationBarAppearace.barTintColor = UIColor(hexString: Constants.UIColors.NAVIGATION_BAR)
        
        // change navigation item title color
        navigationBarAppearace.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(hexString: Constants.UIColors.WHITE)!]
        
        //change status bar color
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        
        // set default list mode prior to any Core Data inserts
        let defaults = NSUserDefaults.standardUserDefaults()
        let mode = defaults.integerForKey(Constants.Data.APP_STATE)
        if (ToDoListMode(rawValue: mode) != nil) {
            ToDoListConfiguration.defaultConfiguration(sharedContext).listMode = ToDoListMode(rawValue: mode)!
        } else {
            ToDoListConfiguration.defaultConfiguration(sharedContext).listMode = .Simple
        }
        
        // register app to receive local notifications
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil))  // types are UIUserNotificationType members
        
        // allow user to update ToDoItems from notifications bar
        addActions(application)
        
        if Constants.Data.SEED_DB {
            //seed the Core Data database with sample ToDos
            let dataHelper = DataHelper()
            dataHelper.seedDataStore()
            dataHelper.printAllToDos()
        }
        return true
    }

    func applicationDidEnterBackground(application: UIApplication) {
        CoreDataManager.sharedInstance.saveContext()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        CoreDataManager.sharedInstance.saveContext()
    }

    // notify our listener when the ToDo list should be refreshed on application state change
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        NSNotificationCenter.defaultCenter().postNotificationName("TodoListShouldRefresh", object: self)
    }

    func applicationDidBecomeActive(application: UIApplication) {
        NSNotificationCenter.defaultCenter().postNotificationName("TodoListShouldRefresh", object: self)
    }
    
    // badging the app icon for overdue ToDoItems
    func applicationWillResignActive(application: UIApplication) { // fired when user quits the application
        let todoItems: [ToDoItem] = ToDoList.sharedInstance.allItems() // retrieve list of all to-do items
        let overdueItems = todoItems.filter({ (todoItem) -> Bool in
            if (todoItem.deadline != nil) {
                return todoItem.deadline!.compare(NSDate()) != .OrderedDescending
            } else {
                return false
            }
        })
        UIApplication.sharedApplication().applicationIconBadgeNumber = overdueItems.count // set our badge number to number of overdue items
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        let dictionary: [String: AnyObject?] = ["deadline": notification.fireDate!, "text": notification.userInfo!["title"] as! String, "id": notification.userInfo!["UUID"] as! String!]
        let toDoItem = ToDoItem(dictionary: dictionary, context: sharedContext)
        
        CoreDataManager.sharedInstance.saveContext()

        switch (identifier!) {
        case "COMPLETE_TODO":
            ToDoList.sharedInstance.removeItem(toDoItem)
        case "REMIND":
            ToDoList.sharedInstance.scheduleReminderforItem(toDoItem)
        default: // switch statements must be exhaustive - this condition should never be met
            print("Error: unexpected notification action identifier!")
        }
        completionHandler() // per developer documentation, app will terminate if we fail to call this
    }
    
    // allow user to update ToDoItems from notifications bar: http://jamesonquave.com/blog/local-notifications-in-ios-8-with-swift-part-2/
    func addActions(application: UIApplication) -> Bool {
        let completeAction = UIMutableUserNotificationAction()
        completeAction.identifier = "COMPLETE_TODO" // the unique identifier for this action
        completeAction.title = "Complete" // title for the action button
        completeAction.activationMode = .Background // UIUserNotificationActivationMode.Background - don't bring app to foreground
        completeAction.authenticationRequired = false // don't require unlocking before performing action
        completeAction.destructive = true // display action in red
        
        let remindAction = UIMutableUserNotificationAction()
        remindAction.identifier = "REMIND"
        remindAction.title = "Remind in 30 minutes"
        remindAction.activationMode = .Background
        remindAction.destructive = false
        
        let todoCategory = UIMutableUserNotificationCategory() // notification categories allow us to create groups of actions that we can associate with a notification
        todoCategory.identifier = "TODO_CATEGORY"
        todoCategory.setActions([remindAction, completeAction], forContext: .Default) // UIUserNotificationActionContext.Default (4 actions max)
        todoCategory.setActions([completeAction, remindAction], forContext: .Minimal) // UIUserNotificationActionContext.Minimal - for when space is limited (2 actions max)
        
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: NSSet(array: [todoCategory]) as? Set<UIUserNotificationCategory>)) // we're now providing a set containing our category as an argument
        return true
    }
    
}

