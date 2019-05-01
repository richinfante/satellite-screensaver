//
//  GeoJSON.swift
//  satellite-saver-2
//
//  Created by Rich Infante on 4/25/19.
//  Copyright © 2019 Rich Infante. All rights reserved.
//

import Foundation

/// Collection of GeoJSON Features
@objcMembers class GeoJSONCollection : NSObject, Codable {
    var type: String
    var features: [GeoJSONFeature]
    var bbox: [Float32]
    
    override init() {
        self.type = "Fake"
        self.features = []
        self.bbox = []
    }
}

/// GeoJSON Feature Properites
@objcMembers class GeoJSONProperties : NSObject, Codable {
    var scalerank: Float32
    var featurecla: String
    var min_zoom: Float32
}

/// GeoJSON Geometry
@objcMembers class GeoJSONGeometry : NSObject, Codable {
    var type: String
    var coordinates: [[Float32]]
}

extension GeoJSONGeometry {
    /// Helper: find NSPoint at index (they're stored as arrays).
    @objc func point_at(index: Int) -> NSPoint {
        return NSPoint(x: CGFloat(self.coordinates[index][0]), y: CGFloat(self.coordinates[index][1]))
    }
}

/// GeoJSON Feature
@objcMembers class GeoJSONFeature :NSObject,  Codable {
    var type: String
    var properties: GeoJSONProperties
    var bbox: [Float32]
    var geometry:GeoJSONGeometry
}

extension GeoJSONCollection {
    /// Get the GeoJSON for the world.
    @objc static func world_geo() -> GeoJSONCollection {
        // Get the bundle
        let bundle = Bundle.init(for: self)
        
        // Get file url for the geojson
        guard let geojson = bundle.url(forResource: "world", withExtension: "json") else {
            return GeoJSONCollection()
        }
        
        // Get the data inside the json
        guard let data = try? Data(contentsOf: geojson) else {
            return GeoJSONCollection()
        }
        
        // Try decoding it.
        guard let res = try? JSONDecoder().decode(GeoJSONCollection.self, from: data) else {
            return GeoJSONCollection()
        }
        
        return res
    }
}
