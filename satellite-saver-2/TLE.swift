//
//  TLE.swift
//  satellite-saver-2
//
//  Created by Rich Infante on 4/30/19.
//  Copyright © 2019 Rich Infante. All rights reserved.
//

import Foundation

/// Store a two-line element set.
@objcMembers class TLE : NSObject {
    /// Store TLE Lines
    var lines: String? = nil
    
    /// Store name
    var name: String? = nil
    
    // Store track
    var track: Track! = nil
    
    /// Have an error?
    var error: Bool = false
    
    /// The displayed track color.
    var trackColor: NSColor
    
    /// Initialize a new track.
    init(name: String, lines: String, trackColor: NSColor) {
        self.trackColor = trackColor
        self.name = name
        self.lines = lines
        super.init()
    }
    
    /// Set the contained track (objc helper)
    @objc func set_track(track: Track) {
        self.track = track
    }
    
    /// Check if we have a track.
    @objc func has_track() -> Bool {
        return self.track != nil
    }
    
    /// Get the contained track (objc helper)
    @objc func get_track() -> Track {
        return self.track!
    }
    
    // TODO: add iterator protocol for each TrackPoint to abstract away from C array?
    
    /// Get current point (objc helper)
    @objc func get_current_point() -> TrackPoint {
        return self.track.current
    }
}
