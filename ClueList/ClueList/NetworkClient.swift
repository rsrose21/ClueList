//
//  NetworkClient.swift
//  ClueList
//
//  Created by Ryan Rose on 10/30/15.
//  Copyright © 2015 GE. All rights reserved.
//

import Alamofire
import SwiftyJSON

class NetworkClient: NSObject {
    
    // Method for invoking GET requests on API
    func taskForGETMethod(method: String, var params: [String: AnyObject]?, completionHandler: (result: JSON!) -> Void) {
        // Build URL, configure request
        let urlString = Constants.API.BASE_URL + method
        params!["access_token"] = Constants.API.ACCESS_TOKEN
        //don't block main UI by making async API requests in a separate thread
        dispatch_async(dispatch_get_main_queue()) {
            Alamofire.request(.GET, urlString, parameters: params, encoding: ParameterEncoding.URL).responseJSON { response in
                switch response.result {
                case .Success(let data):
                    let json = JSON(data)
                    //send parsed JSON back to completion handler
                    completionHandler(result: json["results"])
                case .Failure(let error):
                    print("Request failed with error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> NetworkClient {
        struct Singleton {
            static var sharedInstance = NetworkClient()
        }
        return Singleton.sharedInstance
    }
}
