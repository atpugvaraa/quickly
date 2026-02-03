//
//  CatalogService.swift
//  quickly
//
//  Created by Aarav Gupta on 31/01/26.
//

import Core
import Foundation

public actor CatalogService {
    public let client = NetworkClient()
    private let fileManager = FileManager.default
    
    private let cachePath = URL(filePath: "/opt/quickly/cache")
    private let brewURL = URL(string: "https://formulae.brew.sh/api/formula.json")!
    private let spiURL = URL(string: "https://raw.githubusercontent.com/SwiftPackageIndex/PackageList/main/packages.json")!
    
    // Caches
    private var brewCache: [BrewFormula]?
    private var spiCache: [SwiftPackage]?
    
    public init() {}
    
    // MARK: - Homebrew Logic
    public func indexFormulas() async throws -> [BrewFormula] {
        if let cache = brewCache { return cache }
        
        let localCache = cachePath.appending(component: "formula.json")
        if fileManager.fileExists(atPath: localCache.path()) {
            let data = try Data(contentsOf: localCache)
            let formulas = try JSONDecoder().decode([BrewFormula].self, from: data)
            self.brewCache = formulas
            return formulas
        }
        return try await reindexBrew()
    }
    
    func reindexBrew() async throws -> [BrewFormula] {
        print("🌍 Fetching Homebrew Catalog...")
        let (data, _) = try await client.session.data(from: brewURL)
        try fileManager.createDirectory(at: cachePath, withIntermediateDirectories: true)
        try data.write(to: cachePath.appending(component: "formula.json"))
        let formulas = try JSONDecoder().decode([BrewFormula].self, from: data)
        self.brewCache = formulas
        return formulas
    }
    
    // MARK: - SPI Logic (New)
    public func indexSPI() async throws -> [SwiftPackage] {
        if let cache = spiCache { return cache }
        
        let localCache = cachePath.appending(component: "spi.json")
        if fileManager.fileExists(atPath: localCache.path()) {
            let data = try Data(contentsOf: localCache)
            let urls = try JSONDecoder().decode([String].self, from: data)
            let packages = urls.map { SwiftPackage(url: $0) }
            self.spiCache = packages
            return packages
        }
        return try await reindexSwiftPackage()
    }
    
    func reindexSwiftPackage() async throws -> [SwiftPackage] {
        print("Fetching Swift Package Index...")
        let (data, _) = try await client.session.data(from: spiURL)
        try fileManager.createDirectory(at: cachePath, withIntermediateDirectories: true)
        try data.write(to: cachePath.appending(component: "spi.json"))
        
        let urls = try JSONDecoder().decode([String].self, from: data)
        let packages = urls.map { SwiftPackage(url: $0) }
        self.spiCache = packages
        return packages
    }
    
    // MARK: - Search
    public func findBrew(name: String) async throws -> BrewFormula? {
        let formulas = try await indexFormulas()
        return formulas.first { $0.name == name }
    }
    
    public func findSwiftPackage(query: String) async throws -> SwiftPackage? {
        let packages = try await indexSPI()
        return packages.first { $0.name.lowercased() == query.lowercased() }
    }
}
