//
//  CategoriesController.swift
//  App
//
//  Created by Thibault Tourailles on 09/11/2018.
//

import Vapor

struct CategoriesController: RouteCollection {

    func boot(router: Router) throws {
        let route = router.grouped("api", "categories")
        route.get(use: getAllHandler)
        route.get(Category.parameter, use: getHandler)
        route.get(Category.parameter, "acronyms", use: getAcronymsHandler)

        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let protected = route.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        protected.post(Category.self, use: createHandler)
    }

    // MARK: - Private

    private func createHandler(_ req: Request, category: Category) throws -> Future<Category> {
        return category.save(on: req)
    }

    private func getAllHandler(_ req: Request) throws -> Future<[Category]> {
        return Category.query(on: req).all()
    }

    private func getHandler(_ req: Request) throws -> Future<Category> {
        return try req.parameters.next(Category.self)
    }

    private func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req
            .parameters
            .next(Category.self)
            .flatMap(to: [Acronym].self) { category in
                try category.acronyms.query(on: req).all()
        }
    }
}
