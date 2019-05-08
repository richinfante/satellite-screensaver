//
//  GroundStation.swift
//  satellite-saver-2
//
//  Created by Rich Infante on 5/2/19.
//  Copyright © 2019 Rich Infante. All rights reserved.
//

import Foundation

@objcMembers class GroundStation : NSObject, Codable {
    var latitude: Double
    var longitude: Double
    var title: String?
    var color: String?
    var pointSize: Float?
    var fontSize: Float?
    

    /// Initialize a ground station object from JSON data
    static func fromJSON(data: Data) -> Array<GroundStation>? {
        // Try decoding it.
        guard let res = try? JSONDecoder().decode(Array<GroundStation>.self, from: data) else {
            return nil
        }
        
        return res
    }

    func getFontSize(defaultSize: Float) -> Float {
        if let size = self.fontSize {
            return size
        }
        
        return defaultSize
    }
    
    
    func getPointSize(defaultSize: Float) -> Float {
        if let size = self.pointSize {
            return size
        }
        
        return defaultSize
    }
    
    /// Get the color for display, given the default.
    func getColor(defaultColor: NSColor) -> NSColor {
        if let hexColor = self.color {
            return NSColor(hex: hexColor)
        }
        
        return defaultColor
    }
    
    /// Get an NSPoint with latitude and longitude
    func getCoords() -> NSPoint {
        return NSMakePoint(CGFloat(self.longitude), CGFloat(self.latitude))
    }
}

/// Ground Station Mode
@objc enum GroundStationMode : Int {
    case disabled = 0
    case staticJSON = 1
    case dynamicURL = 2
}

/// Delegate protocol providing settings for fetching and data
@objc protocol GroundStationProviderDelegate {
    func getGroundStationMode() -> GroundStationMode
    func getStaticGroundStations() -> Data?
    func getDynamicGroundStationsURL() -> URL?
}

@objcMembers class GroundStationProvider : NSObject {
    var delegate: GroundStationProviderDelegate?
    var stations: [GroundStation]? = nil
    
    /// Purge all cached stations from memory.
    func purge() {
        self.stations = nil
    }

    /// Get a list of the current ground stations
    func getStations() -> [GroundStation] {
        if let stations = self.stations {
            return stations
        }

        guard let delegate = self.delegate else { return [] }
        
        switch delegate.getGroundStationMode() {
        case .staticJSON:
            // Get static stations list
            guard let data = delegate.getStaticGroundStations() else { return [] }
            
            // Parse the returned data
            guard let result = GroundStation.fromJSON(data: data) else { return [] }
            
            // Assign stations to self
            self.stations = result
            
            return result
        case .dynamicURL:
            
            // Get url to fetch stations from
            guard let url = delegate.getDynamicGroundStationsURL() else { return [] }
            
            // Launch a task.
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                
                // No data? return.
                guard let data = data else { return }
                
                // Parse result
                guard let result = GroundStation.fromJSON(data: data) else { return }
                
                // Set flags.
                DispatchQueue.main.async {
                    self.stations = result
                }
            }
            
            task.resume()
            return []
        case .disabled:
            return []
        }
    
    }
}
