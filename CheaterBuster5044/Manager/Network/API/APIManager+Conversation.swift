import Foundation
import UIKit

extension APIManager {

    func analyzeConversation(image: UIImage, appBundle: String = "com.kam.5044cheater") async throws -> TaskStatusResponse {
        if useMockData {
            print("APIManager: Using Mock Data for Conversation Analysis")
            try await Task.sleep(nanoseconds: 2_000_000_000)
            return try loadMockConversationData()
        }

        let taskId = try await uploadConversationImage(image, appBundle: appBundle)
        return try await pollConversationResults(taskId: taskId)
    }

    private func uploadConversationImage(_ image: UIImage, appBundle: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/task") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        authenticatedRequest(&request)

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")

        guard let imageData = image.pngData() ?? image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.cannotDecodeContentData)
        }

        let body = createConversationMultipartBody(
            boundary: boundary,
            imageData: imageData,
            appBundle: appBundle
        )
        request.httpBody = body

        print("APIManager: Uploading conversation image...")
        let (data, response) = try await URLSession.shared.data(for: request)

        if let jsonString = String(data: data, encoding: .utf8) {
            print("APIManager: Upload Response: \(jsonString)")
        }

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decodedResponse = try JSONDecoder().decode(TaskRequestResponse.self, from: data)
        return decodedResponse.id
    }

    private func pollConversationResults(taskId: String) async throws -> TaskStatusResponse {
        var attempts = 0
        let maxAttempts = 60

        try await Task.sleep(nanoseconds: 2_000_000_000)

        while attempts < maxAttempts {
            attempts += 1
            print("APIManager: Polling conversation task \(taskId) (Attempt \(attempts))...")

            let result = try await getConversationTaskResult(taskId: taskId)

            if result.status == "finished" {
                return result
            }

            try await Task.sleep(nanoseconds: 1_000_000_000)
        }

        throw URLError(.timedOut)
    }

    
    private func getConversationTaskResult(taskId: String) async throws -> TaskStatusResponse {
        guard let url = URL(string: "\(baseURL)/api/task/\(taskId)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        authenticatedRequest(&request)
        request.setValue("application/json", forHTTPHeaderField: "accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        #if DEBUG
        if let http = response as? HTTPURLResponse {
            print("⬇️ /api/task/\(taskId) HTTP \(http.statusCode)")
        }

        if let pretty = prettyPrintedJSON(from: data) {
            print("⬇️ Raw backend JSON:\n\(pretty)")
        } else if let text = String(data: data, encoding: .utf8) {
            print("⬇️ Raw backend (not JSON?):\n\(text)")
        } else {
            print("⬇️ Raw backend bytes count: \(data.count)")
        }
        #endif

        return try JSONDecoder().decode(TaskStatusResponse.self, from: data)
    }

    #if DEBUG
    private func prettyPrintedJSON(from data: Data) -> String? {
        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
            return String(data: prettyData, encoding: .utf8)
        } catch {
            return nil
        }
    }
    #endif


    private func loadMockConversationData() throws -> TaskStatusResponse {
        guard let url = Bundle.main.url(forResource: "mockCheater", withExtension: "json") else {
            throw URLError(.fileDoesNotExist)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(TaskStatusResponse.self, from: data)
    }

    private func createConversationMultipartBody(boundary: String, imageData: Data, appBundle: String) -> Data {
        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"conversation\"\r\n\r\n".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"app_bundle\"\r\n\r\n".data(using: .utf8)!)
        body.append(appBundle.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"webhook_url\"\r\n\r\n".data(using: .utf8)!)
        body.append("https://example.com/".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}
