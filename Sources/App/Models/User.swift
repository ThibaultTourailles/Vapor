//
//  User.swift
//  App
//
//  Created by Thibault Tourailles on 08/11/2018.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

final class User: Codable {
    var id: UUID?
    var name: String
    var username: String
    var password: String

    init(name: String, username: String, password: String) {
        self.name = name
        self.username = username
        self.password = password
    }

    final class Public: Codable {
        var id: UUID?
        var name: String
        var username: String

        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Parameter {}
extension User.Public: Content {}

extension User {
    var acronyms: Children<User, Acronym> {
        return children(\.userID)
    }
}

extension User: Migration {

    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.unique(on: \.username)
        }
    }
}

extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username)
    }
}

extension Future where T: User {
    func convertToPublic() -> Future<User.Public> {
        return self.map(to: User.Public.self) { user in
            return user.convertToPublic()
        }
    }
}

extension User: BasicAuthenticatable {
    static let usernameKey: UsernameKey = \User.username
    static let passwordKey: PasswordKey = \User.password
}

extension User: TokenAuthenticatable {
    typealias TokenType = Token
}

extension User: SessionAuthenticatable {}

struct AdminUser: Migration {
    typealias Database = PostgreSQLDatabase

    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        guard let password = try? BCrypt.hash("password") else { fatalError("Failed to create admin user") }
        let admin = User(
            name: "Admin",
            username: "Admin",
            password: password
        )
        return admin.save(on: connection).transform(to: ())
    }

    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return .done(on: connection)
    }
}
