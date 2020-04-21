//
//  File.swift
//  
//
//  Created by Andre Carrera on 4/14/20.
//

import Foundation

// Raw graphql queries used to create real queries
class RawGraphQLArgument {
    
    enum RawGraphQLArgumentName: RawRepresentable {
        typealias RawValue = String
        
//        case not
        case whereCase
        case and
        case or
        case name(String)
        case distinct
        case column(DatabaseColumn)
        
        /// Failable Initalizer
        public init?(rawValue: RawValue) {
            switch rawValue {
            case "where": self = .whereCase
            case "and":  self = .and
            case "or":  self = .or
            case "distinct": self = .distinct
//            case "not": self = .not
            default:
                self = .name(rawValue)
            }
        }

        /// Backing raw value
        public var rawValue: RawValue {
            switch self {
//            case .not: return "not"
            case .whereCase: return "where"
            case .and: return "and"
            case .or: return "or"
            case .distinct: return "distinct"
            case .name(let name):
                return name
            case .column(let column):
                // TODO check that this is the value I want!
                return "\(column.tableName)_\(column.columnName)"
            }
        }
    }
    
    enum RawGraphQLArgumentValue {
        case string(String)
        case integer(Int)
        case arguments([RawGraphQLArgument])
        case double(Double)
        case bool(Bool)
    }
    
    init(name: RawGraphQLArgumentName, value: RawGraphQLArgumentValue, not: Bool = false) {
        self.name = name
        self.value = value
        self.not = not
    }
    
    let name: RawGraphQLArgumentName
    let value: RawGraphQLArgumentValue
    let not: Bool
}

class RawGraphQLQuery {
    
    init(table: DatabaseTable,
         arguments: [RawGraphQLArgument] = [],
         queries: [RawGraphQLQuery] = [],
         fields: [RawGraphQLField] = [],
         hasAggregates: Bool = false) {
        self.table = table
        self.arguments = arguments
        self.queries = queries
        self.fields = fields
        self.hasAggregates = hasAggregates
    }
    
    let table: DatabaseTable
    let arguments: [RawGraphQLArgument]
    let queries: [RawGraphQLQuery]
    let fields: [RawGraphQLField]
    let hasAggregates: Bool
}

struct RawGraphQLField {
    init(name: RawGraphQLField.RawGraphQLFieldName, column: DatabaseColumn, arguments: [RawGraphQLArgument] = []) {
        self.name = name
        self.column = column
        self.arguments = arguments
    }
    
    enum RawGraphQLFieldName {
        case aggregate(AggregateOpperation)
        case field(String)
        
    }
    let name: RawGraphQLFieldName
    let column: DatabaseColumn
    let arguments: [RawGraphQLArgument]
}

// Real Graphql queries to encode

enum GraphQLArgumentValue {
    case string(String)
    case integer(Int)
    case arguments([GraphQLArgument])
    
    func encode() -> String{
        switch self {
        case .integer(let val):
            return "\(val)"
        case .string(let val):
            return "\"\(val)\""
        case .arguments(let vals):
            return  "{" + vals.map{ $0.encode()}.joined(separator: ", ")  + "}"
        }
    }
}

class GraphQLArgument {
    init(name: String, value: GraphQLArgumentValue) {
        self.name = name
        self.value = value
    }
    
    let name: String
    let value: GraphQLArgumentValue
    // todo enum when I need it.
    func encode() -> String {
        return "\(name): \(value.encode())"
    }
}

class GraphQLQuery {
    init(fieldName: String, arguments: [GraphQLArgument] = [], queries: [GraphQLQuery] = []) {
        self.fieldName = fieldName
        self.arguments = arguments
        self.queries = queries
    }
    
    let fieldName: String
    let arguments: [GraphQLArgument]
    let queries: [GraphQLQuery]
    
    func encode() -> String {
        let encodedArgs = arguments.count > 0 ? self.encodedArguments() : ""
        let encodedQueries = queries.count > 0 ? self.encodedQueries() : ""
        return "\(fieldName)\(encodedArgs) \(encodedQueries)"
    }
    func encodedArguments() -> String {
        "(" + arguments.map { $0.encode()}.joined(separator: ", ") + ")"
    }
    
    func encodedQueries() -> String {
        return "{\n" +
            queries.map {$0.encode()}.joined(separator: "\n") +
        "\n}"
    }
}

struct GraphQLDatasetExample: Codable {
    let schemaId: String
    let question: String
    let questionTokens: [String]
    let query: String
}
