import Foundation

struct RegisterUserRequest: Codable {
    let apphud_id: String
}

struct RegisterUserResponse: Codable {
    let id: String
    let apphud_id: String
    let tokens: Int
}

struct AuthorizeUserRequest: Codable {
    let user_id: String
}

struct AuthorizeUserResponse: Codable {
    let access_token: String
    let token_type: String
}

