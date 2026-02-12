import Foundation
import UIKit

extension APIManager {

    enum RemoveBackgroundError: LocalizedError {
        case invalidURL
        case cannotEncodeImage
        case invalidResponse
        case httpError(statusCode: Int, message: String?)
        case invalidImageData

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid REMBG URL."
            case .cannotEncodeImage:
                return "Cannot encode image for upload."
            case .invalidResponse:
                return "Invalid server response."
            case let .httpError(code, message):
                if let message, !message.isEmpty {
                    return "REMBG failed (\(code)): \(message)"
                } else {
                    return "REMBG failed (\(code))."
                }
            case .invalidImageData:
                return "REMBG returned invalid image data."
            }
        }
    }

    
    func removeBackground(image: UIImage) async throws -> UIImage {
        guard let url = URL(string: "\(rembgBaseURL)/rembg") else {
            throw RemoveBackgroundError.invalidURL
        }

        
        guard let imageData = image.pngData() else {
            throw RemoveBackgroundError.cannotEncodeImage
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("*/*", forHTTPHeaderField: "accept")

        request.httpBody = createRembgMultipartBody(
            boundary: boundary,
            fileData: imageData,
            fieldName: "file",
            fileName: "image.png",
            mimeType: "image/png"
        )

        print("🧩 REMBG: uploading \(imageData.count) bytes...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            print("🔴 REMBG: invalid response (no HTTPURLResponse)")
            throw RemoveBackgroundError.invalidResponse
        }

        if (200...299).contains(http.statusCode) {
            print("✅ REMBG: success, received \(data.count) bytes")
            guard let out = UIImage(data: data) else {
                print("🔴 REMBG: received data but cannot decode UIImage")
                throw RemoveBackgroundError.invalidImageData
            }
            return out
        } else {
            let message = decodeRembgErrorMessage(from: data)
            print("🔴 REMBG: failed status=\(http.statusCode) message=\(message ?? "nil")")
            throw RemoveBackgroundError.httpError(statusCode: http.statusCode, message: message)
        }
    }

    private func createRembgMultipartBody(
        boundary: String,
        fileData: Data,
        fieldName: String,
        fileName: String,
        mimeType: String
    ) -> Data {
        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    private struct RembgHTTPValidationError: Decodable {
        struct DetailItem: Decodable {
            let loc: [RembgLocValue]?
            let msg: String?
            let type: String?
        }
        let detail: [DetailItem]?
    }

    private enum RembgLocValue: Decodable {
        case string(String)
        case int(Int)

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let i = try? c.decode(Int.self) {
                self = .int(i)
                return
            }
            if let s = try? c.decode(String.self) {
                self = .string(s)
                return
            }
            self = .string("unknown")
        }
    }

    private func decodeRembgErrorMessage(from data: Data) -> String? {
        
        if let decoded = try? JSONDecoder().decode(RembgHTTPValidationError.self, from: data),
           let first = decoded.detail?.first {
            if let msg = first.msg, !msg.isEmpty { return msg }
        }

        
        if let s = String(data: data, encoding: .utf8), !s.isEmpty {
            return s
        }
        return nil
    }
}
