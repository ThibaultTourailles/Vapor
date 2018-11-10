import Vapor
import Fluent

struct AcronymsController: RouteCollection {

    // MARK: - RouteCollection

    func boot(router: Router) throws {
        let route = router.grouped("api", "acronyms")
        route.get(use: getAllHandler)
        route.post(Acronym.self, use: createHandler)
        route.get(Acronym.parameter, use: getHandler)
        route.put(Acronym.parameter, use: updateHandler)
        route.delete(Acronym.parameter, use: deleteHandler)
        route.get("search", use: searchHandler)
        route.get("first", use: getFirstHandler)
        route.get("sorted", use: sortedHandler)
        route.get(Acronym.parameter, "user", use: getUserHandler)
        route.post(Acronym.parameter, "categories", Category.parameter, use: addCategoriesHandler)
        route.delete(Acronym.parameter, "categories", Category.parameter, use: removeCategoryHandler)
    }

    // MARK: - Private

    private func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }

    private func createHandler(_ req: Request, acronym: Acronym) throws -> Future<Acronym> {
        return acronym.save(on: req)
    }

    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }

    private func updateHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(
            to: Acronym.self,
            req.parameters.next(Acronym.self),
            req.content.decode(Acronym.self)
        ) { acronym, updated in
            acronym.short = updated.short ?? acronym.short
            acronym.long = updated.long ?? acronym.long
            acronym.userID = updated.userID
            return acronym.save(on: req)
        }
    }

    private func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(Acronym.self)
            .delete(on: req)
            .transform(to: HTTPStatus.noContent)
    }

    private func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let query = req.query[String.self, at: "q"] else { throw Abort(.badRequest) }
        return Acronym.query(on: req).group(.or) { or in
            or.filter(\.short == query)
            or.filter(\.long == query)
            }.all() }

    private func getFirstHandler(_ req: Request) throws -> Future<Acronym> {
        return Acronym.query(on: req)
            .first()
            .map(to: Acronym.self) { acronym in
                guard let acronym = acronym else { throw Abort(.notFound) }
                return acronym
            }
    }

    private func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).sort(\.short, .ascending).all()
    }

    private func getUserHandler(_ req: Request) throws -> Future<User> {
        return try req
            .parameters.next(Acronym.self)
            .flatMap(to: User.self) { acronym in
                acronym.user.get(on: req)
        }
    }

    private func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(
            to: HTTPStatus.self,
            req.parameters.next(Acronym.self),
            req.parameters.next(Category.self)) { acronym, category in
                return acronym.categories
                    .attach(category, on: req)
                    .transform(to: .created)
        }
    }

    private func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req
            .parameters
            .next(Acronym.self)
            .flatMap(to: [Category].self) { acronym in
                try acronym.categories.query(on: req).all()
        }
    }

    private func removeCategoryHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(
            to: HTTPStatus.self,
            req.parameters.next(Acronym.self),
            req.parameters.next(Category.self)
        ) { acronym, category in
            return acronym
                .categories
                .detach(category, on: req)
                .transform(to: .noContent)
        }
    }
}
