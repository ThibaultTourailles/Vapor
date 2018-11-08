import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    router.post("api", "acronyms") { req -> Future<Acronym> in
        return try req
            .content
            .decode(Acronym.self)
            .flatMap(to: Acronym.self) { acronym in
                return acronym.save(on: req)
            }
    }

    router.get("api", "acronyms") { req -> Future<[Acronym]> in
        return Acronym.query(on: req).all()
    }

    router.get("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        return try req.parameters.next(Acronym.self)
    }

    router.put("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        return try flatMap(
            to: Acronym.self,
            req.parameters.next(Acronym.self),
            req.content.decode(Acronym.self)) { acronym, updated in
                acronym.short = updated.short ?? acronym.short
                acronym.long = updated.long ?? acronym.long
                return acronym.save(on: req)
            }
    }

    router.delete("api", "acronyms", Acronym.parameter) { req -> Future<HTTPStatus> in
        return try req
            .parameters
            .next(Acronym.self)
            .delete(on: req)
            .transform(to: HTTPStatus.noContent)
    }

    router.get("api", "acronyms", "search") { req -> Future<[Acronym]> in
        guard let query = req.query[String.self, at: "q"] else { throw Abort(.badRequest) }
        return Acronym
            .query(on: req)
            .group(.or) { or in
                or.filter(\.short == query)
                or.filter(\.long == query)
            }
            .all()
    }

    router.get("api", "acronyms", "first") { req -> Future<Acronym> in
        return Acronym
            .query(on: req)
            .first()
            .map(to: Acronym.self) { acronym in
                guard let acronym = acronym else { throw Abort(.notFound) }
                return acronym
        }
    }

    router.get("api", "acronyms", "sorted") { req -> Future<[Acronym]> in
        return Acronym
            .query(on: req)
            .sort(\.short, .ascending)
            .all()
    }

}
