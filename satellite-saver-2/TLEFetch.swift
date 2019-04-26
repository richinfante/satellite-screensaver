//
//  TLEFetch.swift
//  satellite-saver-2
//
//  Created by Rich Infante on 4/26/19.
//  Copyright © 2019 Rich Infante. All rights reserved.
//

import Foundation

@objcMembers class TLEFetcher : NSObject {
    /// Store TLE Lines
    var lines: String? = nil
    
    /// Store name
    var name : String? = nil
    
    /// Boolean to detect fetching
    var is_fetching: Bool = false
    override init() {
        super.init()
    }
    
    /// Fetch iss tle
    func fetch_iss() -> String? {
        // Return nil while loading
        if self.is_fetching {
            return nil
        }

        // If loaded, return lines.
        if let lines = self.lines {
            return lines
        }
        
        // Load from internet.
        self.is_fetching = true
        guard let url = URL(string: "https://celestrak.richinfante.com/stations.txt") else {
            return nil
        }

        // TODO: make this request asynchronous.
        // It currently works, but hangs the first drawRect: call until the request fails / completes.
        guard let data = try? Data(contentsOf: url), let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        // Extract first 3 lines / name.
        let stringToSplit = string.components(separatedBy: "\n")
        self.lines = "\(stringToSplit[0])\n\(stringToSplit[1])\n\(stringToSplit[2])"
        self.name = stringToSplit[0]
        self.is_fetching = false
        
        return self.lines
        
    }
}
