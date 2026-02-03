//
//  Store.swift
//  quickly
//
//  Created by Aarav Gupta on 31/01/26.
//

import Foundation
import Core

public struct Store {
    private let fileManager = FileManager.default
    private let cellarPath = URL(filePath: "/opt/quickly/cellar")
    
    public init() {}
    
    /// Returns the target directory for a specific formula version
    public func path(for formula: BrewFormula) throws -> URL {
        guard let version = formula.versions.stable else {
            throw PackageError.versionNotFound
        }
        
        return cellarPath
            .appending(component: formula.name)
            .appending(component: version)
    }
    
    /// Checks if a package is already installed
    public func isInstalled(formula: BrewFormula) -> Bool {
        guard let path = try? path(for: formula) else { return false }
        return fileManager.fileExists(atPath: path.path())
    }
}
