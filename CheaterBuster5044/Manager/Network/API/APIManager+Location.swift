import Foundation
import UIKit

extension APIManager {

    func searchLocation(image: UIImage, appBundle: String = "com.kam.5044cheater") async throws -> LocationTaskStatusResponse {
        if useMockData {
            print("APIManager: Using Mock Data for Location Search")
            try await Task.sleep(nanoseconds: 2_000_000_000)
            return try loadMockLocationData()
        }

        let taskId = try await uploadLocationImage(image, appBundle: appBundle)
        return try await pollLocationResults(taskId: taskId)
    }

    private func uploadLocationImage(_ image: UIImage, appBundle: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/task/place") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        authenticatedRequest(&request)

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")

        guard let imageData = image.jpegData(compressionQuality: 0.8) ?? image.pngData() else {
            throw URLError(.cannotDecodeContentData)
        }

        let body = createLocationMultipartBody(
            boundary: boundary,
            imageData: imageData,
            appBundle: appBundle
        )
        request.httpBody = body

        print("APIManager: Uploading location image...")
        let (data, response) = try await URLSession.shared.data(for: request)

        if let jsonString = String(data: data, encoding: .utf8) {
            print("APIManager: Upload Response: \(jsonString)")
        }

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decodedResponse = try JSONDecoder().decode(LocationTaskRequestResponse.self, from: data)
        return decodedResponse.id
    }

    private func pollLocationResults(taskId: String) async throws -> LocationTaskStatusResponse {
        var attempts = 0
        let maxAttempts = 60

        try await Task.sleep(nanoseconds: 2_000_000_000)

        while attempts < maxAttempts {
            attempts += 1
            print("APIManager: Polling location task \(taskId) (Attempt \(attempts))...")

            let result = try await getLocationTaskResult(taskId: taskId)

            if result.status == "finished" {
                return result
            }

            try await Task.sleep(nanoseconds: 1_000_000_000)
        }

        throw URLError(.timedOut)
    }

    private func getLocationTaskResult(taskId: String) async throws -> LocationTaskStatusResponse {
        guard let url = URL(string: "\(baseURL)/api/task/\(taskId)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        authenticatedRequest(&request)
        request.setValue("application/json", forHTTPHeaderField: "accept")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(LocationTaskStatusResponse.self, from: data)
    }

    private func loadMockLocationData() throws -> LocationTaskStatusResponse {
        guard let url = Bundle.main.url(forResource: "mockLocation", withExtension: "json") else {
            throw URLError(.fileDoesNotExist)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(LocationTaskStatusResponse.self, from: data)
    }

    private func createLocationMultipartBody(boundary: String, imageData: Data, appBundle: String) -> Data {
        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
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
