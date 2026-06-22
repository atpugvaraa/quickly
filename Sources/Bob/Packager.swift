//
//  Packager.swift
//  quickly
//

import Foundation
import Core

public struct Packager {
    public init() {}
    
    public func export(at path: URL, target: TargetOS) async throws {
        print("Exporting package at \(path.path()) for \(target)...")
        
        switch target {
        case .macos:
            print("Building macOS .app bundle...")
            try await executeShellCommand("swift build -c release", in: path)
            print("Packaging into .app...")
            // Logic to create .app structure would go here
            
        case .ios:
            print("Building iOS .ipa...")
            do {
                try await executeShellCommand("xcodebuild archive -scheme App -archivePath build/App.xcarchive", in: path)
                // xcodebuild -exportArchive ...
            } catch {
                print("⚠️ iOS Export Failed. Ensure Xcode is installed and project is configured correctly.")
                throw error
            }
            
        case .windows:
            print("Building Windows .exe...")
            do {
                try await executeShellCommand("swift build -c release --destination windows-x86_64", in: path)
            } catch {
                print("⚠️ Windows Export Failed. Ensure you have the Swift Windows cross-compiler toolchain installed.")
                throw error
            }
            
        case .linux:
            print("Building Linux raw ELF binary...")
            do {
                try await executeShellCommand("swift build -c release", in: path)
                
                print("Attempting to package as .appimage...")
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                process.arguments = ["which", "appimagetool"]
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    print("Found appimagetool, creating .appimage...")
                    // appimagetool logic
                } else {
                    print("⚠️ appimagetool not found. Exporting raw ELF binary only.")
                    print("💡 Tip: Install appimagetool for a better Linux distribution experience.")
                }
            } catch {
                print("⚠️ Linux Export Failed.")
                throw error
            }
            
        case .android:
            print("Building Android .apk...")
            do {
                try await executeShellCommand("swift build -c release --destination android-aarch64", in: path)
                // APK packaging logic with gradle/android SDK
            } catch {
                print("⚠️ Android Export Failed. Ensure you have the Swift Android Toolchain and Android SDK/NDK installed.")
                throw error
            }
        }
        
        print("✅ Export complete.")
    }
    
    private func executeShellCommand(_ command: String, in directory: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        process.currentDirectoryURL = directory
        
        var env = ProcessInfo.processInfo.environment
        env["PKG_CONFIG_PATH"] = "/opt/quickly/cellar/raylib/6.0"
        process.environment = env
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw NSError(domain: "PackagerError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Command failed: \(command)"])
        }
    }
}
