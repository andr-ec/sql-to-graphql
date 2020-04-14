//
//  File.swift
//  
//
//  Created by Andre Carrera on 4/14/20.
//

import Foundation

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

// holds a graphql query.
struct GraphQLDatasetExample {
    init(example: DatasetExample, with schema: BaseSchema) {
        // might need to grab tables.json.
        
        // find which tables to query from "FROM" and any other
        // find any aggregates that are needed
        // create a struct that can return
        
        
        // might need to use vars. can't see everything I need in one shot.
        switch example.sql.from.tableUnits.first![0] {
        case .tableIndex(let index):
            <#code#>
        default:
            <#code#>
        }
    }
}
