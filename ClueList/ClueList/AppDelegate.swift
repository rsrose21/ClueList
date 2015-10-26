//
//  AppDelegate.swift
//  ClueList
//
//  Created by Ryan Rose on 10/12/15.
//  Copyright © 2015 GE. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Change navigation bar color: https://coderwall.com/p/dyqrfa/customize-navigation-bar-appearance-with-swift
        let navigationBarAppearace = UINavigationBar.appearance();
        
        navigationBarAppearace.tintColor = UIColor(hexString: "#ffffffff")
        navigationBarAppearace.barTintColor = UIColor(hexString: "#6F5499ff")
        
        // change navigation item title color
        navigationBarAppearace.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        
        //change status bar color
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        
        //set default list mode prior to any Core Data inserts
        ToDoListConfiguration.defaultConfiguration(sharedContext).listMode = .Simple
        
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

}

