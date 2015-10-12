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
func addToDoItem(text: String) {
    let dictionary: [String: AnyObject] = ["text": text]
    sampleData.append(ToDoItem(dictionary: dictionary))
}

//add some default ToDos to start
func loadSampleData() {
    addToDoItem("feed the cat")
    addToDoItem("buy eggs")
    addToDoItem("watch WWDC videos")
    addToDoItem("The top of the Eiffel Tower leans away from the sun, as the metal facing the sun heats up and expands. It can move as much as 7 inches.")
    addToDoItem("buy a new iPhone")
    addToDoItem("darn holes in socks")
    addToDoItem("write this tutorial")
    addToDoItem("master Swift")
    addToDoItem("learn to draw")
    addToDoItem("get more exercise")
    addToDoItem("catch up with Mom")
    addToDoItem("get a hair cut")
}