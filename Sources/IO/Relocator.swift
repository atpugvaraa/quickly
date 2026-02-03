//
//  Relocator.swift
//  quickly
//
//  Created by Aarav Gupta on 03/02/26.
//

import Foundation

public struct Relocator {
    public init() {}
    
    public func relocate(at installDir: URL) throws {
        let fileManager = FileManager.default
        
        let binPath = installDir.appending(component: "bin")
        if fileManager.fileExists(atPath: binPath.path()) {
            let binaries = try fileManager.contentsOfDirectory(at: binPath, includingPropertiesForKeys: nil)
            for binary in binaries {
                if binary.lastPathComponent.hasPrefix(".") { continue }
                try patch(binary: binary)
            }
        }
        
        let libPath = installDir.appending(component: "lib")
        if fileManager.fileExists(atPath: libPath.path()) {
            let libs = try fileManager.contentsOfDirectory(at: libPath, includingPropertiesForKeys: nil)
            for lib in libs where lib.pathExtension == "dylib" {
                try patch(binary: lib)
            }
        }
    }
    
    private func patch(binary: URL) throws {
        let deps = try getDependencies(of: binary)
        var modified = false
        
        for oldPath in deps {
            if oldPath.contains("@@HOMEBREW_PREFIX@@") || oldPath.contains("/opt/homebrew") || oldPath.contains("/usr/local") {
                
                let filename = URL(fileURLWithPath: oldPath).lastPathComponent
                let newPath = "/opt/quickly/lib/\(filename)"
                
                if FileManager.default.fileExists(atPath: newPath) {
                    try changeInstallName(binary: binary, old: oldPath, new: newPath)
                    print("🩹 Relocated \(binary.lastPathComponent): \(filename)")
                    modified = true
                }
            }
        }
        
        if modified {
            try resign(binary: binary)
        }
    }
    
    private func getDependencies(of binary: URL) throws -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/otool")
        process.arguments = ["-L", binary.path()]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return output.split(separator: "\n")
            .dropFirst()
            .compactMap { line in
                let parts = line.trimmingCharacters(in: .whitespaces).split(separator: " ")
                return parts.first.map(String.init)
            }
    }
    
    private func changeInstallName(binary: URL, old: String, new: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/install_name_tool")
        process.arguments = ["-change", old, new, binary.path()]
        
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binary.path())
        try process.run()
        process.waitUntilExit()
    }
    
    private func resign(binary: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["--force", "--sign", "-", binary.path()]
        
        try process.run()
        process.waitUntilExit()
        print("Re-signed \(binary.lastPathComponent)")
    }
}
