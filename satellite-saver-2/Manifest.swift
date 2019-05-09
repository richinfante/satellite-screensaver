//
//  Manifest.swift
//  satellite-saver-2
//
//  Created by Rich Infante on 4/30/19.
//  Copyright © 2019 Rich Infante. All rights reserved.
//

import Foundation
import CocoaLumberjack

@objcMembers class DeploymentManifest : NSObject, Codable {
    
    /// Latest Build Number
    var latestBuild: Int?
    
    /// Update URL
    var updateUrl: String?
    
    override init() {
        super.init()
    }
    
    private enum CodingKeys: String, CodingKey {
        case latestBuild
        case updateUrl
    }
    
    /// Get a string representing the latest build.
    func latestBuildString() -> String {
        if let latestBuild = latestBuild {
            return "\(latestBuild)"
        } else {
            return "Unknown"
        }
    }
    
    /// Check if the bundle needs an update.
    func needsUpdate () -> Bool {
        // Get bundle for screensaver.
        let bundle = Bundle.init(for: DeploymentManifest.self)
        
        // Load build number from the info.plist
        guard let currentBuildString = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
            return false
        }

        // Try to parse build into integer
        guard let currentBuild = Int(currentBuildString, radix: 10) else {
            return false
        }
        
        // If we don't have a latest build number from the manifest, end.
        guard let latestBuild = self.latestBuild else {
            return false
        }
        
        // If the build is less than latest, say we have updates.
        if currentBuild < latestBuild {
            return true
        }
        
        // No updates needed!
        return false
    }
    
    /// Initialize the deployment manifest from a URL
    static func initFromUrl(url: URL, completion: @escaping (DeploymentManifest?)->()) {
        DDLogInfo("Loading manifest from \(url)")

        // Launch a task.
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            // Log error info
            if let error = error {
                DDLogError("Failed to laod manifest \(error.localizedDescription)")
            }
            
            // If data is nil, fail.
            guard let data = data else {
                return completion(nil)
            }
            
            // Try decoding it.
            guard let res = try? JSONDecoder().decode(DeploymentManifest.self, from: data) else {
                return completion(nil)
            }

            // Send the new manifest
            completion(res)
        }
        
        task.resume()
    }
}
