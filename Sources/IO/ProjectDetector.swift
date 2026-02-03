//
//  ProjectDetector.swift
//  quickly
//
//  Created by Aarav Gupta on 03/02/26.
//

import Foundation

public struct ProjectDetector {
    public init() {}
    
    public enum ProjectType {
        case xcodeproj(String)
        case xcworkspace(String)
        case package(String)
    }
    
    public func detect(at path: URL = URL(filePath: FileManager.default.currentDirectoryPath)) -> ProjectType? {
        let fileManager = FileManager.default
        
        if let workspace = try? fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: nil).first(where: { $0.pathExtension == "xcworkspace"}) {
            let name = workspace.deletingPathExtension().lastPathComponent
            return .xcworkspace(name)
        }
        
        if let project = try? fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: nil).first(where: { $0.pathExtension == "xcodeproj"}) {
            let name = project.deletingPathExtension().lastPathComponent
            return .xcodeproj(name)
        }
        
        let package = path.appending(component: "Package.swift")
        if fileManager.fileExists(atPath: package.path()) {
            return .package(path.lastPathComponent)
        }
        
        return nil
    }
}
