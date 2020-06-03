//
//  File.swift
//  
//
//  Created by Andre Carrera on 5/27/20.
//

import Foundation

public struct GraphQLDatasetExample: Codable {
    public init(schemaId: String, question: String, query: String) {
        self.schemaId = schemaId
        self.question = question
        self.query = query
    }
    
    public let schemaId: String
    public let question: String
    //    let questionTokens: [String]
    public let query: String
    
}
