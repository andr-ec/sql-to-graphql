//
//  File.swift
//  
//
//  Created by Andre Carrera on 4/13/20.
//

import Foundation

typealias SchemaToExamples = [String: [DatasetExample]]

struct SpiderDataset {
    let path: String
    let name: String
    let URLpath: URL
    let schemaToExamples: SchemaToExamples
    let decoder = JSONDecoder()
    
    init(subPath: String, parentDirectory: URL) throws {
        self.URLpath = parentDirectory.appendingPathComponent(subPath)
        self.path = URLpath.path
        self.name = URLpath.deletingPathExtension().pathComponents.last!
        self.schemaToExamples = try SpiderDataset.getDatasetByDatabase(url: self.URLpath, decoder: decoder)
    }
    
    static func getDatasetByDatabase(url: URL, decoder: JSONDecoder) throws -> [String: [DatasetExample]] {
        let data = try Data(contentsOf: url)
        let examples = try decoder.decode([DatasetExample].self, from: data)
        return Dictionary(grouping: examples, by: {$0.dbID})
    }
}
