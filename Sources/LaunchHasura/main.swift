//
//  main.swift
//  
//
//  Created by Andre Carrera on 4/7/20.
//

import Foundation
import Utilities

// Useful for adding a breakpoint and checking each instance one by one.

let dockerPath = "/usr/local/bin/docker"
for name in databaseNames{
    print(name)
    let hash = startHasura(name: name, dockerPath: dockerPath)
    stopHasura(hash: hash, dockerPath: dockerPath)
}

