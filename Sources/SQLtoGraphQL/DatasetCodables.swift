//
//  File.swift
//  
//
//  Created by Andre Carrera on 4/13/20.
//

//################################
//# Assumptions:
//#   1. sql is correct
//#   2. only table name has alias
//#   3. only one intersect/union/except
//#
//# val: number(float)/string(str)/sql(dict)
//# col_unit: (agg_id, col_id, isDistinct(bool))
//# val_unit: (unit_op, col_unit1, col_unit2)
//# table_unit: (table_type, col_unit/sql)
//# cond_unit: (not_op, op_id, val_unit, val1, val2)
//# condition: [cond_unit1, 'and'/'or', cond_unit2, ...]
//# sql {
//#   'select': (isDistinct(bool), [(agg_id, val_unit), (agg_id, val_unit), ...])
//#   'from': {'table_units': [table_unit1, table_unit2, ...], 'conds': condition}
//#   'where': condition
//#   'groupBy': [col_unit1, col_unit2, ...]
//#   'orderBy': ('asc'/'desc', [val_unit1, val_unit2, ...])
//#   'having': condition
//#   'limit': None/limit value
//#   'intersect': None/sql
//#   'except': None/sql
//#   'union': None/sql
//# }
//################################


import Foundation
struct DatasetExample: Codable {
    let dbID, query: String
    let queryToks, queryToksNoValue: [String]
    let question: String
    let questionToks: [String]
    let sql: SQL

    enum CodingKeys: String, CodingKey {
        case dbID = "db_id"
        case query
        case queryToks = "query_toks"
        case queryToksNoValue = "query_toks_no_value"
        case question
        case questionToks = "question_toks"
        case sql
    }
}

// MARK: - SQL
class SQL: Codable {
    let except: SQL?
    let from: SQLFrom
    let groupBy: [[GroupBy]]
    let having: [SQLHaving]
    let intersect: SQL?
    let limit: Int?
    let orderBy: [ExceptOrderBy]
    let select: [ExceptSelect]
    let union: SQL?
    let sqlWhere: [SQLWhere]

    enum CodingKeys: String, CodingKey {
        case except, from, groupBy, having, intersect, limit, orderBy, select, union
        case sqlWhere = "where"
    }
}

enum SQLWhere: Codable {
    case enumeration(HavingEnum)
    case unionArray([CunningWhere])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([CunningWhere].self) {
            self = .unionArray(x)
            return
        }
        if let x = try? container.decode(HavingEnum.self) {
            self = .enumeration(x)
            return
        }
        throw DecodingError.typeMismatch(SQLWhere.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for SQLWhere"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .enumeration(let x):
            try container.encode(x)
        case .unionArray(let x):
            try container.encode(x)
        }
    }
}

enum CunningWhere: Codable {
    case bool(Bool)
    case double(Double)
    case exceptClass(SQL)
    case string(String)
    case unionArray([CondElement])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .bool(x)
            return
        }
        if let x = try? container.decode([CondElement].self) {
            self = .unionArray(x)
            return
        }
        if let x = try? container.decode(Double.self) {
            self = .double(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if let x = try? container.decode(SQL.self) {
            self = .exceptClass(x)
            return
        }
        if container.decodeNil() {
            self = .null
            return
        }
        throw DecodingError.typeMismatch(CunningWhere.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for CunningWhere"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let x):
            try container.encode(x)
        case .double(let x):
            try container.encode(x)
        case .exceptClass(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        case .unionArray(let x):
            try container.encode(x)
        case .null:
            try container.encodeNil()
        }
    }
}

enum ExceptSelect: Codable {
    case bool(Bool)
    case unionArrayArray([[SelectSelect]])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .bool(x)
            return
        }
        if let x = try? container.decode([[SelectSelect]].self) {
            self = .unionArrayArray(x)
            return
        }
        throw DecodingError.typeMismatch(ExceptSelect.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for ExceptSelect"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let x):
            try container.encode(x)
        case .unionArrayArray(let x):
            try container.encode(x)
        }
    }
}

enum SelectSelect: Codable {
    case integer(Int)
    case unionArray([OrderBy])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        if let x = try? container.decode([OrderBy].self) {
            self = .unionArray(x)
            return
        }
        throw DecodingError.typeMismatch(SelectSelect.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for SelectSelect"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let x):
            try container.encode(x)
        case .unionArray(let x):
            try container.encode(x)
        }
    }
}

enum OrderBy: Codable {
    case integer(Int)
    case unionArray([GroupBy])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        if let x = try? container.decode([GroupBy].self) {
            self = .unionArray(x)
            return
        }
        if container.decodeNil() {
            self = .null
            return
        }
        throw DecodingError.typeMismatch(OrderBy.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for OrderBy"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let x):
            try container.encode(x)
        case .unionArray(let x):
            try container.encode(x)
        case .null:
            try container.encodeNil()
        }
    }
}

enum OrderByEnum: String, Codable {
    case asc = "asc"
    case desc = "desc"
}

enum ExceptOrderBy: Codable {
    case enumeration(OrderByEnum)
    case unionArrayArray([[OrderBy]])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([[OrderBy]].self) {
            self = .unionArrayArray(x)
            return
        }
        if let x = try? container.decode(OrderByEnum.self) {
            self = .enumeration(x)
            return
        }
        throw DecodingError.typeMismatch(ExceptOrderBy.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for ExceptOrderBy"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .enumeration(let x):
            try container.encode(x)
        case .unionArrayArray(let x):
            try container.encode(x)
        }
    }
}


enum SQLHaving: Codable {
    case enumeration(HavingEnum)
    case unionArray([PurpleHaving])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([PurpleHaving].self) {
            self = .unionArray(x)
            return
        }
        if let x = try? container.decode(HavingEnum.self) {
            self = .enumeration(x)
            return
        }
        throw DecodingError.typeMismatch(SQLHaving.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for SQLHaving"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .enumeration(let x):
            try container.encode(x)
        case .unionArray(let x):
            try container.encode(x)
        }
    }
}

enum PurpleHaving: Codable {
    case bool(Bool)
    case integer(Int)
    case string(String)
    case tableUnitClass(SQL)
    case unionArray([OrderBy])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .bool(x)
            return
        }
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        if let x = try? container.decode([OrderBy].self) {
            self = .unionArray(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if let x = try? container.decode(SQL.self) {
            self = .tableUnitClass(x)
            return
        }
        if container.decodeNil() {
            self = .null
            return
        }
        throw DecodingError.typeMismatch(PurpleHaving.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for PurpleHaving"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let x):
            try container.encode(x)
        case .integer(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        case .tableUnitClass(let x):
            try container.encode(x)
        case .unionArray(let x):
            try container.encode(x)
        case .null:
            try container.encodeNil()
        }
    }
}

struct SQLFrom: Codable {
    let conds: [PurpleCond]
    let tableUnits: [[FluffyTableUnit]]

    enum CodingKeys: String, CodingKey {
        case conds
        case tableUnits = "table_units"
    }
}

enum PurpleCond: Codable {
    case enumeration(HavingEnum)
    case unionArray([CondCond])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([CondCond].self) {
            self = .unionArray(x)
            return
        }
        if let x = try? container.decode(HavingEnum.self) {
            self = .enumeration(x)
            return
        }
        throw DecodingError.typeMismatch(PurpleCond.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for PurpleCond"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .enumeration(let x):
            try container.encode(x)
        case .unionArray(let x):
            try container.encode(x)
        }
    }
}

enum FluffyTableUnit: Codable {
    case enumeration(TableUnitEnum)
    case integer(Int)
    case tableUnitClass(SQL)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        if let x = try? container.decode(TableUnitEnum.self) {
            self = .enumeration(x)
            return
        }
        if let x = try? container.decode(SQL.self) {
            self = .tableUnitClass(x)
            return
        }
        throw DecodingError.typeMismatch(FluffyTableUnit.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for FluffyTableUnit"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .enumeration(let x):
            try container.encode(x)
        case .integer(let x):
            try container.encode(x)
        case .tableUnitClass(let x):
            try container.encode(x)
        }
    }
}

enum HavingEnum: String, Codable {
    case and = "and"
    case or = "or"
}

enum CondCond: Codable {
    case bool(Bool)
    case integer(Int)
    case unionArray([CondElement])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .bool(x)
            return
        }
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        if let x = try? container.decode([CondElement].self) {
            self = .unionArray(x)
            return
        }
        if container.decodeNil() {
            self = .null
            return
        }
        throw DecodingError.typeMismatch(CondCond.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for CondCond"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let x):
            try container.encode(x)
        case .integer(let x):
            try container.encode(x)
        case .unionArray(let x):
            try container.encode(x)
        case .null:
            try container.encodeNil()
        }
    }
}

enum CondElement: Codable {
    case bool(Bool)
    case integer(Int)
    case unionArray([GroupBy])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .bool(x)
            return
        }
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        if let x = try? container.decode([GroupBy].self) {
            self = .unionArray(x)
            return
        }
        if container.decodeNil() {
            self = .null
            return
        }
        throw DecodingError.typeMismatch(CondElement.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for CondElement"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let x):
            try container.encode(x)
        case .integer(let x):
            try container.encode(x)
        case .unionArray(let x):
            try container.encode(x)
        case .null:
            try container.encodeNil()
        }
    }
}


enum GroupBy: Codable {
    case bool(Bool)
    case integer(Int)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .bool(x)
            return
        }
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        throw DecodingError.typeMismatch(GroupBy.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for GroupBy"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let x):
            try container.encode(x)
        case .integer(let x):
            try container.encode(x)
        }
    }
}

enum TableUnitEnum: String, Codable {
    case sql = "sql"
    case tableUnit = "table_unit"
}
