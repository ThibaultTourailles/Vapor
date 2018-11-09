//
//  UsersController.swift
//  App
//
//  Created by Thibault Tourailles on 08/11/2018.
//

import Vapor

struct UsersController: RouteCollection {

    func boot(router: Router) throws {
        let route = router.grouped("api", "users")
        route.post(User.self, use: createHandler)
        route.get(use: getAllHandler)
        route.get(User.parameter, use: getHandler)
        route.get(User.parameter, "acronyms", use: getAcronymsHandler)
    }

    // MARK: - Private

    private func createHandler(_ req: Request, user: User) throws -> Future<User> {
        return user.save(on: req)
    }

    private func getAllHandler(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }

    private func getHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(User.self)
    }

    private func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req
            .parameters
            .next(User.self)
            .flatMap(to: [Acronym].self) { user in
                try user.acronyms.query(on: req).all()
            }
    }
}
