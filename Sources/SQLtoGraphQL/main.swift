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
        let spiderURL = URL(fileURLWithPath: spiderPath, isDirectory: true)
        let queryDatasetPaths = try FileManager.default.subpathsOfDirectory(atPath: spiderPath)
            .filter {($0.contains("train") || $0.contains("dev")) && $0.contains(".json") && !$0.contains("others") } // dev/train.json
        
        let datasets = try queryDatasetPaths.map { try SpiderDataset(subPath: $0, parentDirectory: spiderURL) }
        
        let databases = try self.loadDatabases(spiderURL: spiderURL)
        
        let databaseById = Dictionary(grouping: databases, by: {$0.dbID})
            .mapValues{ $0.first! }
        
//        print("Total count = \(datasets.flatMap{ $0.schemaToExamples.map{ $0.value.count}}.reduce(0, +))")
        // Total examples = 9693
        for dataset in datasets {
            try process(dataset: dataset, databases: databaseById)
        }
        
    }
    
    func process(dataset: SpiderDataset, databases: [String: Database]) throws {
        // TODO load databases/ datasets only when needed one at a time
        for (name, exampleGroup) in dataset.schemaToExamples.sorted(by: { $0.key > $1.key}) {
            let database = databases[name]!
            let schema = try loadSchema(name: name)
            
            let parser = DatabaseExamplesParser(schema: schema, examples: exampleGroup, database: database)
            
            let graphqlDataset = parser.parse()
            
            // we have access to the dataset type here (train, dev)
            // so save here.
        }
    }
    
    func loadSchema(name: String) throws -> BaseSchema {
        let schemaPath = sourceRootURL
            .appendingPathComponent("Schemas")
            .appendingPathComponent(name, isDirectory: true)
            .appendingPathComponent("schema.json")
        let data = try Data(contentsOf: schemaPath)
        return try decoder.decode(BaseSchema.self, from: data)
    }
    
    func loadDatabases(spiderURL: URL) throws -> [Database] {
        let tablePath = spiderURL
            .appendingPathComponent("tables.json")
        let data = try Data(contentsOf: tablePath)
        return try decoder.decode([Database].self, from: data)
    }
}

ParseSQLtoGraphQL.main()
