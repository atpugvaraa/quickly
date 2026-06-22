//
//  Main.swift
//  quickly
//
//  Created by Aarav Gupta on 31/01/26.
//

import ArgumentParser
import IO
import Core
import Bob
import Foundation

@main
struct quickly: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            abstract: "The lightning-fast package manager.",
            subcommands: [PackageCmd.self, Run.self, Export.self, Install.self, Add.self],
        )
    }
}

struct PackageCmd: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "package",
            abstract: "Manage Swift packages.",
            subcommands: [Init.self]
        )
    }
}

struct Init: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "init",
            abstract: "Scaffold a new QuickUI project."
        )
    }
    
    @Option(name: .shortAndLong, help: "Name of the project")
    var name: String?
    
    @Argument(help: "Path to scaffold the project in")
    var path: String?
    
    func run() async throws {
        let currentPath = FileManager.default.currentDirectoryPath
        let projectPath = path.map { URL(fileURLWithPath: $0) } ?? URL(fileURLWithPath: currentPath)
        
        let projectName = name ?? projectPath.lastPathComponent
        
        let scaffolder = Scaffolder()
        try await scaffolder.runInit(name: projectName, projectRoot: projectPath)
    }
}

struct Run: AsyncParsableCommand {
    @Argument(help: "Path to the local package")
    var path: String?
    
    @Flag(help: "Target OS to run on (e.g. --ios, --macos)")
    var target: TargetOS?
    
    func run() async throws {
        let packagePath = path.map { URL(fileURLWithPath: $0) } ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let resolvedTarget = target ?? SystemInfo.shared.hostOS
        
        let runner = Runner()
        try await runner.run(at: packagePath, target: resolvedTarget, hostOS: SystemInfo.shared.hostOS)
    }
}

struct Export: AsyncParsableCommand {
    @Argument(help: "Target OS to export for (macos, ios, android, windows, linux)")
    var target: TargetOS
    
    @Argument(help: "Path to the local package")
    var path: String?
    
    func run() async throws {
        let packagePath = path.map { URL(fileURLWithPath: $0) } ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        let packager = Packager()
        try await packager.export(at: packagePath, target: target)
    }
}

struct Install: AsyncParsableCommand {
    @Argument(help: "Package to install")
    var package: String
    
    // --lib: C-Lib
    @Flag(name: .customLong("lib"), help: "Install as a bridged C/C++ library")
    var isLib: Bool = false
    
    // --spm: Swift Package Mode
    @Flag(name: .customLong("spm"), help: "Install from Swift Package Index (Source)")
    var isSPM: Bool = false
    
    func run() async throws {
        if isLib && isSPM {
            print("Error: Cannot use --lib and --spm together.")
            return
        }
        
        let installer = Installer()
        
        do {
            try await installer.install(package: package, isLib: isLib, isSPM: isSPM)
        } catch {
            print("Error: \(error)")
        }
    }
}


struct Add: AsyncParsableCommand {
    func run() async throws {
        let fileManager = FileManager.default
        let currentPath = URL(filePath: fileManager.currentDirectoryPath)
        
        let manifest = try await parseManifest(at: currentPath)
        print("Found project: \(manifest.name)")
        
        let installedPaths = try await installDependencies(from: manifest)
        
        try await linkAndOpenProject(at: currentPath, installedPaths: installedPaths)
    }
    
    // MARK: - Helper Functions
    private func parseManifest(at path: URL) async throws -> ManifestParser.PackageInfo {
        let packageSwift = path.appending(component: "Package.swift")
        
        guard FileManager.default.fileExists(atPath: packageSwift.path()) else {
            print("No Package.swift found in current directory.")
            throw CleanExit.message("")
        }
        
        print("Parsing Package.swift...")
        let parser = ManifestParser()
        return try await parser.parse(at: path)
    }
    
    private func installDependencies(from manifest: ManifestParser.PackageInfo) async throws -> [URL] {
        let installer = Installer()
        var installedPaths: [URL] = []
        let packagesRoot = URL(filePath: "/opt/quickly/packages")
        
        for dep in manifest.dependencies {
            let pkgName = dep.url.split(separator: "/").last?.replacingOccurrences(of: ".git", with: "") ?? dep.url
            
            try await installer.install(package: dep.url, isLib: false, isSPM: true)
            
            let pkgDir = packagesRoot.appending(component: pkgName)
            if let versions = try? FileManager.default.contentsOfDirectory(at: pkgDir, includingPropertiesForKeys: nil),
               let best = versions.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }).first {
                installedPaths.append(best)
            }
        }
        
        return installedPaths
    }
    
    private func linkAndOpenProject(at path: URL, installedPaths: [URL]) async throws {
        let fileManager = FileManager.default
        
        guard let project = try? fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
            .first(where: { $0.pathExtension == "xcodeproj" })
        else {
            print("Packages installed globally. (No .xcodeproj found to link)")
            return
        }
        
        let name = project.deletingPathExtension().lastPathComponent
        print("Linking \(installedPaths.count) packages to \(name).xcodeproj via Workspace...")
        
        let generator = WorkspaceGenerator()
        try generator.generate(projectName: name, packages: installedPaths, at: path)
        
        print("Switching to \(name).xcworkspace...")
        let xcode = XcodeController()
        let projectPath = path.appending(component: "\(name).xcodeproj")
        let workspacePath = path.appending(component: "\(name).xcworkspace")
        
        xcode.closeProject(at: projectPath)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        xcode.open(at: workspacePath)
        
        print("✅ Done!")
    }
}
