//
//  File.swift
//  
//
//  Created by Andre Carrera on 4/10/20.
//

import Foundation
import ArgumentParser
import Utilities
import ApolloCodegenLib


struct SimplifiedSchema: Codable {
    let arguments: [Utilities.Arg]
    let types: [Utilities.TypeElement]
}


let parentFolderOfScriptFile = FileFinder.findParentFolder()
let sourceRootURL = parentFolderOfScriptFile
    .deletingLastPathComponent() // Sources
    .deletingLastPathComponent() // Project Root

let cliFolderURL = sourceRootURL
    .appendingPathComponent("Codegen")
    .appendingPathComponent("ApolloCLI")

let decoder = JSONDecoder()
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

struct DownloadGraphQLSchemas: ParsableCommand {
    
    @Option(name: .shortAndLong, default: "/usr/local/bin/docker", help: "The path to where docker is installed.")
    var dockerPath: String
    
    @Option(name: .shortAndLong, default: "http://localhost:8080/v1/graphql", help: "The URL to the graphql endpoint.")
    var graphqlEndpoint: String
    
    @Option(name: .shortAndLong, default: true, help: "Should retry failed schema downloads?")
    var shouldRetryFailed: Bool
    
    @Option(name: .shortAndLong, default: nil, help: "The name of a single schema to download.")
    var schemaName: String?
    
    var endpoint: URL {
        URL(string: graphqlEndpoint)!
    }
    
    
    
    func run() {
        if let name = self.schemaName {
            self.download(schema: name)
            return
        } else {
            var(successful, failed) = download(schemas: databaseNames.sorted())
            
            if shouldRetryFailed {
                while failed.count > 0 {
                    print("retrying failed \(failed.count)")
                    (successful, failed) = download(schemas: failed)
                }
            }
            
            print("successful \(successful.count)")
            print("failed \(failed.count)")
        }
    }
    
    func download(schema: String) {
        let hash = startHasura(name: schema, dockerPath: self.dockerPath)
        print("⬇️ \(schema)")
        // This makes it so that hasura has enough time to startup
        // and the request doesn't fail.
        sleep(1)
        let downloaded = self.downloadSchema(name: schema)
        
        switch downloaded {
        case .success(let downloadLogs):
            print(downloadLogs)
        //                successful.append(name)
        case .failure(let error):
            print("🚨 \(error)")
            //                failed.append(name)
        }
        
        let stopped = stopHasura(hash: hash, dockerPath: self.dockerPath)
        print("✅ \(stopped)")
        return
    }
    
    func download(schemas: [String]) -> (successful: [String], failed: [String]) {
        var successful = [String]()
        var failed = [String]()
        for name in schemas {
            let hash = startHasura(name: name, dockerPath: self.dockerPath)
            print("⬇️ \(name)")
            // This makes it so that hasura has enough time to startup
            // and the request doesn't fail.
            sleep(1)
            let downloaded = self.downloadSchema(name: name)
            
            switch downloaded {
            case .success(let downloadLogs):
                print(downloadLogs)
                successful.append(name)
            case .failure(let error):
                print("🚨 \(error)")
                failed.append(name)
            }
            
            let stopped = stopHasura(hash: hash, dockerPath: self.dockerPath)
            print("✅ \(stopped)")
        }
        return (successful,failed)
    }
    
    
    func downloadSchema(name: String) -> Result<String,Error> {
        
        let output = sourceRootURL
            .appendingPathComponent("Schemas")
            .appendingPathComponent(name, isDirectory: true)
        
        do {
            try FileManager
                .default
                .apollo_createFolderIfNeeded(at: output)
            
            let jsonOptions = ApolloSchemaOptions(schemaFileType: .json, endpointURL: endpoint,
                                              outputFolderURL: output)
            
            let sdlOptions = ApolloSchemaOptions(schemaFileType: .schemaDefinitionLanguage, endpointURL: endpoint,
                                                  outputFolderURL: output)
            
            let jsonResult = try ApolloSchemaDownloader.run(with: cliFolderURL,
                                                        options: jsonOptions)
            let sdlResult = try ApolloSchemaDownloader.run(with: cliFolderURL,
                                                           options: sdlOptions)
            
            try self.saveSimplifiedSchema(to: output)
            // save simplified json schema.
            return Result.success(jsonResult + sdlResult)
        } catch {
            return Result.failure(error)
        }
    }
    
    func saveSimplifiedSchema(to path: URL) throws {
        let fullJsonPath = path.appendingPathComponent("schema.json", isDirectory: false)
        let data = try Data(contentsOf: fullJsonPath)
        let schema = try decoder.decode(BaseSchema.self, from: data)
        let queryTypes = schema.schema.types.first!.fields!
            .filter{ !$0.name.contains("_by_pk")} // only want array types.
        
        let nameToType = Dictionary(uniqueKeysWithValues: schema.schema.types.dropFirst().map{ ($0.name, $0)})
        
        let queryTypesWithFields = queryTypes.compactMap{nameToType[$0.name] }
        assert(queryTypes.count == queryTypesWithFields.count)
        
        let arguments = queryTypes.first!.args
        
        let simpleSchema = SimplifiedSchema(arguments: arguments, types: queryTypesWithFields)
        let simplifiedSchemaPath = path.appendingPathComponent("simpleSchema.json", isDirectory: false)
        
        // save array of types

        let dataSchema = try encoder.encode(simpleSchema)
        
        try dataSchema.write(to: simplifiedSchemaPath)
    }
}

DownloadGraphQLSchemas.main()
