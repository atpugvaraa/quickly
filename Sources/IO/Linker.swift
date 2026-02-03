//
//  Linker.swift
//  quickly
//
//  Created by Aarav Gupta on 02/02/26.
//

import Foundation
import Core

public struct Linker {
    private let binPath = URL(filePath: "/opt/quickly/bin")
    private let libPath = URL(filePath: "/opt/quickly/lib")
    private let fileManager = FileManager.default
    
    public init() {}
    
    public func link(package: String, at installDir: URL) throws {
        try linkFolder(from: installDir.appending(component: "bin"), to: binPath)
        try linkFolder(from: installDir.appending(component: "lib"), to: libPath)
    }
    
    private func linkFolder(from source: URL, to destination: URL) throws {
        guard fileManager.fileExists(atPath: source.path()) else { return }
        
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        
        let contents = try fileManager.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
        
        for item in contents {
            if item.lastPathComponent.hasPrefix(".") { continue }
            
            let targetLink = destination.appending(component: item.lastPathComponent)
            
            if fileManager.fileExists(atPath: targetLink.path()) {
                try fileManager.removeItem(at: targetLink)
            }
            
            try fileManager.createSymbolicLink(at: targetLink, withDestinationURL: item)
            print("Linked \(item.lastPathComponent)")
        }
    }
}
