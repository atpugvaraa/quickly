//
//  SwiftPackage.swift
//  quickly
//
//  Created by Aarav Gupta on 01/02/26.
//

import Foundation

public enum Branch: String, Sendable {
    case main = "main"
    case master = "master"
    case unstable = "HEAD"
}

public struct SwiftPackage: Codable, Sendable, Identifiable {
    public let url: String
    public var version: String?
    
    public var id: String { return name }
    
    public var name: String {
        // github.com/owner/name.git -> name
        return url.split(separator: "/").last?
            .replacingOccurrences(of: ".git", with: "") ?? url
    }
    
    public init(url: String, version: String? = nil) {
        self.url = url
        self.version = version
    }
    
    // MARK: - Code Generation Helpers
    public func packageString(branch: Branch = .main) -> String {
        if let version = version {
            return ".package(url: \"\(url)\", from: \"\(version)\")"
        } else {
            return ".package(url: \"\(url)\", branch: \"\(branch)\")"
        }
    }
    
    public var product: String {
        let cleanName = name
            .split(separator: "-")
            .map { $0.prefix(1).capitalized + $0.dropFirst() }
            .joined()
        return ".product(name: \"\(cleanName)\", package: \"\(name)\")"
    }
}
