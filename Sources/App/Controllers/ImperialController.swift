//
//  ImperialController.swift
//  App
//
//  Created by Thibault Tourailles on 14/11/2018.
//

import Vapor
import Imperial
import Authentication

struct ImperialController: RouteCollection {

    func boot(router: Router) throws {
        guard let callback = Environment.get("GOOGLE_CALLBACK_URL") else { fatalError("Callback URL not set") }
        try router.oAuth(
            from: Google.self,
            authenticate: "login-google",
            callback: callback,
            scope: ["profile", "email"],
            completion: processGoogleLogin
        )
    }

    // MARK: - Private

    private func processGoogleLogin(request: Request, token: String) throws -> Future<ResponseEncodable> {
        return request.future(request.redirect(to: "/"))
//        return try Google
//            .getUser(on: request)
//            .flatMap(to: ResponseEncodable.self) { userInfo in
//                return User
//                    .query(on: request)
//                    .filter(\.username == userInfo.email)
//                    .first()
//                    .flatMap(to: ResponseEncodable.self) { foundUser in
//                        guard let existingUser = foundUser else {
//                            let user = User(
//                                name: userInfo.email,
//                                username: userInfo.email,
//                                password: ""
//                            )
//                            return user
//                                .save(on: request)
//                                .map(to: ResponseEncodable.self) { user in
//                                    try request.authenticateSession(user)
//                                    return request.redirect(to: "/")
//                            }
//                        }
//                        try request.authenticateSession(existingUser)
//                        return request.future(request.redirect(to: "/"))
//                }
//        }
    }
}

struct GoogleUserInfo: Content {
    let email: String
    let name: String
}

extension Google {

    static func getUser(on request: Request) throws -> Future<GoogleUserInfo> {
        var headers = HTTPHeaders()
        headers.bearerAuthorization = try BearerAuthorization(token: request.accessToken())
        let url = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
        return try request
            .client()
            .get(url, headers: headers)
            .map(to: GoogleUserInfo.self) { response in
                switch response.http.status {
                case .unauthorized:
                    throw Abort.redirect(to: "/login-google")
                case .ok:
                    break
                default:
                    throw Abort(.internalServerError)
                }
                return try response
                    .content
                    .syncDecode(GoogleUserInfo.self)
        }
    }
}
