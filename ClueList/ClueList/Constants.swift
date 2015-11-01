//
//  Constants.swift
//  ClueList
//
//  Created by Ryan Rose on 10/24/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Foundation
import UIKit

class Constants: NSObject {
    
    struct Messages {
        static let LOADING_DATA: String = "Loading..."
        static let LOADING_DATA_FAILED: String = "Loading data has failed"
        static let PLACEHOLDER_TEXT = "Enter Task"
    }
    
    struct Data {
        static let SEED_DB: Bool = false
    }
    
    struct API {
        static let BASE_URL: String = "http://localhost:3000/api/"
    }
    
    struct UIFonts {
        static let BASE_FONT_SIZE: CGFloat = 12.0
        static let HEADLINE_FONT_SIZE: CGFloat = 17.0
        
        static let BODY_FONT: String = "Helvetica Neue"
        static let HEADLINE_FONT: String = "Helvetica Neue"
    }
    
    struct UIColors {
        static let WHITE: String = "#ffffffff"
        static let NAVIGATION_BAR: String = "#6F5499ff"
    }
}