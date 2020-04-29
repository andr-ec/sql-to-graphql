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
    
    @Argument(help: "The path to save the new GraphQL dataset to.")
    var savePath: String
    
    @Option(name: .shortAndLong, default: "/usr/local/bin/docker", help: "The path to where docker is installed.")
    var dockerPath: String
    
    @Option(name: .shortAndLong, default: "http://localhost:8080/v1/graphql", help: "The URL to the graphql endpoint.")
    var graphqlEndpoint: String
    
    @Option(name: .shortAndLong, default: false, help: "If user should be prompted to fill in manual error entries at the end.")
    var promptManual: Bool
    
    
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
        let databasesResults = dataset.schemaToExamples
            .sorted(by: { $0.key > $1.key})
            .flatMap({ [self.process($0.key, database: databases[$0.key]!, exampleGroup: $0.value)]})
        
        let successfulResults = databasesResults
            .flatMap{ $0.successful }
        
        
        
        let failedResults = databasesResults
            .map{ (name: $0.name ,failed: $0.failed) }
        
        let failedCounts = failedResults
            .map{ $0.failed.count}
            .reduce(0, +)
        
        let allSuccessful: [GraphQLDatasetExample]
        
        if self.promptManual {
            // call function to save successfulResults
            let failedToRunManually = failedResults
                .map{ (name: $0.name, failed: $0.failed.filter{ $0.failedReason == .manualRelationEntryNeeded }) }
            
            let successManual = failedToRunManually
                .flatMap{ self.process($0.name, database: databases[$0.name]!, exampleGroup: $0.failed.map{ $0.example}, isPromptManual: true).successful }
            
            allSuccessful = successfulResults + successManual
        } else {
            allSuccessful = successfulResults
        }
        
        try self.saveAll(examples: allSuccessful, for: dataset)
        print("Succesful:",successfulResults.count)
        print("Failed:", failedCounts)
        return
        // call function to save allSuccesful
        // print out count of all errors.
    }
    
    func saveAll(examples: [GraphQLDatasetExample], for dataset: SpiderDataset) throws {
        let fileName = dataset.name.contains("train") ? "train.json" : "dev.json"
        let saveURL = URL(fileURLWithPath: self.savePath)
            .appendingPathComponent(fileName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(examples)
        
        try data.write(to: saveURL)
    }
    
    func process(_ name: String, database: Database, exampleGroup: [DatasetExample], isPromptManual: Bool = false) -> DatabaseExampleResult {
        let schema = try! loadSchema(name: name)
        let parser = DatabaseExamplesParser(schema: schema, examples: exampleGroup, database: database, isPromptManual: isPromptManual)
        let (successful, failed) = parser.parse()
        return DatabaseExampleResult(name: name, successful: successful, failed: failed)
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
