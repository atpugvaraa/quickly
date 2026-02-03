//
//  Installer.swift
//  quickly
//
//  Created by Aarav Gupta on 01/02/26.
//

import Foundation
import Core
import Bob

public actor Installer {
    private let catalog: CatalogService
    private let downloader: Downloader
    private let store: Store
    private let bridger: CBridger
    private let linker: Linker
    private let extractor: Extractor
    private let relocator: Relocator
    
    private var installedCache: Set<String> = []
    
    public init() {
        self.catalog = CatalogService()
        self.downloader = Downloader()
        self.store = Store()
        self.bridger = CBridger()
        self.linker = Linker()
        self.extractor = Extractor()
        self.relocator = Relocator()
    }
    
    public func install(package: String, isLib: Bool, isSPM: Bool) async throws {
        if isSPM {
            try await installSPM(package: package)
        } else {
            try await installBrew(package: package, shouldBridge: isLib)
        }
    }
    
    // MARK: - SPM Logic
    private func installSPM(package: String) async throws {
        let git = Git()
        
        print("Searching Swift Package Index for '\(package)'...")
        guard var swiftPkg = try await catalog.findSwiftPackage(query: package) else {
            print("Package '\(package)' not found in Swift Package Index.")
            return
        }
        
        print("Detecting latest version for \(swiftPkg.name)...")
        if let latestVersion = try? await git.detectLatestVersion(url: swiftPkg.url) {
            print("Found latest tag: \(latestVersion)")
            swiftPkg.version = latestVersion
        } else {
            print("No tags found, defaulting to HEAD.")
        }
        
        let versionDir = swiftPkg.version ?? "HEAD"
        
        let packagesRoot = URL(filePath: "/opt/quickly/packages")
        let installDir = packagesRoot.appending(path: "\(swiftPkg.name)/\(versionDir)")
        
        if FileManager.default.fileExists(atPath: installDir.path()) {
            print("Already installed at \(installDir.path())")
            return
        }
        
        print("Cloning source...")
        try FileManager.default.createDirectory(at: installDir.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        try git.clone(url: swiftPkg.url, to: installDir, version: swiftPkg.version)
        
        print("Installed \(swiftPkg.name) (\(versionDir))")
        print("Usage: \(swiftPkg.packageString())")
    }
    
    // MARK: - Brew Logic
    private func installBrew(package: String, shouldBridge: Bool) async throws {
        guard let formula = try await catalog.findBrew(name: package) else {
            print("Package \(package) not found in Homebrew catalog.")
            return
        }
        
        for dep in formula.dependencies {
            if !installedCache.contains(dep) {
                print("Resolving dependency: \(dep)")
                try await installBrew(package: dep, shouldBridge: false)
            }
        }
        
        if installedCache.contains(package) { return }
        
        print("Installing \(formula.name)...")
        
        if store.isInstalled(formula: formula) {
             print("Already installed.")
             let installDir = try store.path(for: formula)
             try linker.link(package: package, at: installDir)
             installedCache.insert(package)
             return
        }
        
        let system = SystemInfo.shared
        guard let bottle = formula.bottle?.stable?.files[system.bottleKey] ??
                           formula.bottle?.stable?.files["all"] ??
                           formula.bottle?.stable?.files.values.first
        else {
            print("No compatible bottle found for \(package).")
            return
        }
        
        var urlString = bottle.url
        if !urlString.hasPrefix("https") { urlString = "https://\(urlString)" }
        let casURL = try await downloader.download(url: URL(string: urlString)!, sha256: bottle.sha256)
        
        let installDir = try store.path(for: formula)
        try extractor.extract(file: casURL, to: installDir)
        
        try linker.link(package: package, at: installDir)
        
        try relocator.relocate(at: installDir)
        
        if shouldBridge {
            try bridger.generateModuleMap(at: installDir, name: package)
        }
        
        installedCache.insert(package)
        print("Installed \(package) v\(formula.versions.stable ?? "?")")
    }
}
