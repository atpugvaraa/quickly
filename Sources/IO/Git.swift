//
//  Git.swift
//  quickly
//
//  Created by Aarav Gupta on 02/02/26.
//

import Foundation

public struct Git {
    public init() {}
    
    public enum GitError: Error {
        case executionFailed(String)
        case noTagsFound
    }

    /// Returns the latest SemVer tag (e.g. "1.5.0") or nil if none found
    public func detectLatestVersion(url: String) async throws -> String? {
        // ls-remote --tags lists all tags. We sort -V (version sort) to get the highest.
        // git ls-remote --tags --refs --sort='v:refname' <url>
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["ls-remote", "--tags", "--refs", "--sort=v:refname", url]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        let tags = output.split(separator: "\n").compactMap { line -> String? in
            guard let ref = line.split(separator: "\t").last else { return nil }
            return ref.replacingOccurrences(of: "refs/tags/", with: "")
                .replacingOccurrences(of: "^\\{}", with: "", options: .regularExpression)
        }
        
        let validTags = tags.filter { $0.first?.isNumber == true || $0.starts(with: "v") }
        
        return validTags.last
    }
    
    public func clone(url: String, to path: URL, version: String? = nil) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        
        var args = ["clone", "--depth", "1"]
        
        if let v = version {
            args.append(contentsOf: ["--branch", v])
        }
        
        args.append(contentsOf: [url, path.path()])
        
        process.arguments = args
        try process.run()
        process.waitUntilExit()
    }
}
