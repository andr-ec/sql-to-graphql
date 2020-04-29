//
//  File.swift
//  
//
//  Created by Andre Carrera on 4/14/20.
//

import Foundation

// Raw graphql queries used to create real queries

struct RawGraphQLQueryGroup {
    let queries: [RawGraphQLQuery]
    let fromTableQueries: [RawGraphQLQuery]
    let whereArgument: RawGraphQLArgument?
    let orderByArgument: RawGraphQLArgument?
    let limitArgument: RawGraphQLArgument?
    let isDistinct: Bool
}

class RawGraphQLArgument: Hashable {
    static func == (lhs: RawGraphQLArgument, rhs: RawGraphQLArgument) -> Bool {
        lhs.name == rhs.name && lhs.value == rhs.value && lhs.not == rhs.not
    }
    
    
    enum RawGraphQLArgumentName: RawRepresentable, Hashable {
        typealias RawValue = String
        
        case not
        case whereCase
        case and
        case or
        case name(String)
        case distinct
        case column(DatabaseColumn)
        case orderBy
        case limit
        case queryRelation(String)
        case whereOperation(WhereOperation)
        
        /// Failable Initalizer
        public init?(rawValue: RawValue) {
            switch rawValue {
            case "where": self = .whereCase
            case "and":  self = .and
            case "or":  self = .or
            case "distinct": self = .distinct
            case "order_by": self = .orderBy
            case "limit": self = .limit
            case "not": self = .not
            default:
                if let operation = WhereOperation.init(rawString: rawValue) {
                    self = .whereOperation(operation)
                } else {
                    self = .name(rawValue)
                }
            }
        }

        /// Backing raw value
        public var rawValue: RawValue {
            switch self {
            case .not: return "not"
            case .whereCase: return "where"
            case .and: return "and"
            case .or: return "or"
            case .distinct: return "distinct"
            case .orderBy: return "order_by"
            case .limit: return "limit"
            case .whereOperation(let operation):
                return operation.rawGraphQLString
            case .name(let name):
                return name
            case .column(let column):
                // TODO check that this is the value I want!
//                return "\(column.tableName)_\(column.columnName)"
                return column.columnName
            case .queryRelation(let relation):
                return relation
            }
        }
    }
    
    enum RawGraphQLArgumentValue: Hashable {
        case string(String)
        case integer(Int)
        case arguments([RawGraphQLArgument])
        case double(Double)
        case bool(Bool)
        case namedValue(String) // just returns without quotes for example asc or dec
        
        func encode() -> String {
            switch self {
            case .integer(let val):
                return "\(val)"
            case .string(let val):
//                return val
                let valReplacing = val.replacingOccurrences(of: "\"", with: "")
                return "\"\(valReplacing)\""
            case .arguments(let vals):
                return  "{" + vals.map{ $0.encode()}.joined(separator: ", ")  + "}"
            case .double(let val):
                return "\(val)"
            case .bool(let val):
                return "\(val)"
            case .namedValue(let val):
                return val
            }
        }
    }
    
    init(name: RawGraphQLArgumentName, value: RawGraphQLArgumentValue, not: Bool = false) {
        self.name = name
        self.value = value
        self.not = not
    }
    
    var name: RawGraphQLArgumentName
    let value: RawGraphQLArgumentValue
    let not: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(value)
        hasher.combine(not)
    }
    
    func encode() -> String {
        if case .column(_) = name {
            fatalError("column should be replaced with name.")
        }
        let encoded = "\(name.rawValue): " + value.encode()
        return encoded
    }
}

class RawGraphQLQuery: Hashable {
    static func == (lhs: RawGraphQLQuery, rhs: RawGraphQLQuery) -> Bool {
        lhs.table == rhs.table &&
        lhs.arguments == rhs.arguments &&
        lhs.queries == rhs.queries &&
        lhs.fields == rhs.fields &&
        lhs.hasAggregates == rhs.hasAggregates &&
        lhs.name == rhs.name
    }
    
    
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
    
    var table: DatabaseTable
    var arguments: [RawGraphQLArgument]
    var queries: [RawGraphQLQuery]
    var fields: [RawGraphQLField]
    /// if hasAggregate: `self.query.first` is always the `nodes`,
    /// `self.query.last` is always the `aggregate`
    let hasAggregates: Bool
    var name: String? // only has a value once confirmed as nested / parent query
    
    
    /// sets name based off of schema types, handling aggregate when needed.
    /// `nodes` query is correct name as well.
    func setNameFrom(schema: BaseSchema) {
        let types = schema.schema.types
        let aggregateEnding = self.hasAggregates ? "_aggregate" : ""
        guard let type = types
        .first(where: { $0.name.lowercased() == self.table.name.lowercased() + aggregateEnding }) else {
                fatalError("table not found in schema")
        }
        self.name = type.name
        if self.hasAggregates,
            let nodesType = types.first(where: { $0.name.lowercased() == self.table.name.lowercased() }) {
//            let aggregateFieldsType = types.first(where: {$0.name.lowercased() == self.table.name.lowercased() + aggregateEnding + "_fields"}) {
            
            self.queries.first?.table = table
            self.queries.first?.name = nodesType.name
            
            self.queries.last?.table = table
            self.queries.last?.name = "aggregate"
            // TODO find aggregate type and add.
        } else if self.hasAggregates {
            fatalError("table not found in schema")
        }
    }
    
    func combine(with query: RawGraphQLQuery) {
        self.arguments = self.arguments + query.arguments
        self.fields = self.fields + query.fields
        self.queries = self.queries + query.queries
    }
    
    var nestedQueryCount: Int {
        self.queries.map{$0.nestedQueryCount}.reduce(0, +) + 1
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(table)
        hasher.combine(arguments)
        hasher.combine(queries)
        hasher.combine(fields)
        hasher.combine(hasAggregates)
        hasher.combine(name)
    }
    
    func encode() -> String {
        guard !queries.isEmpty || !fields.isEmpty else {
            return ""
        }
        let encodedArgs = arguments.count > 0 ? self.encodedArguments() : ""
        let encodedQueries = queries.count > 0 ? self.encodedQueries() : ""
        let encodedFields = fields.count > 0 ? self.encodeFields() : ""
        return "\(name!)\(encodedArgs) { \(encodedFields) \(encodedQueries) }"
    }
    
    func encodeFields() -> String {
        self.fields.map{ $0.encode() }.joined(separator: "  ")
    }
    
    func encodedArguments() -> String {
        "(" + arguments.map { $0.encode()}.joined(separator: ", ") + ")"
    }
    
    func encodedQueries() -> String {
        return queries.map {$0.encode()}.joined(separator: "   ")
    }
}

struct RawGraphQLField: Hashable {
    init(name: RawGraphQLField.RawGraphQLFieldName, column: DatabaseColumn, arguments: [RawGraphQLArgument] = []) {
        self.name = name
        self.column = column
        self.arguments = arguments
    }
    
    enum RawGraphQLFieldName: Hashable {
        case aggregate(AggregateOpperation)
        case field(String)
        case allFields
    }
    let name: RawGraphQLFieldName
    let column: DatabaseColumn
    let arguments: [RawGraphQLArgument]
    
    func encode() -> String {
        // TODO:
        // verify that .distinct are being handled correctly.
        assert(arguments.count == 0 || self.arguments.first!.name == .distinct)
        switch self.name {
        case .aggregate(let operation):
            return operation.string
        case .field(let field):
            return field
        case .allFields:
            fatalError("all fields should be handled before encoding")
        }
    }
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
//    let questionTokens: [String]
    let query: String
}
