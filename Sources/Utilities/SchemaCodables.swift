//
//  File.swift
//  
//
//  Created by Andre Carrera on 4/13/20.
//

import Foundation

// MARK: - BaseSchema
public struct BaseSchema: Codable {
    public let schema: Schema

    enum CodingKeys: String, CodingKey {
        case schema = "__schema"
    }
}

// MARK: - Schema
public struct Schema: Codable {
    public let queryType, mutationType, subscriptionType: MutationTypeClass
    public let types: [TypeElement]
    public let directives: [Directive]
}

// MARK: - Directive
public struct Directive: Codable {
    public let name, directiveDescription: String
    public let locations: [String]
    public let args: [Arg]

    enum CodingKeys: String, CodingKey {
        case name
        case directiveDescription = "description"
        case locations, args
    }
}

// MARK: - Arg
public struct Arg: Codable {
    public let name: String
    public let argDescription: String?
    public let type: OfTypeClass
    public let defaultValue: String?

    enum CodingKeys: String, CodingKey {
        case name
        case argDescription = "description"
        case type, defaultValue
    }
}

// MARK: - OfTypeClass
public class OfTypeClass: Codable {
    public let kind: Kind
    public let name: String?
    public let ofType: OfTypeClass?

    init(kind: Kind, name: String?, ofType: OfTypeClass?) {
        self.kind = kind
        self.name = name
        self.ofType = ofType
    }
}

public enum Kind: String, Codable {
    case inputObject = "INPUT_OBJECT"
    case kindENUM = "ENUM"
    case list = "LIST"
    case nonNull = "NON_NULL"
    case object = "OBJECT"
    case scalar = "SCALAR"
}

// MARK: - MutationTypeClass
public struct MutationTypeClass: Codable {
    public let name: String
}

// MARK: - TypeElement
public struct TypeElement: Codable {
    public let kind: Kind
    public let name: String
    public let typeDescription: String?
    public let fields: [Field]?
    public let inputFields: [Arg]?
//    public let interfaces: [JSONAny]?
    public let enumValues: [EnumValue]?
//    public let possibleTypes: JSONNull?

    enum CodingKeys: String, CodingKey {
        case kind, name
        case typeDescription = "description"
//        case fields, inputFields, interfaces, enumValues, possibleTypes
        case fields, inputFields, enumValues
        
    }
    /// gets all of the fields that are not relations
    public var allSingleFieldNames: [String] {
        (fields ?? []).filter{ $0.type.kind == .scalar}.map{ $0.name}
    }
}

// MARK: - EnumValue
public struct EnumValue: Codable {
    public let name, enumValueDescription: String
    public let isDeprecated: Bool
//    public let deprecationReason: JSONNull?

    enum CodingKeys: String, CodingKey {
        case name
        case enumValueDescription = "description"
        case isDeprecated//, deprecationReason
    }
}

// MARK: - Field
public struct Field: Codable {
    public let name: String
    public let fieldDescription: String?
    public let args: [Arg]
    public let type: OfTypeClass
    public let isDeprecated: Bool
//    public let deprecationReason: JSONNull?

    enum CodingKeys: String, CodingKey {
        case name
        case fieldDescription = "description"
        case args, type, isDeprecated//, deprecationReason
    }
    
    public func nameMatchesFieldType(_ name: String?) -> Bool {
        guard let name = name, let objectTypeName = self.objectTypeName else {
            return false
        }
        return objectTypeName.lowercased() == name.lowercased()
    }
    
    public func fieldMatchesField(_ field:Field) -> Bool {
        return nameMatchesFieldType(field.objectTypeName)
    }
    
    public var objectTypeName: String? {
        if self.type.kind == .object, let name = self.type.name {
            return name
        } else if self.type.ofType?.kind == .some(.object), let name = self.type.ofType?.name {
            return name
        } else if type.ofType?.ofType?.ofType?.kind == .some(.object), let name = self.type.ofType?.ofType?.ofType?.name {
            return name
        } else {
            return nil
        }
    }
}
