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

//CLAUSE_KEYWORDS = ('select', 'from', 'where', 'group', 'order', 'limit', 'intersect', 'union', 'except')
//JOIN_KEYWORDS = ('join', 'on', 'as')
//
//WHERE_OPS = ('not', 'between', '=', '>', '<', '>=', '<=', '!=', 'in', 'like', 'is', 'exists')
//UNIT_OPS = ('none', '-', '+', "*", '/')
//AGG_OPS = ('none', 'max', 'min', 'count', 'sum', 'avg')
//TABLE_TYPE = {
//    'sql': "sql",
//    'table_unit': "table_unit",
//}
//COND_OPS = ('and', 'or')
//SQL_OPS = ('intersect', 'union', 'except')
//ORDER_OPS = ('desc', 'asc')


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
    /// returns HavingConditionStruct value only at odd indices that exist
    func havingCondition(at index: Int) -> HavingConditionStruct? {
        if case .conditionUnit(let havings) = having[index] {
            return havings.toStruct()
        }else {
            return nil
        }
    }
    /// returns WhereConditionStruct value only at odd indices that exist
    func whereCondition(at index: Int) -> WhereConditionStruct? {
        if case .whereCondition(let condition) = sqlWhere[index] {
            return condition.toStruct()
        }else {
            return nil
        }
    }
}

enum SQLWhere: Codable {
    case enumeration(AndOr)
    case whereCondition([CunningWhere])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([CunningWhere].self) {
            self = .whereCondition(x)
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
        case .whereCondition(let x):
            try container.encode(x)
        }
    }
}

struct OrderByStruct {
    let direction: ValueUnitEnum
    let valueUnits: [ValueUnitStruct]
    init?(orderBys: [ExceptValueUnit]) {
        assert(orderBys.isEmpty || orderBys.count == 2, "wrong cound for orderBy tuple.")
        if let first = orderBys.first, case .enumeration(let direction) = first,
            let last = orderBys.last, case .unionArrayArray(let valueUnits) = last {
            self.direction = direction
            self.valueUnits = valueUnits.map { $0.toStruct()}
        }else {
            return nil
        }
    }
}

extension Array where Element == ExceptValueUnit {
    func toStruct() -> OrderByStruct? {
        return OrderByStruct(orderBys: self)
    }
}

struct WhereConditionStruct {
    let notOperation: Bool
    private let operationId: Int
    let operation: WhereOperation
    /// The value unit before the operation
    let valueUnit: ValueUnitStruct
    /// The value unit after operation
    let val1: ValueType // should this be optional?
    let val2: ValueType?

    enum ValueType {
        case double(Double)
        case integer(Int)
        case string(String)
        case sql(SQL)
        case columnUnit(ColumnUnitStruct)
    }

    init(units: [CunningWhere]) {
        assert(units.count == 5, "ConditionUnit (cond_unit) count is not 5.")

        guard case .notOperation(let notOperation) = units[0],
            case .integer(let operationId) = units[1],
            case .valueUnit(let valueUnit) = units[2] else {
            fatalError("ConditionUnit (cond_unit) type orders don't match.")
        }

        self.notOperation = notOperation
        self.operationId = operationId
        self.operation = WhereOperation(rawValue: operationId)!
        self.valueUnit = valueUnit.toStruct()

        switch units[3] {
        case .double(let val):
            self.val1 = .double(val)
        case .string(let val):
            self.val1 = .string(val)
        case .sql(let val):
            self.val1 = .sql(val)
        case .integer(let val):
            self.val1 = .integer(val)
        case .val(let column):
            self.val1 = .columnUnit(column.toStuct())
        default:
            fatalError("val1: ValueType (val) type orders don't match.")
        }

        switch units[4] {
        case .double(let val):
            self.val2 = .double(val)
        case .string(let val):
            self.val2 = .string(val)
        case .sql(let val):
            self.val2 = .sql(val)
        case .integer(let val):
            self.val2 = .integer(val)
        case .val(let column):
            self.val2 = .columnUnit(column.toStuct())
        case .null:
            self.val2 = nil // val2 is optional
        default:
            fatalError("val2: ValueType (val) type orders don't match.")
        }
    }
}

extension Array where Element == CunningWhere {
    func toStruct() -> WhereConditionStruct {
        WhereConditionStruct(units: self)
    }
}


/// cond_unit: (not_op, op_id, val_unit, val1, val2)
enum CunningWhere: Codable {
    case notOperation(Bool)
    case integer(Int)
    case double(Double)
    case sql(SQL)
    case string(String)
    case valueUnit([ValueUnit])
    case val([ColumnUnit])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .notOperation(x)
            return
        }
        if let val = try? container.decode([ColumnUnit].self) {
            self = .val(val)
            return
        }
        if let x = try? container.decode([ValueUnit].self) {
            self = .valueUnit(x)
            return
        }
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
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
            self = .sql(x)
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
        case .notOperation(let x):
            try container.encode(x)
        case .double(let x):
            try container.encode(x)
        case .integer(let x):
            try container.encode(x)
        case .sql(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        case .valueUnit(let x):
            try container.encode(x)
        case .val(let x):
            try container.encode(x)
        case .null:
            try container.encodeNil()
        }
    }
}

struct SelectStruct {
    let isDistinct: Bool
    let selectStatements: [SelectField]
    
    init(selects: [ExceptSelect]) {
        assert(selects.count == 2, "Select count is not 2")
        guard case .isDistict(let isDistinct) = selects[0] else {
            fatalError("isDistinct is not at index 0.")
        }
        guard case .unionArrayArray(let selectStatements) = selects[1] else {
            fatalError("selectStatements is not at index 1.")
        }
        self.isDistinct = isDistinct
        self.selectStatements = selectStatements.toPairs()
        
    }
}

extension Array where Element == ExceptSelect {
    func toStruct() -> SelectStruct {
        SelectStruct(selects: self)
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

struct SelectField {
    let aggregateOpperation: AggregateOpperation
    let valueUnit: ValueUnitStruct
    
    init(selects:[SelectSelect] ) {
        guard case .aggregateOpperation(let operation) = selects[0] else {
            fatalError("select pair type mismatch")
        }
        guard case .valueUnit(let unit) = selects[1] else {
            fatalError("select pair type mismatch")
        }
        self.aggregateOpperation = operation
        self.valueUnit = unit.toStruct()
    }
}

extension Array where Element == [SelectSelect] {
    func toPairs() -> [SelectField] {
        self.map(SelectField.init(selects:))
    }
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

struct HavingConditionStruct {
    let notOperation: Bool
    let operationId: Int
    let operation: WhereOperation
    let valueUnit: ValueUnitStruct
    let val1: ValueType // should this be optional?
    let val2: ValueType?
    
    enum ValueType {
//        case integer(Int)
        case string(String)
        case sql(SQL)
    }

    init(units: [PurpleHaving]) {
        assert(units.count == 5, "ConditionUnit (cond_unit) count is not 5.")
        
        guard case .notOperation(let notOperation) = units[0],
            case .integer(let operationId) = units[1],
            case .valueUnit(let valueUnit) = units[2] else {
            fatalError("ConditionUnit (cond_unit) type orders don't match.")
        }

        self.notOperation = notOperation
        self.operationId = operationId
        self.operation = WhereOperation(rawValue: operationId)!
        self.valueUnit = valueUnit.toStruct()
        
        switch units[3] {
//        case .integer(let val):
//            self.val1 = .integer(val)
        case .string(let val):
            self.val1 = .string(val)
        case .sql(let val):
            self.val1 = .sql(val)
        default:
            fatalError("val1: ValueType (val) type orders don't match.")
        }
        
        switch units[4] {
//        case .integer(let val):
//            self.val2 = .integer(val)
        case .string(let val):
            self.val2 = .string(val)
        case .sql(let val):
            self.val2 = .sql(val)
        case .null:
            self.val2 = nil // val2 is optional
        default:
            fatalError("val2: ValueType (val) type orders don't match.")
        }
    }
}

extension Array where Element == PurpleHaving {
    func toStruct() -> HavingConditionStruct {
        HavingConditionStruct(units: self)
    }
}
/// cond_unit: (not_op, op_id, val_unit, val1, val2)
enum PurpleHaving: Codable {
    case notOperation(Bool)
    case integer(Int)
    case valueUnit([ValueUnit])
    case string(String)
    case sql(SQL)
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
        if let x = try? container.decode([ValueUnit].self) {
            self = .valueUnit(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if let x = try? container.decode(SQL.self) {
            self = .sql(x)
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
        case .notOperation(let x):
            try container.encode(x)
        case .integer(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        case .sql(let x):
            try container.encode(x)
        case .valueUnit(let x):
            try container.encode(x)
        case .null:
            try container.encodeNil()
        }
    }
}

struct SQLFrom: Codable {
    let conds: [Conditions]
    let tableUnits: [[TableUnit]]
    
    /// either TableUnit.nestedSQL or tableIndex
    var allTableUnits: [TableUnit] {
        // index 1 is always the table unit
        self.tableUnits.compactMap{$0.last}
        
    }

    enum CodingKeys: String, CodingKey {
        case conds
        case tableUnits = "table_units"
    }
    /// returns condition if condition is "[ConditionUnit]" (should be all odd indices)
    func condition(at index: Int) -> ConditionUnitStruct? {
        if case .conditionUnit(let units) = self.conds[index] {
            return units.toStruct()
        } else {
            return nil
        }
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


struct ConditionUnitStruct {
    let notOperation: Bool
    private let operationId: Int
    let operation: WhereOperation
    let valueUnit: ValueUnitStruct
    let val1: ColumnUnitStruct
    let val2: ColumnUnitStruct?

    init(units: [ConditionUnit]) {
        assert(units.count == 5, "ConditionUnit (cond_unit) count is not 5.")
        
        guard case .notOperation(let notOperation) = units[0],
            case .integer(let operationId) = units[1],
            case .valueUnit(let valueUnit) = units[2],
            case .val(let val1) = units[3] else {
            fatalError("ConditionUnit (cond_unit) type orders don't match.")
        }

        self.notOperation = notOperation
        self.operationId = operationId
        self.operation = WhereOperation(rawValue: operationId)!
        self.valueUnit = valueUnit.toStruct()
        self.val1 = val1.toStuct()
        switch units[4] {
        case .val(let val2):
            self.val2 = val2.toStuct()
        case .null:
            self.val2 = nil
        default:
            fatalError("val2: ConditionUnit (cond_unit) type orders don't match.")
        }
    }
}

extension Array where Element == ConditionUnit {
    func toStruct() -> ConditionUnitStruct {
        ConditionUnitStruct(units: self)
    }
}

// possible reason it's weird is because it tries to decode val1 and val2 as ValueUnit
// in reality those are supposed to be ColumnUnit
/// cond_unit: (not_op, op_id, val_unit, val1, val2)
enum ConditionUnit: Codable {
    case notOperation(Bool)
    /// is WhereOperation on index 1, is val1 on index 3, is val2 on index4
    case integer(Int)
    /// val_unit: (unit_op, col_unit1, col_unit2)
    case valueUnit([ValueUnit])
//    case valueUnit([ValueUnit])
    case val([ColumnUnit])
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
        if let val = try? container.decode([ColumnUnit].self) {
            self = .val(val)
            return
        }
        if let x = try? container.decode([ValueUnit].self) {
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
        case .val(let x):
            try container.encode(x)
        case .null:
            try container.encodeNil()
        }
    }
}

// should be a val_unit
struct ValueUnitStruct {
    let unitOperation: UnitOperation
    let columnUnit1: ColumnUnitStruct
    let columnUnit2: ColumnUnitStruct?
    init(condElements: [ValueUnit]) {
        assert(condElements.count == 3, "ValueUnit (val_unit) does not have 3 elements")
        guard case .unitOperation(let unitOperation) = condElements[0],
            case .columnUnit(let columnUnit1) = condElements[1] else {
                fatalError("ValueUnit (val_unit) types don't match order.")
        }
        self.unitOperation = unitOperation
        self.columnUnit1 = columnUnit1.toStuct()
        // TODO there are some cases where bool is used
        // wrongly it's enumerating to ValueUnit when it should use ColumnUnit
        // This might fail, where is the bool???
        switch condElements[2] {
        case .columnUnit(let columnUnit2):
            self.columnUnit2 = columnUnit2.toStuct()
        case .null:
            self.columnUnit2 = nil
        default:
            fatalError("columnUnit2: ValueUnit (val_unit) types don't match.")
        }
    }
}

extension Array where Element == ValueUnit {
    func toStruct() -> ValueUnitStruct {
        ValueUnitStruct(condElements: self)
    }
}

/// same as valueUnit except for bool


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

struct ColumnUnitStruct {
    let aggregateId: Int
    let columnId: Int
    let isDistinct: Bool
    
    init(columnUnits: [ColumnUnit]) {
        assert(columnUnits.count == 3, "Column Unit (col_unit) count is not 3.")
        guard case .integer(let aggregateId) = columnUnits[0],
            case .integer(let columnId) = columnUnits[1],
            case .isDistinct(let isDistinct) = columnUnits[2] else {
                fatalError("Column Unit (col_unit) types do not match")
        }
        
        self.aggregateId = aggregateId
        self.columnId = columnId
        self.isDistinct = isDistinct
    }
}

extension Array where Element == ColumnUnit {
    func toStuct() -> ColumnUnitStruct {
        return ColumnUnitStruct(columnUnits: self)
    }
}

enum TableUnitEnum: String, Codable {
    case sql = "sql"
    case tableUnit = "table_unit"
}
