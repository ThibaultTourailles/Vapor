//
//  UsersController.swift
//  App
//
//  Created by Thibault Tourailles on 08/11/2018.
//

import Vapor
import Crypto

struct UsersController: RouteCollection {

    func boot(router: Router) throws {
        let route = router.grouped("api", "users")
        route.post(User.self, use: createHandler)
        route.get(use: getAllHandler)
        route.get(User.parameter, use: getHandler)
        route.get(User.parameter, "acronyms", use: getAcronymsHandler)

        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup = route.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
    }

    // MARK: - Private

    private func createHandler(_ req: Request, user: User) throws -> Future<User.Public> {
        user.password = try BCrypt.hash(user.password)
        return user.save(on: req).convertToPublic()
    }

    private func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return User.query(on: req).decode(data: User.Public.self).all()
    }

    private func getHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(User.self).convertToPublic()
    }

    private func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req
            .parameters
            .next(User.self)
            .flatMap(to: [Acronym].self) { user in
                try user.acronyms.query(on: req).all()
            }
    }

    private func loginHandler(_ req: Request) throws -> Future<Token> {
        let user = try req.requireAuthenticated(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req)
    }
}
