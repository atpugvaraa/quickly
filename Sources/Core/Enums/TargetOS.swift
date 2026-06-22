//
//  TargetOS.swift
//  quickly
//

import ArgumentParser

public enum TargetOS: String, Codable, ExpressibleByArgument, Sendable, EnumerableFlag {
    case macos
    case ios
    case android
    case windows
    case linux
}
