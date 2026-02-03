//
//  DerivedDataLinker.swift
//  quickly
//
//  Created by Aarav Gupta on 03/02/26.
//

import Foundation

public struct PackageLinker {
    private let fileManager = FileManager.default
    private let packagesPath = URL(filePath: "/opt/quickly/packages")
    
    public init() {}
    
    public func addPackage(projectName: String) throws {
        let home = fileManager.homeDirectoryForCurrentUser
        let derivedDataRoot = home.appending(path: "Library/Developer/Xcode/DerivedData")
        
        guard fileManager.fileExists(atPath: derivedDataRoot.path()) else {
            print("DerivedData not found at \(derivedDataRoot.path())")
            return
        }
        
        let contents = try fileManager.contentsOfDirectory(at: derivedDataRoot, includingPropertiesForKeys: [.contentModificationDateKey])
        
        let candidates = contents.filter { $0.lastPathComponent.starts(with: projectName + "-") }
        
        guard let targetProjectDir = candidates.sorted(by: {
            let date1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            let date2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            return date1 > date2
        }).first else {
            print("No DerivedData folder found for project '\(projectName)'. Have you built it yet?")
            return
        }
        
        print("Found Project Build: \(targetProjectDir.lastPathComponent)")
        
        // Xcode standard path: DerivedData/<Project>/SourcePackages/checkouts
        let checkoutsDir = targetProjectDir.appending(path: "SourcePackages/checkouts")
        
        try fileManager.createDirectory(at: checkoutsDir, withIntermediateDirectories: true)
        
        if !fileManager.fileExists(atPath: packagesPath.path()) {
            print("No global packages found in \(packagesPath.path())")
            return
        }
        
        let globalPackages = try fileManager.contentsOfDirectory(at: packagesPath, includingPropertiesForKeys: nil)
        
        for pkg in globalPackages {
            if pkg.lastPathComponent.hasPrefix(".") { continue }
            
            let versions = try fileManager.contentsOfDirectory(at: pkg, includingPropertiesForKeys: nil)
            guard let bestVersion = versions.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }).first else { continue }
            
            let linkName = pkg.lastPathComponent
            let destination = checkoutsDir.appending(component: linkName)
            
            if fileManager.fileExists(atPath: destination.path()) {
                try fileManager.removeItem(at: destination)
            }
            
            try fileManager.createSymbolicLink(at: destination, withDestinationURL: bestVersion)
            print("Injected \(linkName) (\(bestVersion.lastPathComponent))")
        }
    }
}
