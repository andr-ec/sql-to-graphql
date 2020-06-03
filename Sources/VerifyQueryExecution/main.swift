//
//  File.swift
//  
//
//  Created by Andre Carrera on 5/27/20.
//

import Foundation
import ArgumentParser
import Utilities
import Combine

let decoder = JSONDecoder()
let encoder = JSONEncoder()

struct DownloadGraphQLSchemas: ParsableCommand {
    @Option(name: .shortAndLong, default: "/usr/local/bin/docker", help: "The path to where docker is installed.")
    var dockerPath: String
    
    @Option(name: .shortAndLong, default: "http://localhost:8080/v1/graphql", help: "The URL to the graphql endpoint.")
    var graphqlEndpoint: String
    
    @Argument(help: "include the full path to the dataset to verify.")
    var path: String
    
    
    func run() throws {
        let pathURL = URL(fileURLWithPath: self.path)
        let data = try Data(contentsOf: pathURL)
        let examples = try decoder.decode([GraphQLDatasetExample].self, from: data)
        
        let examplesBySchema = Dictionary(grouping: examples, by: {$0.schemaId})
        
        let verify = VerifyQuery(dockerPath: self.dockerPath, graphqlEndpoint: self.graphqlEndpoint)
        
        verify.schemaToExample.send(examplesBySchema)
        
        RunLoop.current.run()
    }
}

enum HTTPError: Error {
    case code(Int)
    case noResponse
    case other(Error)
}

DownloadGraphQLSchemas.main()
