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
        static let NETWORK_ERROR: String = "No Internet Connection "
        static let LOADING_DATA_FAILED: String = "Loading data has failed"
        static let PLACEHOLDER_TEXT = "Enter Task"
    }
    
    struct Data {
        static let SEED_DB: Bool = false
        static let DEBUG_LAYERS: Bool = false
        static let APP_STATE: String = "listMode"
    }
    
    struct API {
        static let BASE_URL: String = "https://cluelist-api.herokuapp.com/api/"
        static let ACCESS_TOKEN: String = "iwoPb0w0Lj5axSGon8ssVNYDEvAsA4o4CgpNIGhmv9BP2BzAX7ETDcAjqLo3AY6w"
        // uncomment these lines and update the ACCESS_TOKEN if you are running the API locally
        //static let BASE_URL: String = "http://localhost:3000/api/"
        //static let ACCESS_TOKEN: String = "tY6apkFWNqaxiaUnyxmZi8gGccB1QiH0t2SFTbEHRoE60a1uSeswFLOSh0SKuhZX"
    }
    
    struct UIFonts {
        static let BASE_FONT_SIZE: CGFloat = 12.0
        static let HEADLINE_FONT_SIZE: CGFloat = BASE_FONT_SIZE + 2
        
        static let BODY_FONT: String = "Helvetica Neue"
        static let HEADLINE_FONT: String = "Helvetica Neue"
        static let HIGHLIGHT_FONT: String = "HelveticaNeue-BoldItalic"
    }
    
    struct UIColors {
        static let WHITE: String = "#ffffffff"
        static let NAVIGATION_BAR: String = "#6F5499ff"
        static let TABLE_BG: String = "#eeeeeeff"
        static let TOOLBAR_ACTIVE: String = "#ff0000ff"
        static let TOOLBAR_ITEM: String = "#A1A1A1ff"
    }
    
    struct UIDimensions {
        // The CGFloat type annotation is necessary for these constants because they are passed as arguments to bridged Objective-C methods,
        // and without making the type explicit these will be inferred to be type Double which is not compatible.
        static let TABLE_CELL_PADDING_TOP: CGFloat = 5.0
        static let TABLE_CELL_PADDING_RIGHT: CGFloat = 40.0
        static let TABLE_CELL_PADDING_BOTTOM: CGFloat = 0.0
        static let TABLE_CELL_PADDING_LEFT: CGFloat = 40.0
        
        static let TABLE_SECTION_HEIGHT: CGFloat = 20.0
    }
}