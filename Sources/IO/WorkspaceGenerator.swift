//
//  WorkspaceGenerator.swift
//  quickly
//
//  Created by Aarav Gupta on 03/02/26.
//

import Foundation

public struct WorkspaceGenerator {
    public init() {}
    
    public func generate(projectName: String, packages: [URL], at root: URL) throws {
        let workspacePath = root.appending(component: "\(projectName).xcworkspace")
        let dataPath = workspacePath.appending(component: "contents.xcworkspacedata")
        
        try FileManager.default.createDirectory(at: workspacePath, withIntermediateDirectories: true)
        
        // add the .xcodeproj itself
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Workspace version = "1.0">
           <FileRef location = "group:\(projectName).xcodeproj"></FileRef>
        """
        
        // add each package path
        for pkg in packages {
            xml += "\n   <FileRef location = \"absolute:\(pkg.path())\"></FileRef>"
        }
        
        xml += "\n</Workspace>"
        
        try xml.write(to: dataPath, atomically: true, encoding: .utf8)
        print("📝 Generated workspace at \(workspacePath.lastPathComponent)")
    }
}
