//
//  NSMutableAttributedString.swift
//  Swift extension to NSMutableAttributedString adding methods for highlighting and replacing substrings
//  Based on: https://gist.github.com/sketchytech/7cd6ab241a22fc2a3ffc
//  ClueList
//
//  Created by Ryan Rose on 10/15/15.
//  Copyright © 2015 GE. All rights reserved.
//

import UIKit

extension NSMutableAttributedString {
    
    func highlightStrings(stringToHighlight:String, fontName:String, fontSize:CGFloat) throws -> String {
        
        //Defining fonts of size and type for highlight
        let boldFont:UIFont = UIFont(name: fontName, size: fontSize)!
        
        let exp = try NSRegularExpression(pattern: stringToHighlight, options: [.CaseInsensitive])
        
        let arr = exp.matchesInString(self.string, options: NSMatchingOptions(rawValue: 0), range:NSRange(location: 0, length: self.length))
        
        for s in arr {
            
            //highlight text in a UILabel: http://stackoverflow.com/questions/29165560/ios-swift-is-it-possible-to-change-the-font-style-of-a-certain-word-in-a-string
            self.setAttributes([NSFontAttributeName : boldFont, NSForegroundColorAttributeName : UIColor.redColor()], range: s.range)
        }
        
        return stringToHighlight
    }
    
    func replaceStrings(find:String, replace:String, usingRegex:Bool = false) throws -> Int {
        
        var useRegex:NSRegularExpressionOptions?
        
        if !usingRegex {
            useRegex = NSRegularExpressionOptions.IgnoreMetacharacters
        }
        
        let exp = try NSRegularExpression(pattern: find, options: (useRegex ?? nil)!)
        
        _ = exp.matchesInString(self.string, options: NSMatchingOptions(rawValue: 0), range:NSRange(location: 0, length: self.length))
        
        return self.mutableString.replaceOccurrencesOfString(find, withString:replace, options:NSStringCompareOptions.RegularExpressionSearch, range:NSRange(location: 0, length: self.length))
    }
}