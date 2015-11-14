//
//  ControllerSectionInfo.swift
//  Created for: http://www.iosnomad.com/blog/2014/8/6/swift-nsfetchedresultscontroller-trickery
//
//  Created by Alek Åström on 2015-09-13.
//  Copyright © 2015 Apps and Wonders. All rights reserved.
//  https://github.com/MrAlek/Swift-NSFetchedResultsController-Trickery/blob/master/LICENSE
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