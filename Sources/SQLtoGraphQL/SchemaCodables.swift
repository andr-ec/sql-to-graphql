//
//  File.swift
//  
//
//  Created by Andre Carrera on 4/13/20.
//

import Foundation

// MARK: - BaseSchema
struct BaseSchema: Codable {
    let schema: Schema

    enum CodingKeys: String, CodingKey {
        case schema = "__schema"
    }
}

// MARK: - Schema
struct Schema: Codable {
    let queryType, mutationType, subscriptionType: MutationTypeClass
    let types: [TypeElement]
    let directives: [Directive]
}

// MARK: - Directive
struct Directive: Codable {
    let name, directiveDescription: String
    let locations: [String]
    let args: [Arg]

    enum CodingKeys: String, CodingKey {
        case name
        case directiveDescription = "description"
        case locations, args
    }
}

// MARK: - Arg
struct Arg: Codable {
    let name: String
    let argDescription: String?
    let type: OfTypeClass
    let defaultValue: String?

    enum CodingKeys: String, CodingKey {
        case name
        case argDescription = "description"
        case type, defaultValue
    }
}

// MARK: - OfTypeClass
class OfTypeClass: Codable {
    let kind: Kind
    let name: String?
    let ofType: OfTypeClass?

    init(kind: Kind, name: String?, ofType: OfTypeClass?) {
        self.kind = kind
        self.name = name
        self.ofType = ofType
    }
}

enum Kind: String, Codable {
    case inputObject = "INPUT_OBJECT"
    case kindENUM = "ENUM"
    case list = "LIST"
    case nonNull = "NON_NULL"
    case object = "OBJECT"
    case scalar = "SCALAR"
}

// MARK: - MutationTypeClass
struct MutationTypeClass: Codable {
    let name: String
}

// MARK: - TypeElement
struct TypeElement: Codable {
    let kind: Kind
    let name: String
    let typeDescription: String?
    let fields: [Field]?
    let inputFields: [Arg]?
//    let interfaces: [JSONAny]?
    let enumValues: [EnumValue]?
//    let possibleTypes: JSONNull?

    enum CodingKeys: String, CodingKey {
        case kind, name
        case typeDescription = "description"
//        case fields, inputFields, interfaces, enumValues, possibleTypes
        case fields, inputFields, enumValues
        
    }
}

// MARK: - EnumValue
struct EnumValue: Codable {
    let name, enumValueDescription: String
    let isDeprecated: Bool
//    let deprecationReason: JSONNull?

    enum CodingKeys: String, CodingKey {
        case name
        case enumValueDescription = "description"
        case isDeprecated//, deprecationReason
    }
}

// MARK: - Field
struct Field: Codable {
    let name: String
    let fieldDescription: String?
    let args: [Arg]
    let type: OfTypeClass
    let isDeprecated: Bool
//    let deprecationReason: JSONNull?

    enum CodingKeys: String, CodingKey {
        case name
        case fieldDescription = "description"
        case args, type, isDeprecated//, deprecationReason
    }
}
