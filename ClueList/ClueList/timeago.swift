//
//  timeago.swift
//  https://gist.github.com/jacks205/4a77fb1703632eb9ae79
//
//

import Foundation

func timeAgoSinceDate(date:NSDate, numericDates:Bool) -> String {
    let calendar = NSCalendar.currentCalendar()
    let now = NSDate()
    let earliest = now.earlierDate(date)
    let latest = (earliest == now) ? date : now
    let components:NSDateComponents = calendar.components([NSCalendarUnit.Minute , NSCalendarUnit.Hour , NSCalendarUnit.Day , NSCalendarUnit.WeekOfYear , NSCalendarUnit.Month , NSCalendarUnit.Year , NSCalendarUnit.Second], fromDate: earliest, toDate: latest, options: NSCalendarOptions())
    //Format date for display: http://www.brianjcoleman.com/tutorial-nsdate-in-swift/
    let formatter = NSDateFormatter();
    formatter.dateFormat = "MMM dd 'at' h:mm a" // example: "Jan 01 at 12:00 PM"
    
    if (components.weekOfYear >= 1){
        return formatter.stringFromDate(date)
    } else if (components.day >= 2) {
        return "\(components.day) days ago"
    } else if (components.day >= 1){
        if (numericDates){
            return "1 day ago"
        } else {
            return "Yesterday"
        }
    } else if (components.hour >= 2) {
        return "\(components.hour) hours ago"
    } else if (components.hour >= 1){
        if (numericDates){
            return "1 hour ago"
        } else {
            return "An hour ago"
        }
    } else if (components.minute >= 2) {
        return "\(components.minute) minutes ago"
    } else if (components.minute >= 1){
        if (numericDates){
            return "1 minute ago"
        } else {
            return "A minute ago"
        }
    } else if (components.second >= 3) {
        return "\(components.second) seconds ago"
    } else {
        return "Just now"
    }
    
}