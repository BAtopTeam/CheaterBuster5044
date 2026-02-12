import Foundation

struct LocationTaskRequestResponse: Codable {
    let id: String
    let status: String
    let result: String?
    let error: String?
}

struct LocationTaskStatusResponse: Codable {
    let id: String
    let status: String
    let result: String?
    let error: String?
}

