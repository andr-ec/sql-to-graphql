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
    let groupBy: [[ColumnUnit]]
    let having: [SQLHaving]
    let intersect: SQL?
    let limit: Int?
    let orderBy: [ExceptValueUnit]
    let select: [ExceptSelect]
    let union: SQL?
    let sqlWhere: [SQLWhere]

    enum CodingKeys: String, CodingKey {
        case except, from, groupBy, having, intersect, limit, orderBy, select, union
        case sqlWhere = "where"
    }
    
    enum ConnectionOperator {
        case intersect(SQL)
        case union(SQL)
        case except(SQL)
        case none
    }
    // only one intersect/union/except
    var connection: ConnectionOperator {
        if let except = except {
            return .except(except)
        } else if let intersect = intersect {
            return .intersect(intersect)
        } else if let union = union {
            return .union(union)
        } else {
            return .none
        }
    }
}

enum SQLWhere: Codable {
    case enumeration(AndOr)
    case unionArray([CunningWhere])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([CunningWhere].self) {
            self = .unionArray(x)
            return
        }
        if let x = try? container.decode(AndOr.self) {
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
    case isDistict(Bool) // always first!
    case unionArrayArray([[SelectSelect]]) // always second!

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .isDistict(x)
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
        case .isDistict(let x):
            try container.encode(x)
        case .unionArrayArray(let x):
            try container.encode(x)
        }
    }
}

// AGG_OPS = ('none', 'max', 'min', 'count', 'sum', 'avg')
enum AggregateOpperation: Int, Codable {
    case none
    case max
    case min
    case count
    case sum
    case avg
}

// (agg_id, val_unit)
enum SelectSelect: Codable {
    case aggregateOpperation(AggregateOpperation) // always first!
    case valueUnit([ValueUnit]) // always second

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(AggregateOpperation.self) {
            self = .aggregateOpperation(x)
            return
        }
        if let x = try? container.decode([ValueUnit].self) {
            self = .valueUnit(x)
            return
        }
        throw DecodingError.typeMismatch(SelectSelect.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for SelectSelect"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .aggregateOpperation(let x):
            try container.encode(x)
        case .valueUnit(let x):
            try container.encode(x)
        }
    }
}

// UNIT_OPS = ('none', '-', '+', "*", '/')
enum UnitOperation: Int, Codable {
    case none
    case minus
    case plus
    case times
    case divide
}

// val_unit: (unit_op, col_unit1, col_unit2)
// order is important for col_unit1, col_unit2
enum ValueUnit: Codable {
    case unitOperation(UnitOperation)
    case columnUnit([ColumnUnit])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(UnitOperation.self) {
            self = .unitOperation(x)
            return
        }
        if let x = try? container.decode([ColumnUnit].self) {
            self = .columnUnit(x)
            return
        }
        if container.decodeNil() {
            self = .null
            return
        }
        throw DecodingError.typeMismatch(ValueUnit.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for ValueUnit"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .unitOperation(let x):
            try container.encode(x)
        case .columnUnit(let x):
            try container.encode(x)
        case .null:
            try container.encodeNil()
        }
    }
}

enum ValueUnitEnum: String, Codable {
    case asc = "asc"
    case desc = "desc"
}

enum ExceptValueUnit: Codable {
    case enumeration(ValueUnitEnum)
    case unionArrayArray([[ValueUnit]])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([[ValueUnit]].self) {
            self = .unionArrayArray(x)
            return
        }
        if let x = try? container.decode(ValueUnitEnum.self) {
            self = .enumeration(x)
            return
        }
        throw DecodingError.typeMismatch(ExceptValueUnit.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for ExceptValueUnit"))
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

///condition: [cond_unit1, 'and'/'or', cond_unit2, ...]
enum SQLHaving: Codable {
    case enumeration(AndOr)
    case conditionUnit([PurpleHaving])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([PurpleHaving].self) {
            self = .conditionUnit(x)
            return
        }
        if let x = try? container.decode(AndOr.self) {
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
        case .conditionUnit(let x):
            try container.encode(x)
        }
    }
}
/// cond_unit: (not_op, op_id, val_unit, val1, val2)
enum PurpleHaving: Codable {
    case bool(Bool)
    case integer(Int)
    case string(String)
    case tableUnitClass(SQL)
    case unionArray([ValueUnit])
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
        if let x = try? container.decode([ValueUnit].self) {
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
    let conds: [Conditions]
    let tableUnits: [[TableUnit]]

    enum CodingKeys: String, CodingKey {
        case conds
        case tableUnits = "table_units"
    }
}

enum Conditions: Codable {
    case enumeration(AndOr)
    case conditionUnit([ConditionUnit])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([ConditionUnit].self) {
            self = .conditionUnit(x)
            return
        }
        if let x = try? container.decode(AndOr.self) {
            self = .enumeration(x)
            return
        }
        throw DecodingError.typeMismatch(Conditions.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for PurpleCond"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .enumeration(let x):
            try container.encode(x)
        case .conditionUnit(let x):
            try container.encode(x)
        }
    }
}

enum TableUnit: Codable {
    /// will always be first and defines if next index is tableIndex or nested SQL
    /// So this can be ignored since the type is implicit.
    case tableUnitType(TableUnitEnum)
    /// the index of the table
    case tableIndex(Int)
    // some nested SQL
    case nestedSQL(SQL)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) {
            self = .tableIndex(x)
            return
        }
        if let x = try? container.decode(TableUnitEnum.self) {
            self = .tableUnitType(x)
            return
        }
        if let x = try? container.decode(SQL.self) {
            self = .nestedSQL(x)
            return
        }
        throw DecodingError.typeMismatch(TableUnit.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for TableUnit"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .tableUnitType(let x):
            try container.encode(x)
        case .tableIndex(let x):
            try container.encode(x)
        case .nestedSQL(let x):
            try container.encode(x)
        }
    }
}

enum AndOr: String, Codable {
    case and = "and"
    case or = "or"
}

///WHERE_OPS = ('not', 'between', '=', '>', '<', '>=', '<=', '!=', 'in', 'like', 'is', 'exists')
enum WhereOperation: Int, Codable {
    case not
    case between
    case equals
    case greaterThan
    case lessThan
    case greaterThanOrEqualTo
    case lessThanOrEqualTo
    case notEqual
    /// in
    case inOp
    case like
    /// is
    case isOp
    case exists
}

/// cond_unit: (not_op, op_id, val_unit, val1, val2)
enum ConditionUnit: Codable {
    case notOperation(Bool)
    /// is WhereOperation on index 1, is val1 on index 3, is val2 on index4
    case integer(Int)
    /// val_unit: (unit_op, col_unit1, col_unit2)
    case valueUnit([CondElement])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .notOperation(x)
            return
        }
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        if let x = try? container.decode([CondElement].self) {
            self = .valueUnit(x)
            return
        }
        if container.decodeNil() {
            self = .null
            return
        }
        throw DecodingError.typeMismatch(ConditionUnit.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for ConditionUnit"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .notOperation(let x):
            try container.encode(x)
        case .integer(let x):
            try container.encode(x)
        case .valueUnit(let x):
            try container.encode(x)
        case .null:
            try container.encodeNil()
        }
    }
}

/// same as valueUnit except for bool
enum CondElement: Codable {
    /// not sure why there would be a bool here.
    case bool(Bool)
    case integer(Int)
    case unionArray([ColumnUnit])
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
        if let x = try? container.decode([ColumnUnit].self) {
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

/// col_unit: (agg_id, col_id, isDistinct(bool))
enum ColumnUnit: Codable {
    case isDistinct(Bool)
    /// index 0: agg_id, index 1: col_id,
    case integer(Int)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .isDistinct(x)
            return
        }
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        throw DecodingError.typeMismatch(ColumnUnit.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for ColumnUnit"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .isDistinct(let x):
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
