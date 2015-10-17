//
//  SampleData.swift
//  ClueList
//
//  Created by Ryan Rose on 10/12/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation

var sampleData = [ToDoItem]()

//add some default ToDos to start
func loadSampleData() {
    var params: [String: AnyObject?] = ["text": "feed the cat", "clue": "cat", "factoid": "Cats have over 20 muscles that control their ears."]
    sampleData.append(ToDoItem(dictionary: params))
    
    params = ["text": "pick up milk", "clue": "milk", "factoid": "The average cow in the U.S. produces about 21,000 lbs. of milk per year", "completed": true]
    sampleData.append(ToDoItem(dictionary: params))
    
    params = ["text": "buy eggs", "clue": "eggs", "factoid": "Americans consume 76.5 billion eggs per year"]
    sampleData.append(ToDoItem(dictionary: params))
}