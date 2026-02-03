//
//  File.swift
//  quickly
//
//  Created by Aarav Gupta on 01/02/26.
//

import Foundation

public struct BrewFormula: Codable, Sendable, Identifiable {
    public let name: String
    public let desc: String
    public let homepage: String?
    public let versions: Versions
    public let urls: [String: URLInfo]?
    public let bottle: Bottle?
    public let dependencies: [String]
    public let recommended_dependencies: [String]?
    
    public var id: String { name }

    public struct Versions: Codable, Sendable {
        public let stable: String?
        public let head: String?
    }
    
    public struct URLInfo: Codable, Sendable {
        public let url: String?
        public let tag: String?
    }

    public struct Bottle: Codable, Sendable {
        public let stable: BottleBlock?
        
        public struct BottleBlock: Codable, Sendable {
            public let files: [String: BottleFile]
            
            public struct BottleFile: Codable, Sendable {
                public let url: String
                public let sha256: String
            }
        }
    }
}
