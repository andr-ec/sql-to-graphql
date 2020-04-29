//
//  File.swift
//  
//
//  Created by Andre Carrera on 4/28/20.
//

import Foundation

struct FailedExample {
    let example: DatasetExample
    let failedReason: ProcessingError
}

struct DatabaseExampleResult {
    let name: String
    let successful: [GraphQLDatasetExample]
    let failed: [FailedExample]
}
