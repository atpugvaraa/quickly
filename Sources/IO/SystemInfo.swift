//
//  SystemInfo.swift
//  quickly
//
//  Created by Aarav Gupta on 01/02/26.
//

import Foundation

public struct SystemInfo: Sendable {
    static let shared = SystemInfo()
    
    public let os: String
    public let arch: String
    
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
    }
    
    private static func macOSVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        
        switch version.majorVersion {
        case 26: return "tahoe"
        case 15: return "sequoia"
        case 14: return "sonoma"
        case 13: return "ventura"
        case 12: return "monterey"
        case 11: return "big_sur"
        default:
            print("Unknown macOS version \(version.majorVersion), defaulting to sequoia.")
            return "sequoia"
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
