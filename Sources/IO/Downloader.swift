//
//  Downloader.swift
//  quickly
//
//  Created by Aarav Gupta on 31/01/26.
//

import Foundation
import Core

public actor Downloader {
    private let client = NetworkClient()
    
    public init() {}
    
    private let casPath = URL(filePath: "/opt/quickly/cas")
    
    public func download(url: URL, sha256: String) async throws -> URL {
        let destination = casPath.appending(component: sha256)
        
        if FileManager.default.fileExists(atPath: destination.path()) {
            print("Cache hit for \(url.lastPathComponent)")
            return destination
        }
        
        print("Downloading from: \(url.absoluteString)")
        
        let token = try await fetchGHCRToken(for: url)
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (tempURL, response) = try await client.session.download(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let httpResponse = response as? HTTPURLResponse {
                print("❌ Status Code: \(httpResponse.statusCode)")
            }
            throw URLError(.fileDoesNotExist)
        }
        
        try FileManager.default.createDirectory(at: casPath, withIntermediateDirectories: true)
        
        if FileManager.default.fileExists(atPath: destination.path()) {
            try FileManager.default.removeItem(at: destination)
        }
        
        try FileManager.default.moveItem(at: tempURL, to: destination)
        return destination
    }
    
    private func fetchGHCRToken(for url: URL) async throws -> String {
        let pathComponents = url.pathComponents
        
        guard let v2Index = pathComponents.firstIndex(of: "v2"),
              let blobsIndex = pathComponents.firstIndex(of: "blobs"),
              pathComponents.count > blobsIndex + 1 else {
            return ""
        }
        
        let repoComponents = pathComponents[(v2Index + 1)..<blobsIndex]
        let repo = repoComponents.joined(separator: "/")
        let scope = "repository:\(repo):pull"
        
        var components = URLComponents(string: "https://ghcr.io/token")!
        components.queryItems = [
            URLQueryItem(name: "service", value: "ghcr.io"),
            URLQueryItem(name: "scope", value: scope)
        ]
        
        let (data, response) = try await client.session.data(from: components.url!)
        
        if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown Error"
            print("❌ Token Request Failed (\(httpResp.statusCode)): \(errorText)")
            throw URLError(.userAuthenticationRequired)
        }
        
        let tokenReponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        return tokenReponse.token
    }
    
    private struct TokenResponse: Codable {
        let token: String
    }
}
