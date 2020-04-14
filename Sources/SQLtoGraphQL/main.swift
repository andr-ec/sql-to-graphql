//
//  File.swift
//  
//
//  Created by Andre Carrera on 4/13/20.
//

import Foundation
import ArgumentParser
import Utilities
import ApolloCodegenLib

//enum ArgumentValue: Codable {
//    case integer(Int)
//    case string(String)
//    case double(Double)
//    case json(String)
//    init(from decoder: Decoder) throws {
//        let container = try decoder.singleValueContainer()
//        if let x
//    }
//}

let parentFolderOfScriptFile = FileFinder.findParentFolder()
let sourceRootURL = parentFolderOfScriptFile
    .deletingLastPathComponent() // Sources
    .deletingLastPathComponent() // Project Root

let decoder = JSONDecoder()

struct ParseSQLtoGraphQL: ParsableCommand {
    @Argument(help: "The path to the root folder of spider. ex: path/to/spider")
    var spiderPath: String
    
    @Option(name: .shortAndLong, default: "/usr/local/bin/docker", help: "The path to where docker is installed.")
    var dockerPath: String
    
    @Option(name: .shortAndLong, default: "http://localhost:8080/v1/graphql", help: "The URL to the graphql endpoint.")
    var graphqlEndpoint: String
    
    
    
    func run() throws {
        let spiderDBsURL = URL(fileURLWithPath: spiderPath, isDirectory: true)
        let queryDatasetPaths = try FileManager.default.subpathsOfDirectory(atPath: spiderPath)
            .filter {($0.contains("train") || $0.contains("dev")) && $0.contains(".json") } // dev/train.json
        
        let datasets = try queryDatasetPaths.map { try SpiderDataset(subPath: $0, parentDirectory: spiderDBsURL) }
        
        for dataset in datasets {
            try process(dataset: dataset)
        }
        
    }
    
    func process(dataset: SpiderDataset) throws {
        for (name, exampleGroup) in dataset.schemaToExamples {
            let graphqlExamples = try process(schemaName: name, with: exampleGroup)
            // we have access to the dataset type here (train, dev)
            // so save here.
        }
    }
    
    func process(schemaName: String, with examples: [DatasetExample] ) throws -> [GraphQLDatasetExample] {
        // only start hasura if I need it.
//        let hash = startHasura(name: schemaName, dockerPath: self.dockerPath)
        // process schema here, the path is different from the dataset.
        let schema = try loadSchema(name: schemaName)
        
        let graphqlExamples = examples.map { GraphQLDatasetExample(example: $0, with: schema)}
        
//        stopHasura(hash: hash, dockerPath: self.dockerPath)
        // return processed examples.
        return graphqlExamples
    }
    
    func loadSchema(name: String) throws -> BaseSchema {
        let schemaPath = sourceRootURL
            .appendingPathComponent("Schemas")
            .appendingPathComponent(name, isDirectory: true)
            .appendingPathComponent("schema.json")
        let data = try Data(contentsOf: schemaPath)
        return try decoder.decode(BaseSchema.self, from: data)
    }
}

ParseSQLtoGraphQL.main()
