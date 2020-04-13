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


let parentFolderOfScriptFile = FileFinder.findParentFolder()
let sourceRootURL = parentFolderOfScriptFile
    .deletingLastPathComponent() // Sources
    .deletingLastPathComponent() // Project Root

let cliFolderURL = sourceRootURL
    .appendingPathComponent("Codegen")
    .appendingPathComponent("ApolloCLI")


struct DownloadGraphQLSchemas: ParsableCommand {
    
    @Option(name: .shortAndLong, default: "/usr/local/bin/docker", help: "The path to where docker is installed.")
    var dockerPath: String
    
    @Option(name: .shortAndLong, default: "http://localhost:8080/v1/graphql", help: "The URL to the graphql endpoint.")
    var graphqlEndpoint: String
    
    @Option(name: .shortAndLong, default: true, help: "Should retry failed schema downloads?")
    var shouldRetryFailed: Bool
    
    var endpoint: URL {
        URL(string: graphqlEndpoint)!
    }
    
    
    
    func run() {
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
            print("✋ \(stopped)")
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
            
            let options = ApolloSchemaOptions(endpointURL: endpoint,
                                              outputFolderURL: output)
            
            let result = try ApolloSchemaDownloader.run(with: cliFolderURL,
                                                        options: options)
            return Result.success(result)
        } catch {
            return Result.failure(error)
        }
    }
}

DownloadGraphQLSchemas.main()
