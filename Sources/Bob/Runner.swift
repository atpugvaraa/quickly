//
//  Runner.swift
//  quickly
//

import Foundation
import Core

public struct Runner {
    public init() {}
    
    public func run(at path: URL, target: TargetOS, hostOS: TargetOS) async throws {
        
        if target == hostOS {
            print("Running natively on \(hostOS)...")
            try await executeShellCommand("swift run", in: path)
            return
        }
        
        switch target {
        case .ios:
            print("Running for iOS Simulator...")
            print("Building with xcodebuild...")
            // Provide a stub command but warn the user if it fails
            do {
                // Example of what we'd do, in reality we'd need project name and scheme
                // For now, we will just print instructions if xcodebuild fails.
                print("Note: This assumes an iOS-compatible Package or xcodeproj exists in the directory.")
                try await executeShellCommand("xcodebuild -scheme App -destination 'generic/platform=iOS Simulator' build", in: path)
                print("Install and launch via xcrun simctl will happen here.")
            } catch {
                print("⚠️ iOS Run Failed. Ensure you have Xcode installed and the project is configured for iOS.")
                throw error
            }
            
        case .android:
            print("Running for Android Emulator...")
            do {
                try await executeShellCommand("swift build --destination android-aarch64", in: path)
                print("ADB install and launch will happen here.")
            } catch {
                print("⚠️ Android Run Failed. Ensure you have the Swift Android Toolchain and Android SDK/NDK installed.")
                print("See: https://github.com/swiftlang/swift/blob/main/docs/Android.md")
                throw error
            }
            
        case .macos, .windows, .linux:
            print("Cannot natively run \(target) on \(hostOS). Please export instead or use a VM/Docker.")
        }
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
            throw NSError(domain: "RunnerError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Command failed: \(command)"])
        }
    }
}
