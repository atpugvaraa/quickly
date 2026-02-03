//
//  XcodeController.swift
//  quickly
//
//  Created by Aarav Gupta on 03/02/26.
//


import Foundation

public struct XcodeController {
    public init() {}
    
    public func closeProject(at path: URL) {
        let script = """
        tell application "Xcode"
            try
                close (every workspace document whose path is "\(path.path())")
            end try
        end tell
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
        process.waitUntilExit()
    }
    
    public func open(at path: URL) {
        print("Launching \(path.lastPathComponent)...")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [path.path()]
        try? process.run()
        process.waitUntilExit()
    }
}
