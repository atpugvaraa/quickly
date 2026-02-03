//
//  NetworkClient.swift
//  quickly
//
//  Created by Aarav Gupta on 01/02/26.
//

import Foundation

public actor NetworkClient {
    public let session: URLSession
    
    public init() {
        let configuration = URLSessionConfiguration.ephemeral
        self.session = URLSession(configuration: configuration)
    }
}
