//
//  AppDelegate.swift
//  satellite-viewer
//
//  Created by Rich Infante on 12/9/19.
//  Copyright © 2019 Rich Infante. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func showPreferences(sender: AnyObject?) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PreferencesOpenClicked"), object: nil)
    }

}

