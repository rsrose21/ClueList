# ClueList
Final Project Udacity IOS Nanodegree

ClueList is a iOS app developed in Swift which extends the traditional to-do task management app.
ClueList combines traditional task management with interesting trivia and facts in an effort to help keep you organized while exercising your brain and improving your working memory. 

Users enter tasks and each task is replaced with a series of interesting facts and trivia (factoids) related to keywords found within the original task content. Swiping right reveals a "clue" found within the displayed factoid, highlighting the keyword used to associate the task and factoid. If the clue does not prompt the user to remember the original task they can swipe left to reveal the original task entered.

A example task may be to "Feed the cat". The app will query the ClueList API for factoids based on the string "feed the cat". Several factoids will be returned and one will randomly replace the entered task in the list, for example, "A group of cats is called a clowder". Swiping right will highlight the word "cat" in "cats", revealing the clue. Swiping left will reveal the original task "Feed the cat". Pulling down on the list will refresh the list and randomly select another factoid to display for each task.

Other features include:

* Add, edit, delete tasks
* Prioritize tasks
* Reorder tasks by simple drag 'n' drop
* Create reminders and alerts
* Badging 

## Compatibility
This repository's code works in XCode 7.0 with Swift 2.0
