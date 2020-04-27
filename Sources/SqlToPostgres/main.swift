//
//  main.swift
//  
//
//  Created by Andre Carrera on 4/7/20.
//

import Foundation
import ArgumentParser
import Utilities

struct SQLLiteDB {
    let path: String
    let name: String
    init(subPath: String, parentDirectory: URL) {
        let URLpath = parentDirectory.appendingPathComponent(subPath)
        self.path = URLpath.path
        self.name = URLpath.deletingPathExtension().pathComponents.last!
    }
}

struct ProcessDatabases: ParsableCommand {
    @Argument(help: "The path to the databases folder of spider. ex: path/to/spider/database")
    var spiderPath: String
    
    @Option(name: .shortAndLong, default: "/usr/local/bin/createdb", help: "The path to where createdb is installed.")
    var createdbPath: String
    
    @Option(name: .shortAndLong, default: "/usr/local/bin/pgloader", help: "The path to where pgloader is installed.")
    var pgloaderPath: String
    
    func run() {
        // So we don't run this accidentally while building schemas
        return
        do {
            let spiderDBsURL = URL(fileURLWithPath: spiderPath, isDirectory: true)
            let sqlLitePaths = try FileManager.default.subpathsOfDirectory(atPath: spiderPath)
                .filter { $0.contains(".sqlite")}
                .map { SQLLiteDB(subPath: $0, parentDirectory: spiderDBsURL) }
            
            sqlLitePaths.forEach { database in
                
                _ = shell("\(createdbPath) \(database.name)")
                let pgLoaderResult = shell("\(pgloaderPath) \(database.path) postgresql:///\(database.name)")
                
                print(pgLoaderResult)
            }
            
            print("transfered databases from sqllite to postgres:")
            
            sqlLitePaths.forEach{ print($0.name) }
            
        } catch {
            print(error)
        }
    }
}
ProcessDatabases.main()
