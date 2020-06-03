//
//  File.swift
//  
//
//  Created by Andre Carrera on 5/28/20.
//

import Foundation
import Utilities
import Combine

class VerifyQuery {
    var schemaToExample = PassthroughSubject<Dictionary<String, [GraphQLDatasetExample]>, Never>()
    let dockerPath: String
    let graphqlEndpoint: String
    
    var cancellables = Set<AnyCancellable>()
    
    var endPointURL: URL {
        URL(string: self.graphqlEndpoint)!
    }
    
    init(dockerPath: String, graphqlEndpoint: String) {
        self.dockerPath = dockerPath
        self.graphqlEndpoint = graphqlEndpoint
        var otherFailures = 0
        var gqlFailures = 0
        schemaToExample.sink { currentResults in
            var currentResults = currentResults
            guard let first = currentResults.first else {
                print("total other failures: \(otherFailures)")
                print("total gql failures: \(gqlFailures)")
                exit(0)
            }
            
            self.runExamples(first.value, for: first.key) { processedResults in

                let groups = Dictionary(grouping: processedResults, by: self.isSuccess(for: ))
                print("👍 total \(processedResults.count)\nresults: \(groups.mapValues{ $0.count })")
                if let failures = groups["otherError"] {
                    otherFailures = otherFailures + failures.count
                }
                if let failures = groups["gqlFailure"] {
                    gqlFailures = gqlFailures + failures.count
                }
                currentResults.removeValue(forKey: first.key)
                self.schemaToExample.send(currentResults)
                
            }
        }
        .store(in: &cancellables)
    }
    
    func isSuccess(for result: Result<String, Error>) -> String {
        switch result {
        case .success(_):
            return "success"
        case .failure(let error):
            if let _ = error as? GraphQLError {
                return "gqlFailure"
            }
            else {
                return "otherError"
            }
        }
    }
    
    func runExamples(_ examples: [GraphQLDatasetExample], for schema: String, completion: @escaping ([Result<String, Error>]) -> ()) { // todo add reason for failure
        let hash = Utilities.startHasura(name: schema, dockerPath: self.dockerPath)
        sleep(5)
        Publishers.Sequence(sequence: examples.map(runExample(example:)))
            .flatMap{ $0 }
            .collect()
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { (results) in
                //                print(results)'
                stopHasura(hash: hash, dockerPath: self.dockerPath, shouldRemove: true)
                print("Schema: \(schema)")
                sleep(1)
                
                completion(results)
                
            })
            .store(in: &cancellables)
        
        
    }
    
    func runExample(example: GraphQLDatasetExample) -> AnyPublisher<Result<String, Error>, Never> {
        var request = URLRequest(url: self.endPointURL)
        request.httpBody = try! encoder.encode(["query": example.query])
        request.httpMethod = "POST"
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { output -> Result<String, Error> in
                guard let response = output.response as? HTTPURLResponse else {
                    return Result.failure(HTTPError.noResponse)
                }
                guard response.statusCode == 200 else {
                    return Result.failure(HTTPError.code(response.statusCode))
                }
                if let error = try? decoder.decode(GraphQLError.self, from: output.data) {
                    return Result.failure(error)
                }
                return Result.success(String(data: output.data, encoding: .utf8)!)
        }
        .retry(2)
        .timeout(.seconds(3), scheduler: RunLoop.main)
        .catch{ Just(Result<String, Error>.failure(HTTPError.other($0))) }
        .eraseToAnyPublisher()
    }
    
}

// MARK: - GraphQLError
struct GraphQLError: Codable, Error { // specific to Hasura
    let errors: [ErrorElement]
}

// MARK: - Error
struct ErrorElement: Codable {
    let extensions: Extensions
    let message: String
}

// MARK: - Extensions
struct Extensions: Codable {
    let path, code: String
}

