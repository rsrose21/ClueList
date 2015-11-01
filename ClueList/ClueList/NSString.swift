//
//  NSString.swift
//  ClueList
//
//  Created by Ryan Rose on 11/1/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation

extension NSString {
    
    // encode a string to Base64: http://iosdevelopertips.com/swift-code/base64-encode-decode-swift.html
    func encodeString(str: String) -> NSString {
        let utf8str = str.dataUsingEncoding(NSUTF8StringEncoding)
        
        let base64Encoded = utf8str!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        
        return base64Encoded
    }
    
    // decode a Base64 encoded string: http://iosdevelopertips.com/swift-code/base64-encode-decode-swift.html
    func decodeString(base64Encoded: String) -> NSString {
        let data = NSData(base64EncodedString: base64Encoded, options: NSDataBase64DecodingOptions(rawValue: 0))
        
        let base64Decoded = NSString(data: data!, encoding: NSUTF8StringEncoding)
        
        return base64Decoded!
    }
    
}