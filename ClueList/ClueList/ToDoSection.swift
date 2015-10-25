//
//  ToDoSection.swift
//  ClueList
//  Maintains sort order of sections 
//
//  Created by Ryan Rose on 10/25/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation

enum ToDoSection: String {
    case ToDo = "10"
    case HighPriority = "11"
    case MediumPriority = "12"
    case LowPriority = "13"
    case Done = "20"
    
    var title: String {
        switch self {
        case ToDo:              return "Left to do"
        case Done:              return "Done"
        case HighPriority:      return "High priority"
        case MediumPriority:    return "Medium priority"
        case LowPriority:       return "Low priority"
        }
    }
}
