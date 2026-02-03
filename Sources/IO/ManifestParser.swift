//
//  ManifestParser.swift
//  quickly
//
//  Created by Aarav Gupta on 03/02/26.
//

import Foundation

public struct ManifestParser {
    public init() {}
    
    public struct PackageInfo: Decodable {
        public let name: String
        public let dependencies: [Dependency]
        
        public struct Dependency: Decodable {
            public let url: String
            public let requirement: Requirement?
        }
        
        public struct Requirement: Decodable {
            public let range: [LowerBound]?
            public let exact: [String]?
            public let branch: [String]?
            public let revision: [String]?
            
            public struct LowerBound: Decodable {
                public let lowerBound: String
            }
        }
    }
    
    public func parse(at url: URL) async throws -> PackageInfo {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["package", "dump-package", "--package-path", url.path()]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return try JSONDecoder().decode(PackageInfo.self, from: data)
    }
}
