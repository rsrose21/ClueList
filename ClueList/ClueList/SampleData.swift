//
//  SampleData.swift
//  ClueList
//
//  Created by Ryan Rose on 10/12/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation

var sampleData = [ToDoItem]()

//helper to add ToDoItem given text description
func addToDoItem(text: String, clue: String?, factoid: String?) {
    let dictionary: [String: AnyObject?] = ["text": text, "clue": clue, "factoid": factoid]
    sampleData.append(ToDoItem(dictionary: dictionary))
}

//add some default ToDos to start
func loadSampleData() {
    addToDoItem("feed the cat", clue: "cat", factoid: "Cats have over 20 muscles that control their ears.")
    addToDoItem("pick up milk", clue: "milk", factoid: "The average cow in the U.S. produces about 21,000 lbs. of milk per year")
    addToDoItem("buy eggs", clue: "eggs", factoid: "Americans consume 76.5 billion eggs per year")
}