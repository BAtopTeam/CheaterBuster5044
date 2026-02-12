import Foundation
import UIKit

extension APIManager {

    func fetchCheaterBuster(image: UIImage) async throws -> CheaterBusterTaskResponse {
        if useMockData {
            print("APIManager: Using Mock Data for CheaterBuster")
            try await Task.sleep(nanoseconds: 2_000_000_000)
            return try loadMockCheaterBusterData()
        }

        let taskId = try await uploadCheaterBusterImage(image)
        return try await pollCheaterBusterResults(taskId: taskId)
    }

    private func uploadCheaterBusterImage(_ image: UIImage) async throws -> String {
        guard let url = URL(string: "https://api.cheatersearch.space/task") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("mHwbaeKRIL8I1WRycD9X82Gpa8KltT8eTxX6qHe931SnVhfDY5FQG18QVEDVG96Y", forHTTPHeaderField: "X-Api-Key")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")

        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw URLError(.cannotDecodeContentData)
        }

        request.httpBody = createCheaterBusterMultipartBody(
            boundary: boundary,
            imageData: imageData
        )

        print("APIManager: Uploading CheaterBuster image...")
        let (data, response) = try await URLSession.shared.data(for: request)

        if let jsonString = String(data: data, encoding: .utf8) {
            print("APIManager: Upload Response: \(jsonString)")
        }

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decodedResponse = try JSONDecoder().decode(CheaterBusterTaskRequestResponse.self, from: data)
        return decodedResponse.task_id
    }

    private func pollCheaterBusterResults(taskId: String) async throws -> CheaterBusterTaskResponse {
        var attempts = 0
        let maxAttempts = 120

        try await Task.sleep(nanoseconds: 5_000_000_000)

        while attempts < maxAttempts {
            attempts += 1
            print("APIManager: Polling CheaterBuster task \(taskId) (Attempt \(attempts))...")

            let result = try await getCheaterBusterTaskResult(taskId: taskId)

            if isCheaterBusterCompleted(result) {
                return result
            }

            try await Task.sleep(nanoseconds: 1_000_000_000)
        }

        throw URLError(.timedOut)
    }

    private func getCheaterBusterTaskResult(taskId: String) async throws -> CheaterBusterTaskResponse {
        guard let url = URL(string: "https://api.cheatersearch.space/task/\(taskId)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("mHwbaeKRIL8I1WRycD9X82Gpa8KltT8eTxX6qHe931SnVhfDY5FQG18QVEDVG96Y", forHTTPHeaderField: "X-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        #if DEBUG
        if let http = response as? HTTPURLResponse {
            print("⬇️ /task/\(taskId) HTTP \(http.statusCode)")
        }
        #endif

        return try JSONDecoder().decode(CheaterBusterTaskResponse.self, from: data)
    }

    private func loadMockCheaterBusterData() throws -> CheaterBusterTaskResponse {
        guard let url = Bundle.main.url(forResource: "mockCheaterBuster", withExtension: "json") else {
            throw URLError(.fileDoesNotExist)
        }
        let data = try Data(contentsOf: url)
        return try buildMockCheaterBusterResponse(from: data)
    }

    private func createCheaterBusterMultipartBody(boundary: String, imageData: Data) -> Data {
        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    private func isCheaterBusterCompleted(_ response: CheaterBusterTaskResponse) -> Bool {
        if let status = response.status, !status.isEmpty {
            return status.values.allSatisfy { value in
                let normalized = value.lowercased()
                return normalized == "completed" || normalized == "success"
            }
        }
        return response.results != nil
    }

    private func buildMockCheaterBusterResponse(from data: Data) throws -> CheaterBusterTaskResponse {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return try JSONDecoder().decode(CheaterBusterTaskResponse.self, from: data)
        }

        let statusMap = parseStatusMap(from: root["status"])
        guard let resultsRaw = root["results"] as? [String: Any] else {
            return try JSONDecoder().decode(CheaterBusterTaskResponse.self, from: data)
        }

        let googleRaw = resultsRaw["google"] as? [String: Any] ?? [:]
        let yandexRaw = resultsRaw["yandex"] as? [String: Any] ?? [:]
        let bingRaw = resultsRaw["bing"] as? [String: Any] ?? [:]

        let googleMatches = parseGoogleMatches(from: googleRaw)
        let bingMatches = parseBingMatches(from: bingRaw)
        let yandexMatches = parseYandexMatches(from: yandexRaw)

        var normalizedResults: [String: CheaterBusterEngineResult] = [:]
        if googleMatches.isEmpty == false {
            normalizedResults["google"] = CheaterBusterEngineResult(visual_matches: googleMatches)
        }
        if bingMatches.isEmpty == false {
            normalizedResults["bing"] = CheaterBusterEngineResult(visual_matches: bingMatches)
        }
        if yandexMatches.isEmpty == false {
            normalizedResults["yandex"] = CheaterBusterEngineResult(visual_matches: yandexMatches)
        }

        if normalizedResults.isEmpty {
            return try JSONDecoder().decode(CheaterBusterTaskResponse.self, from: data)
        }

        return CheaterBusterTaskResponse(
            status: statusMap.isEmpty ? nil : statusMap,
            results: normalizedResults
        )
    }

    private func parseGoogleMatches(from payload: [String: Any]) -> [CheaterBusterVisualMatch] {
        parseMatches(
            from: payload,
            preferredKeys: ["visual_matches", "image_results", "images_results", "items", "result", "data"],
            fallbackSource: "Google",
            category: "google"
        )
    }

    private func parseYandexMatches(from payload: [String: Any]) -> [CheaterBusterVisualMatch] {
        parseMatches(
            from: payload,
            preferredKeys: ["image_results", "images_results", "visual_matches", "items", "result", "data"],
            fallbackSource: "Yandex",
            category: "yandex"
        )
    }

    private func parseBingMatches(from payload: [String: Any]) -> [CheaterBusterVisualMatch] {
        parseMatches(
            from: payload,
            preferredKeys: ["images_results", "image_results", "visual_matches", "items", "result", "data"],
            fallbackSource: "Bing",
            category: "bing"
        )
    }

    private func parseMatches(
        from payload: [String: Any],
        preferredKeys: [String],
        fallbackSource: String,
        category: String
    ) -> [CheaterBusterVisualMatch] {
        let rawItems = self.extractMatchItems(from: payload, preferredKeys: preferredKeys)
        guard rawItems.isEmpty == false else {
            logParsingEmpty(category: category, payload: payload, preferredKeys: preferredKeys)
            return []
        }

        let decoder = JSONDecoder()
        let matches: [CheaterBusterVisualMatch] = rawItems.compactMap { item -> CheaterBusterVisualMatch? in
            var normalized = normalizeRawMatch(item)
            if normalized["source"] == nil {
                normalized["source"] = fallbackSource
            }

            guard let data = try? JSONSerialization.data(withJSONObject: normalized) else {
                return nil
            }
            return try? decoder.decode(CheaterBusterVisualMatch.self, from: data)
        }

        logParsingResult(category: category, rawItems: rawItems, matches: matches)
        return matches
    }

    private func extractMatchItems(from payload: [String: Any], preferredKeys: [String]) -> [[String: Any]] {
        for key in preferredKeys {
            if let array = payload[key] as? [[String: Any]], !array.isEmpty {
                return array
            }
            if let nested = payload[key] as? [String: Any] {
                for nestedKey in preferredKeys {
                    if let nestedArray = nested[nestedKey] as? [[String: Any]], !nestedArray.isEmpty {
                        return nestedArray
                    }
                }
            }
        }

        if let recursive = findFirstCandidateArray(in: payload), recursive.isEmpty == false {
            return recursive
        }

        return []
    }

    private func findFirstCandidateArray(in value: Any) -> [[String: Any]]? {
        if let array = value as? [[String: Any]], array.contains(where: isLikelyMatchItem) {
            return array
        }

        if let dictionary = value as? [String: Any] {
            for child in dictionary.values {
                if let found = findFirstCandidateArray(in: child) {
                    return found
                }
            }
            return nil
        }

        if let array = value as? [Any] {
            for child in array {
                if let found = findFirstCandidateArray(in: child) {
                    return found
                }
            }
            return nil
        }

        return nil
    }

    private func isLikelyMatchItem(_ item: [String: Any]) -> Bool {
        if item["thumbnail"] != nil || item["image"] != nil || item["link"] != nil || item["url"] != nil {
            return true
        }
        if let image = item["image"] as? [String: Any], image["link"] != nil || image["url"] != nil {
            return true
        }
        return false
    }

    private func normalizeRawMatch(_ item: [String: Any]) -> [String: Any] {
        var normalized = item

        let thumbnail = stringValue(
            in: normalized,
            keys: ["thumbnail", "thumbnail_url", "thumbnailUrl", "thumb", "preview", "preview_url"]
        )
        let image = stringValue(
            in: normalized,
            keys: ["image", "image_url", "imageUrl", "content_url", "contentUrl", "original", "original_url"]
        )
        let link = stringValue(in: normalized, keys: ["link", "url"])

        if normalized["thumbnail"] == nil, let thumbnail {
            normalized["thumbnail"] = thumbnail
        }

        if normalized["image"] == nil, let image {
            normalized["image"] = image
        }

        if normalized["image"] == nil,
           let link,
           let imageFromLink = extractImageURLFromQuery(link: link, key: "img_url") {
            normalized["image"] = imageFromLink
        }

        if normalized["image"] == nil, let thumbnail {
            normalized["image"] = thumbnail
        }

        if normalized["thumbnail"] == nil, let image {
            normalized["thumbnail"] = image
        } else if normalized["thumbnail"] == nil,
                  let image = normalized["image"] as? String {
            normalized["thumbnail"] = image
        }

        if let imageObject = normalized["image"] as? [String: Any] {
            let imageFromObject = stringValue(in: imageObject, keys: ["link", "url"])
            normalized["image"] = imageFromObject
            if normalized["thumbnail"] == nil {
                normalized["thumbnail"] = stringValue(in: imageObject, keys: ["thumbnail", "thumbnail_url", "preview"])
            }
        }

        if let thumbnailObject = normalized["thumbnail"] as? [String: Any] {
            normalized["thumbnail"] = stringValue(in: thumbnailObject, keys: ["link", "url", "thumbnail"])
        }

        return normalized
    }

    private func stringValue(in dict: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dict[key] as? String, value.isEmpty == false {
                return value
            }
            if let object = dict[key] as? [String: Any] {
                if let value = object["link"] as? String, value.isEmpty == false {
                    return value
                }
                if let value = object["url"] as? String, value.isEmpty == false {
                    return value
                }
            }
        }
        return nil
    }

    private func extractImageURLFromQuery(link: String, key: String) -> String? {
        guard let components = URLComponents(string: link),
              let queryItems = components.queryItems
        else { return nil }

        return queryItems.first(where: { $0.name == key })?.value
    }

    private func parseStatusMap(from value: Any?) -> [String: String] {
        if let status = value as? [String: String] {
            return status
        }
        if let status = value as? String {
            return ["default": status]
        }
        return [:]
    }

    private func logParsingEmpty(category: String, payload: [String: Any], preferredKeys: [String]) {
#if DEBUG
        let keys = payload.keys.sorted().joined(separator: ", ")
        print("CheaterBuster mock parse [\(category)]: rawItems = 0")
        print("CheaterBuster mock parse [\(category)]: payload keys = [\(keys)]")
        print("CheaterBuster mock parse [\(category)]: preferred keys = \(preferredKeys)")
#endif
    }

    private func logParsingResult(
        category: String,
        rawItems: [[String: Any]],
        matches: [CheaterBusterVisualMatch]
    ) {
#if DEBUG
        print("CheaterBuster mock parse [\(category)]: rawItems = \(rawItems.count), decoded = \(matches.count)")
        if let firstRaw = rawItems.first {
            let firstRawLink = (firstRaw["link"] as? String) ?? (firstRaw["url"] as? String) ?? "nil"
            let firstRawImageLink = (firstRaw["image"] as? [String: Any])?["link"] as? String
            let firstRawThumb = firstRaw["thumbnail"] as? String
            print("CheaterBuster mock parse [\(category)] first raw: link=\(firstRawLink), image.link=\(firstRawImageLink ?? "nil"), thumbnail=\(firstRawThumb ?? "nil")")
        }
        if let first = matches.first {
            print("CheaterBuster mock parse [\(category)] first decoded: source=\(first.source ?? "nil"), link=\(first.link ?? "nil"), image=\(first.image ?? "nil"), thumbnail=\(first.thumbnail ?? "nil")")
        }
#endif
    }
}
