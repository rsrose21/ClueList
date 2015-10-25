//
//  FetchControllerDelegate.swift
//  ClueList
//
//  Created by Ryan Rose on 10/25/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation
import CoreData
import UIKit

public class FetchControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {
    
    private var sectionsBeingAdded: [Int] = []
    private var sectionsBeingRemoved: [Int] = []
    private unowned let tableView: UITableView
    
    var onUpdate: ((indexPath: NSIndexPath?, object: AnyObject) -> Void)?
    public var ignoreNextUpdates: Bool = false
    
    init(tableView: UITableView) {
        self.tableView = tableView
    }
    
    public func controllerWillChangeContent(controller: NSFetchedResultsController)  {
        if ignoreNextUpdates {
            return
        }
        
        sectionsBeingAdded = []
        sectionsBeingRemoved = []
        tableView.beginUpdates()
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)  {
        if ignoreNextUpdates {
            return
        }
        
        switch type {
        case .Insert:
            sectionsBeingAdded.append(sectionIndex)
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            sectionsBeingRemoved.append(sectionIndex)
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    
    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if ignoreNextUpdates {
            return
        }
        
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case .Update:
            onUpdate?(indexPath: indexPath!, object: anObject)
        case .Move:
            // Stupid and ugly, rdar://17684030
            if !sectionsBeingAdded.contains(newIndexPath!.section) && !sectionsBeingRemoved.contains(indexPath!.section) {
                tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                onUpdate?(indexPath: indexPath!, object: anObject)
            } else {
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            }
        }
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController)  {
        if !ignoreNextUpdates {
            tableView.endUpdates()
        }
        
        ignoreNextUpdates = false
    }
}