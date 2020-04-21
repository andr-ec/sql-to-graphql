//
//  File.swift
//  
//
//  Created by Andre Carrera on 4/14/20.
//

import Foundation
struct Database: Codable {
    private let columnNames: [[ColumnName]]
    var columns: [DatabaseColumn] {
        self.columnNamesOriginal.compactMap(self.parseColumn(_:))
    }
    private let columnNamesOriginal: [[ColumnName]]
    let columnTypes: [ColumnType]
    let dbID: String
    let foreignKeys: [[Int]]
    let primaryKeys: [Int]
    let tableNames, tableNamesOriginal: [String]
    
    /// tables with their corresponding columns
    var tables: [DatabaseTable] {
        let groupedColumns = Dictionary(grouping: columns, by: {$0.tableIndex})
        return self.tableNamesOriginal.enumerated().map { (index, tableName) in
            DatabaseTable(index: index, name: tableName, columns: groupedColumns[index] ?? [])
        }
    }
    
    var tableByName: [String: DatabaseTable] {
        Dictionary(uniqueKeysWithValues: self.tables.map{($0.name, $0)})
    }
    
    private func parseColumn(_ column: [ColumnName]) -> DatabaseColumn? {
        if case .integer(let tableIndex) = column.first!, case .string(let columnName) = column.last! {
            let tableName = tableIndex != -1 ? tableNamesOriginal[tableIndex] : "*"
            return DatabaseColumn(columnName: columnName, tableIndex: tableIndex, tableName: tableName )
        } else {
            return nil
        }
    }
    

    enum CodingKeys: String, CodingKey {
        case columnNames = "column_names"
        case columnNamesOriginal = "column_names_original"
        case columnTypes = "column_types"
        case dbID = "db_id"
        case foreignKeys = "foreign_keys"
        case primaryKeys = "primary_keys"
        case tableNames = "table_names"
        case tableNamesOriginal = "table_names_original"
    }
}

struct DatabaseTable: Hashable {
    let index: Int
    let name: String
    let columns: [DatabaseColumn]
}
//enum ColumnName
struct DatabaseColumn: Hashable {
    let columnName: String
    let tableIndex: Int
    let tableName: String
}

enum ColumnName: Codable {
    case integer(Int) // table index
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        throw DecodingError.typeMismatch(ColumnName.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for ColumnName"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        }
    }
}

enum ColumnType: String, Codable {
    case boolean = "boolean"
    case number = "number"
    case others = "others"
    case text = "text"
    case time = "time"
}
