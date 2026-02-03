//
//  C-Bridger.swift
//  quickly
//
//  Created by Aarav Gupta on 31/01/26.
//

import Foundation

public struct CBridger {
    public init() {}
    
    public func generateModuleMap(at root: URL, name: String) throws {
        let includePath = root.appending(component: "include")
        let moduleMapPath = includePath.appending(component: "module.modulemap")
        
        guard FileManager.default.fileExists(atPath: includePath.path()) else {
            print("No include directory found, skipping modulemap generation.")
            return
        }
        
        let content = """
            module \(name) {
                header "include/*.h"
                link "\(name)"
                export *
            }
            """
        
        try content.write(to: moduleMapPath, atomically: true, encoding: .utf8)
        print("Generated module.modulemap for \(name)")
    }
}
