import Foundation

struct TaskRequestResponse: Codable {
    let id: String
    let status: String
    let result: ConversationResult?
    let error: String?
}

struct TaskStatusResponse: Codable {
    let id: String
    let status: String
    let result: ConversationResult?
    let error: String?
}

struct ConversationResult: Codable {
    let risk_score: Int
    let red_flags: [String]
    let recommendations: [String]
}

