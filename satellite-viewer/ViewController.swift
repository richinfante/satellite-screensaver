//
//  ViewController.swift
//  satellite-viewer
//
//  Created by Rich Infante on 12/9/19.
//  Copyright © 2019 Rich Infante. All rights reserved.
//

import Cocoa
import Foundation
import CocoaLumberjack

class ViewController: NSViewController {
    
    var ssview: satellite_saver_2View! = nil
    var configWindow : NSWindow? = nil
    var renderTimer : Timer! = nil
    
    /// Entry point for the view controller
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set window titles & behavior
        self.title = "Satellite Tracker"
        self.window?.title = "Satellite Tracker"
        self.window?.standardWindowButton(.closeButton)?.isEnabled = false

        // Attach the screensaver to the view
        self.ssview = self.view as? satellite_saver_2View
        
        // If it fails, print error.
        if ssview == nil {
            print("Failed to setup ssview as screen saver")
        }
        
        // NOTE: optional. We need some setup methods to load our screensaver.
        self.ssview.setup();
        
        // Schedule a timer
        self.renderTimer = Timer.scheduledTimer(timeInterval: self.ssview.animationTimeInterval, target: self, selector: #selector(self.renderTick), userInfo: nil, repeats: true)

        // Recieve notifications from the parent window if the preferences needs to be opened.
        NotificationCenter.default.addObserver(self, selector: #selector(self.showPrefs(_:) ), name: NSNotification.Name(rawValue: "PreferencesOpenClicked"), object: nil);
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    /// Perform a render tick of the screensaver
    @objc func renderTick() {
        DispatchQueue.main.async {
            self.ssview.setNeedsDisplay(self.ssview.bounds)
        }
    }

    /// Get this view controller's window
    var window : NSWindow? {
        return NSApplication.shared.windows[0]
    }

    /// Present preferences window
    @objc func showPrefs(_ sender: AnyObject?) {
        self.configWindow = self.ssview.configureSheet
        self.window?.beginSheet(self.configWindow!, completionHandler: nil)
    }
}

