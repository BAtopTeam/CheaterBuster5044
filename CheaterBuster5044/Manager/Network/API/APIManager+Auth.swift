import Foundation

extension APIManager {

    func authenticatedRequest(_ request: inout URLRequest) {
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    func authenticate(apphudID: String) async {
        guard accessToken == nil else {
            print("APIManager: Already authenticated. Token exists.")
            return
        }

        print("APIManager: Starting authentication flow with Apphud ID: \(apphudID)")

        do {
            let userId = try await registerUser(apphudID: apphudID)

            let token = try await authorizeUser(userID: userId)

            await MainActor.run {
                self.userID = userId
                self.accessToken = token
            }

            print("APIManager: Authentication successful. Token received.")
        } catch {
            print("APIManager: Authentication failed: \(error)")
        }
    }

    private func registerUser(apphudID: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/user") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")

        let body = RegisterUserRequest(apphud_id: apphudID)
        request.httpBody = try JSONEncoder().encode(body)

        print("APIManager: Registering User...")
        let (data, response) = try await URLSession.shared.data(for: request)

        if let jsonString = String(data: data, encoding: .utf8) {
            print("APIManager: Register Response: \(jsonString)")
        }

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decodedResponse = try JSONDecoder().decode(RegisterUserResponse.self, from: data)
        return decodedResponse.id
    }

    private func authorizeUser(userID: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/user/authorize") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")

        let body = AuthorizeUserRequest(user_id: userID)
        request.httpBody = try JSONEncoder().encode(body)

        print("APIManager: Authorizing User...")
        let (data, response) = try await URLSession.shared.data(for: request)

        if let jsonString = String(data: data, encoding: .utf8) {
            print("APIManager: Authorize Response: \(jsonString)")
        }

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decodedResponse = try JSONDecoder().decode(AuthorizeUserResponse.self, from: data)
        return decodedResponse.access_token
    }
}
