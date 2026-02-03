//
//  Extractor.swift
//  quickly
//
//  Created by Aarav Gupta on 31/01/26.
//

import Foundation

public struct Extractor {
    public init() {}
    
    public enum ExtractorError: Error {
        case executionFailed(String)
    }
    
    public func extract(file: URL, to destination: URL) throws {
        if !FileManager.default.fileExists(atPath: destination.path()) {
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        }
        
        print("Extracting to \(destination.path())...")
        
        // -x: extract
        // -f: file
        // -C: change directory (extract INTO this dir)
        // --strip-components 1: removes the root folder (usually "wget-1.21/") so files sit flat
        let tarballProcess = Process()
        tarballProcess.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        tarballProcess.arguments = ["-xf", file.path(), "-C", destination.path(), "--strip-components=2"]
        
        let pipe = Pipe()
        tarballProcess.standardOutput = pipe
        
        try tarballProcess.run()
        tarballProcess.waitUntilExit()
        
        let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
        let errorMsg = String(data: errorData, encoding: .utf8) ?? ""
        
        guard tarballProcess.terminationStatus == 0 else {
            throw ExtractorError.executionFailed("Tar failed (code \(tarballProcess.terminationStatus)): \(errorMsg)")
        }
    }
}
