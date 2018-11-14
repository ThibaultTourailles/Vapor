//
//  18-11-14-MakeCategoriesUnique.swift
//  App
//
//  Created by Thibault Tourailles on 14/11/2018.
//

import FluentPostgreSQL
import Vapor

struct MakeCategoriesUnique: Migration {

    typealias Database = PostgreSQLDatabase

    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.update(Category.self,on: connection) { builder in
            builder.unique(on: \.name)
        }
    }

    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.update(Category.self, on: connection) { builder in
            builder.deleteUnique(from: \.name)
        }
    }
}
