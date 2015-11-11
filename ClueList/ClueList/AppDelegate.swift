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
        
        //set default list mode prior to any Core Data inserts
        ToDoListConfiguration.defaultConfiguration(sharedContext).listMode = .Simple
        
        // register app to receive local notifications
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil))  // types are UIUserNotificationType members
        
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
    
    func applicationWillResignActive(application: UIApplication) { // fired when user quits the application
        var todoItems: [ToDoItem] = TodoList.sharedInstance.allItems() // retrieve list of all to-do items
        var overdueItems = todoItems.filter({ (todoItem) -> Bool in
            return todoItem.deadline.compare(NSDate()) != .OrderedDescending
        })
        UIApplication.sharedApplication().applicationIconBadgeNumber = overdueItems.count // set our badge number to number of overdue items
    }
    
}

