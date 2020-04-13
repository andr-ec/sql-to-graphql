//
//  File.swift
//  
//
//  Created by Andre Carrera on 4/13/20.
//

import Foundation
struct DatasetExample: Codable {
    let dbID: String
    let query: String
    let queryToks, queryToksNoValue: [String]
    let question: String
    let questionToks: [String]
//    let sql: SQL

    enum CodingKeys: String, CodingKey {
        case dbID = "db_id"
        case query
        case queryToks = "query_toks"
        case queryToksNoValue = "query_toks_no_value"
        case question
        case questionToks = "question_toks"
//        case sql
    }
}
