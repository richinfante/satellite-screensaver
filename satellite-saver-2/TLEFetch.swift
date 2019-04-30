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
    
    var trackColor: NSColor
    
    init(name: String, lines: String, trackColor: NSColor) {
        self.trackColor = trackColor
        self.name = name
        self.lines = lines
        super.init()
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
    
    func reload() {
        self.tles = []
        self.fetched = false
        self.is_fetching = false
    }
    
    func colorForTrack(at: Int) -> NSColor {
        let index = at % colors.count;
        return self.colors[index]
    }
    
    func get_tles (fromURL: String, filteringNames: String, randomizingColors: Bool, defaultColor: NSColor) -> [TLE] {
        let filtering = filteringNames.components(separatedBy: ",").filter({ $0 != "" });
        if fetched {
            return tles
        }
        
        if is_fetching {
            return []
        }
        
        self.is_fetching = true
        guard let url = URL(string: fromURL) else {
            return tles
        }
        
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
                
                if filtering.count > 0 {
                    var found = false
                    for item in filtering {
                        if item.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == stringToSplit[i].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
                            found = true
                        }
                    }
                    
                    if !found {
                        continue
                    }
                }
                var trackColor: NSColor!;
                if randomizingColors {
                    trackColor = self.colorForTrack(at: self.tles.count)
                } else {
                    trackColor = defaultColor;
                }

                let tle = TLE(name: stringToSplit[i], lines: "\(stringToSplit[i])\n\(stringToSplit[i+1])\n\(stringToSplit[i+2])", trackColor: trackColor)
            
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
}
