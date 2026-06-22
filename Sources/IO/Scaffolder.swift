//
//  Initializer.swift
//  quickly
//

import Core
import Foundation

public struct RaylibPlatform {
    public let assetURL: URL
    public let sha256: String
    public let linkerSettings: String

    public static func current() -> RaylibPlatform {
        let os = SystemInfo.shared.hostOS
        switch os {
        case .macos:
            return RaylibPlatform(
                assetURL: URL(
                    string:
                        "https://github.com/raysan5/raylib/releases/download/6.0/raylib-6.0_macos.tar.gz"
                )!,
                sha256: "6ae5947fbd36aee4c280e3a2b3e1893316c433e292bda6e94e0f2b037498ad70",
                linkerSettings: """
                    linkerSettings: [
                        .linkedLibrary("raylib"),
                        .linkedFramework("Cocoa"),
                        .linkedFramework("OpenGL"),
                        .linkedFramework("IOKit"),
                        .linkedFramework("CoreVideo"),
                        .unsafeFlags(["-LSources/Raylib/lib"])
                    ]
                    """
            )
        case .linux:
            // TODO: linux mapping
            fatalError("Linux scaffolding not implemented yet.")
        case .windows:
            // TODO: windows mapping
            fatalError("Windows scaffolding not implemented yet.")
        case .ios, .android:
            fatalError(
                "Scaffolding directly for mobile OS not supported. Scaffold for desktop and export to mobile."
            )
        }
    }
}

extension RaylibPlatform {
    public static func forMacOS6_0() -> RaylibPlatform {
        return RaylibPlatform(
            assetURL: URL(string: "https://github.com/raysan5/raylib/releases/download/6.0/raylib-6.0_macos.tar.gz")!, 
            sha256: "6ae5947fbd36aee4c280e3a2b3e1893316c433e292bda6e94e0f2b037498ad70",
            linkerSettings: """
                linkerSettings: [
                    .linkedLibrary("raylib"),
                    .linkedFramework("Cocoa"),
                    .linkedFramework("OpenGL"),
                    .linkedFramework("IOKit"),
                    .linkedFramework("CoreVideo"),
                    .unsafeFlags(["-LSources/Raylib/lib"])
                ]
                """
        )
    }
}

public struct Scaffolder {
    private let fileManager = FileManager.default
    private let raylibVersion = "6.0"
    private var cellarRaylibPath: URL {
        URL(fileURLWithPath: "/opt/quickly/cellar/raylib/\(raylibVersion)")
    }

    public init() {}

    public func runInit(name: String, projectRoot: URL) async throws {
        print("Initializing QuickUI project '\(name)'...")

        let platform = RaylibPlatform.current()

        // Step 1: Ensure Raylib is in the cellar
        try await ensureRaylibInCellar(platform: platform)

        // Step 2: Scaffold the project tree
        let sourcesDir = projectRoot.appending(component: "Sources")
        let mainTargetDir = sourcesDir.appending(component: name)
        
        try fileManager.createDirectory(at: mainTargetDir, withIntermediateDirectories: true)
        
        // Step 3: Generate Package.swift
        let packageSwift = generatePackageSwift(name: name, linkerSettings: platform.linkerSettings)
        try packageSwift.write(
            to: projectRoot.appending(component: "Package.swift"), atomically: true, encoding: String.Encoding.utf8
        )

        // Step 6: Generate main.swift
        let mainSwift = """
            import Raylib

            InitWindow(800, 600, "Hello from QuickUI!")
            SetTargetFPS(60)

            while !WindowShouldClose() {
                BeginDrawing()
                ClearBackground(Color(r: 245, g: 245, b: 245, a: 255))
                DrawText("Hello from QuickUI!", 20, 20, 20, Color(r: 0, g: 0, b: 0, a: 255))
                EndDrawing()
            }

            CloseWindow()
            """
        try mainSwift.write(
            to: mainTargetDir.appending(component: "main.swift"), atomically: true, encoding: String.Encoding.utf8)

        // Step 7: Print next steps
        print("✅ Project '\(name)' scaffolded successfully.")
        print("Next steps:")
        print("  cd \(name)")
        print("  ql run")
    }

    private func ensureRaylibInCellar(platform: RaylibPlatform) async throws {
        let includePath = cellarRaylibPath.appending(component: "include").appending(component: "raylib.h")
        let libPath = cellarRaylibPath.appending(component: "lib").appending(component: "libraylib.a")
        let pcPath = cellarRaylibPath.appending(component: "raylib.pc")

        if fileManager.fileExists(atPath: includePath.path())
            && fileManager.fileExists(atPath: libPath.path())
            && fileManager.fileExists(atPath: pcPath.path())
        {
            print("Raylib \(raylibVersion) found in cellar.")
            return
        }

        print("Raylib \(raylibVersion) not found or incomplete in cellar. Downloading...")
        let downloader = Downloader()
        let downloadedTarball = try await downloader.download(
            url: platform.assetURL, sha256: platform.sha256)

        print("Extracting Raylib...")
        let extractor = Extractor()
        // Raylib tarballs generally have 1 root component
        try extractor.extract(file: downloadedTarball, to: cellarRaylibPath, stripComponents: 1)
        
        // Remove .dylib to force static linking
        if let libs = try? fileManager.contentsOfDirectory(atPath: libPath.deletingLastPathComponent().path()) {
            for lib in libs {
                if lib.hasSuffix(".dylib") || lib.contains(".dylib.") {
                    try? fileManager.removeItem(at: libPath.deletingLastPathComponent().appending(component: lib))
                }
            }
        }

        // Generate raylib.pc
        let pcContent = """
        prefix=\(cellarRaylibPath.path())
        includedir=${prefix}/include
        libdir=${prefix}/lib

        Name: raylib
        Description: Raylib library
        Version: \(raylibVersion)
        Cflags: -I${includedir}
        Libs: -L${libdir} -lraylib -framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo
        """
        try pcContent.write(to: pcPath, atomically: true, encoding: String.Encoding.utf8)

        // Ensure the expected files exist after extraction
        if !fileManager.fileExists(atPath: includePath.path())
            || !fileManager.fileExists(atPath: libPath.path())
        {
            print(
                "⚠️ Warning: Extraction finished but expected include/lib paths were not found in cellar."
            )
        }
    }

    private func copyRaylibToProject(raylibTargetDir: URL) throws {
        let cellarInclude = cellarRaylibPath.appending(component: "include")
        let cellarLib = cellarRaylibPath.appending(component: "lib")

        let targetInclude = raylibTargetDir.appending(component: "include")
        let targetLib = raylibTargetDir.appending(component: "lib")

        // Copy headers
        if let headers = try? fileManager.contentsOfDirectory(atPath: cellarInclude.path()) {
            for header in headers where header.hasSuffix(".h") {
                let src = cellarInclude.appending(component: header)
                let dst = targetInclude.appending(component: header)
                if !fileManager.fileExists(atPath: dst.path()) {
                    try fileManager.copyItem(at: src, to: dst)
                }
            }
        }

        // Copy static library ONLY
        if let libs = try? fileManager.contentsOfDirectory(atPath: cellarLib.path()) {
            for lib in libs {
                if lib.hasSuffix(".dylib") || lib.contains(".dylib.") {
                    continue  // Skip all dynamic libraries
                }
                if lib == "libraylib.a" {
                    let src = cellarLib.appending(component: lib)
                    let dst = targetLib.appending(component: lib)
                    if !fileManager.fileExists(atPath: dst.path()) {
                        try fileManager.copyItem(at: src, to: dst)
                    }
                }
            }
        }
    }

    private func generatePackageSwift(name: String, linkerSettings: String) -> String {
        let quickUIDependency: String
        if let localPath = ProcessInfo.processInfo.environment["QUICKUI_LOCAL_PATH"] {
            quickUIDependency = ".package(path: \"\(localPath)\")"
        } else {
            quickUIDependency =
                ".package(url: \"https://github.com/atpugvaraa/QuickUI.git\", branch: \"main\")"
        }

        return """
            // swift-tools-version: 6.0
            import PackageDescription

            let package = Package(
                name: "\(name)",
                platforms: [.macOS(.v14)],
                dependencies: [
                    \(quickUIDependency)
                ],
                targets: [
                    .executableTarget(
                        name: "\(name)",
                        dependencies: [
                            .product(name: "QuickUI", package: "QuickUI")
                        ],
                        path: "Sources/\(name)"
                    )
                ]
            )
            """
    }
}
