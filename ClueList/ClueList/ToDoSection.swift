//
//  ToDoMetaData.swift
//  ClueList: maintains sort order of sections
//  Based from: http://www.iosnomad.com/blog/2014/8/6/swift-nsfetchedresultscontroller-trickery
//
//  Original Created by Alek Åström on 2015-09-13.
//  Copyright © 2015 Apps and Wonders. All rights reserved.
//  https://github.com/MrAlek/Swift-NSFetchedResultsController-Trickery/blob/master/LICENSE
//

import Foundation

enum ToDoSection: String {
    case ToDo = "10"
    case HighPriority = "11"
    case MediumPriority = "12"
    case LowPriority = "13"
    case Done = "20"
    case NoPriority = "5"
    
    var title: String {
        switch self {
        case ToDo:              return "Left to do"
        case Done:              return "Done"
        case HighPriority:      return "High"
        case MediumPriority:    return "Medium"
        case LowPriority:       return "Low"
        case NoPriority:        return "None"
        }
    }
}
