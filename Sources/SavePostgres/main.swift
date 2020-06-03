//
//  File.swift
//  
//
//  Created by Andre Carrera on 6/3/20.
//

import Foundation
import Utilities
import ArgumentParser

struct SavePostgres: ParsableCommand {
    
    @Argument(help: "The path to save the database dumps. ex: path/to/directory")
    var saveDirectory: String
    
    @Option(default: "/usr/local/bin/pg_dump", help: "the path to the pgdump on machine.")
    var pgDumpPath: String
    
    func run() throws {
        Utilities.databaseNames.forEach { dbId in
            let results = self.dumpDatabase(name: dbId)
            print("Complete \(dbId) \(results)")
        }
    }
    
    public func dumpDatabase(name: String) -> String {
        let targetPath = URL(fileURLWithPath: saveDirectory, isDirectory: true)
            .appendingPathComponent("\(name)_dump.sql", isDirectory: false)
            .path
        let command = "\(pgDumpPath) --no-owner \(name) > \(targetPath)"
        return shell(command)
    }
    
}

SavePostgres.main()
//pg_dump --no-owner battle_death > battle_death_dump.sql
