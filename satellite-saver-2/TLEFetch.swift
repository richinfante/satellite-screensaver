//
//  TLEFetch.swift
//  satellite-saver-2
//
//  Created by Rich Infante on 4/26/19.
//  Copyright © 2019 Rich Infante. All rights reserved.
//

import Foundation
import Cocoa

/// Helper class to fetch TLEs
@objcMembers class TLEFetcher : NSObject {
    var tles: [TLE] = []
    
    /// Boolean to detect fetching
    var is_fetching: Bool = false
    var fetched: Bool = false
    var fetch_error = false
    
    // Colors array (not used).
    let colors = [
        NSColor.red,
        NSColor.orange,
        NSColor.yellow,
        NSColor.green,
        NSColor.blue,
        NSColor.purple,
        NSColor.white,
        NSColor.gray
    ]

    override init() {
        super.init()
    }
    
    /// Trigger reload by resetting flags.
    func reload() {
        self.tles = []
        self.fetched = false
        self.is_fetching = false
    }
    
    /// Get the color for a track using randomization
    func colorForTrack(at: Int) -> NSColor {
        let index = at % colors.count;
        return self.colors[index]
    }
    
    /// Get a list of the currently available tles.
    func get_tles (fromURL: String, filteringNames: String, randomizingColors: Bool, defaultColor: NSColor) -> [TLE] {
        // Split filters by commas, and remove extras.
        let filtering = filteringNames.components(separatedBy: ",").filter({ $0 != "" });
        
        // If already fetched, return tles.
        if fetched {
            return tles
        }
        
        // If currently fetching, return blank.
        if is_fetching {
            return []
        }
        
        // Toggle fetching.
        self.is_fetching = true
        
        // Try to create aurl
        guard let url = URL(string: fromURL) else {
            return tles
        }
        
        // Launch a task.
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            // If data is nil, fail.
            guard let data = data else {
                self.fetch_error = true
                return
            }
            
            // Try to decode utf8 contents.
            guard let string = String(data: data, encoding: .utf8) else {
                self.fetch_error = true
                return
            }

            // Split by lines.
            let stringToSplit = string.components(separatedBy: "\n")

            // Parse into separate TLES.
            for i in stride(from: 0, to: stringToSplit.count, by: 3) {
                // If i+2 is out-of-bounds, done.
                if i + 2 >= stringToSplit.count {
                    break
                }
                
                /// If we're filtering, see if it's filtered.
                if filtering.count > 0 {
                    var found = false
                    
                    // Loop through filters
                    for item in filtering {
                        // Id trimmed version is equal, found it!
                        if item.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == stringToSplit[i].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
                            found = true
                        }
                    }
                    
                    // If not found, skip adding this one.
                    if !found {
                        continue
                    }
                }
                
                // Intiialize track colors.
                var trackColor: NSColor!;
                if randomizingColors {
                    trackColor = self.colorForTrack(at: self.tles.count)
                } else {
                    trackColor = defaultColor;
                }

                // Create tle object.
                let tle = TLE(name: stringToSplit[i], lines: "\(stringToSplit[i])\n\(stringToSplit[i+1])\n\(stringToSplit[i+2])", trackColor: trackColor)
            
                // On main thread, append tles.
                DispatchQueue.main.async {
                    self.tles.append(tle)
                }
            }
            
            // Set flags.
            DispatchQueue.main.async {
                self.is_fetching = false
                self.fetched = true
                self.fetch_error = false
            }
        }
        
        task.resume()
        
        return []
    }
}
