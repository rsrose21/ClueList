//
//  ControllerSectionInfo.swift
//  ClueList
//
//  Created by Ryan Rose on 10/25/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation
import CoreData

class ControllerSectionInfo {
    
    // ========================================
    // MARK: - Internal properties
    // ========================================
    
    let section: ToDoSection
    let fetchedIndex: Int?
    let fetchController: NSFetchedResultsController
    var fetchedInfo: NSFetchedResultsSectionInfo? {
        guard let index = fetchedIndex else {
            return nil
        }
        return fetchController.sections![index]
    }
    
    // ========================================
    // MARK: - Internal methods
    // ========================================
    
    init(section: ToDoSection, fetchedIndex: Int?, fetchController: NSFetchedResultsController) {
        self.section = section
        self.fetchedIndex = fetchedIndex
        self.fetchController = fetchController
    }
}

extension ControllerSectionInfo: NSFetchedResultsSectionInfo {
    @objc var name: String { return section.title }
    @objc var indexTitle: String? { return "" }
    @objc var numberOfObjects: Int { return fetchedInfo?.numberOfObjects ?? 0 }
    @objc var objects: [AnyObject]? { return fetchedInfo?.objects ?? [] }
}