//
//  TLEFetch.swift
//  satellite-saver-2
//
//  Created by Rich Infante on 4/26/19.
//  Copyright © 2019 Rich Infante. All rights reserved.
//

import Foundation
import Cocoa

@objcMembers class TLE : NSObject {
    /// Store TLE Lines
    var lines: String? = nil
    
    /// Store name
    var name : String? = nil
    
    // Store track
    var track: Track! = nil
    
    var trackColor: NSColor = NSColor.green
    
    init(name: String, lines: String) {
        super.init()
        self.name = name
        self.lines = lines
    }
    
    @objc func set_track(track: Track) {
        self.track = track
    }
    
    @objc func get_track() -> Track {
        return self.track!
    }
    
    @objc func get_current_point() -> TrackPoint {
        return self.track.current
    }
}

@objcMembers class TLEFetcher : NSObject {
    var tles: [TLE] = []
    
    /// Boolean to detect fetching
    var is_fetching: Bool = false
    var fetched: Bool = false
    var fetch_error = false

    override init() {
        super.init()
    }
    
    func get_tles (fromURL: String) -> [TLE] {
        if fetched {
            return tles
        }
        
        if is_fetching {
            return []
        }
        
        self.is_fetching = true
        let url = URL(string: fromURL)!
        
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else {
                self.fetch_error = true
                return
            }
            guard let string = String(data: data, encoding: .utf8) else {
                self.fetch_error = true
                return
            }

            let stringToSplit = string.components(separatedBy: "\n")

            for i in stride(from: 0, to: stringToSplit.count, by: 3) {
                if i + 2 >= stringToSplit.count {
                    break
                }
                
                let tle = TLE(name: stringToSplit[i], lines: "\(stringToSplit[i])\n\(stringToSplit[i+1])\n\(stringToSplit[i+2])")
                
                DispatchQueue.main.async {
                    self.tles.append(tle)
                }
            }
            
            DispatchQueue.main.async {
                self.is_fetching = false
                self.fetched = true
                self.fetch_error = false
            }
        }
        
        task.resume()
        
        return []
    }
    
//    /// Fetch iss tle
//    func fetch_iss() -> String? {
//        // Return nil while loading
//        if self.is_fetching {
//            return nil
//        }
//
//        // If loaded, return lines.
//        if let lines = self.lines {
//            return lines
//        }
//
//        // Load from internet.
//        self.is_fetching = true
//        guard let url = URL(string: "https://celestrak.richinfante.com/stations.txt") else {
//            return nil
//        }
//
//        // TODO: make this request asynchronous.
//        // It currently works, but hangs the first drawRect: call until the request fails / completes.
//        guard let data = try? Data(contentsOf: url), let string = String(data: data, encoding: .utf8) else {
//            return nil
//        }
//
//        // Extract first 3 lines / name.
//        let stringToSplit = string.components(separatedBy: "\n")
//        self.lines = "\(stringToSplit[0])\n\(stringToSplit[1])\n\(stringToSplit[2])"
//        self.name = stringToSplit[0]
//        self.is_fetching = false
//
//        return self.lines
//
//    }
}
