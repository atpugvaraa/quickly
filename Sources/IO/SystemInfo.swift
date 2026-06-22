//
//  SystemInfo.swift
//  quickly
//
//  Created by Aarav Gupta on 01/02/26.
//

import Foundation
import Core

public struct SystemInfo: Sendable {
    public static let shared = SystemInfo()
    
    public let os: String
    public let arch: String
    public let hostOS: TargetOS
    
    // Homebrew uses (e.g., "arm64_sequoia" or "sonoma") in the JSON
    public var bottleKey: String {
        if arch == "arm64" {
            return "arm64_\(os)"
        } else {
            return os
        }
    }
    
    private init() {
        self.os = Self.macOSVersion()
        self.arch = Self.getArch()
        self.hostOS = Self.detectHostOS()
    }
    
    private static func detectHostOS() -> TargetOS {
        #if os(macOS)
        return .macos
        #elseif os(Linux)
        return .linux
        #elseif os(Windows)
        return .windows
        #else
        fatalError("Unsupported host operating system")
        #endif
    }
    
    private static func macOSVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        
        switch version.majorVersion {
        case 26: return "tahoe"
        case 15: return "sequoia"
        case 14: return "sonoma"
        default:
            print("Unknown macOS version \(version.majorVersion), defaulting to sonoma.")
            return "sonoma"
        }
    }
    
    private static func getArch() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8,
                    value != 0 else { return identifier }
            let sanitisedValue = String(UnicodeScalar(UInt8(value)))
            
            return identifier + sanitisedValue
        }
        
        return identifier == "x86_64" ? "x86_64" : "arm64"
    }
}
