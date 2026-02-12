import Foundation

struct CheaterBusterTaskRequestResponse: Decodable {
    let task_id: String
}

struct CheaterBusterTaskResponse: Decodable {
    let status: [String: String]?
    let results: [String: CheaterBusterEngineResult]?

    private enum CodingKeys: String, CodingKey {
        case status
        case results
        case visual_matches
        case image_results
        case images_results
        case data
        case result
    }

    init(status: [String: String]?, results: [String: CheaterBusterEngineResult]?) {
        self.status = status
        self.results = results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var normalizedStatus: [String: String] = [:]
        var normalizedResults: [String: CheaterBusterEngineResult] = [:]

        if let statusMap = try? container.decode([String: String].self, forKey: .status) {
            normalizedStatus.merge(statusMap, uniquingKeysWith: { _, new in new })
        } else if let singleStatus = try? container.decode(String.self, forKey: .status) {
            normalizedStatus["default"] = singleStatus
        }

        if let resultsMap = try? container.decode([String: CheaterBusterEngineResult].self, forKey: .results) {
            normalizedResults.merge(resultsMap, uniquingKeysWith: { _, new in new })
        } else if let singleEngine = try? container.decode(CheaterBusterEngineResult.self, forKey: .results) {
            normalizedResults["default"] = singleEngine
        } else if let matches = try? container.decode([CheaterBusterVisualMatch].self, forKey: .results) {
            normalizedResults["default"] = CheaterBusterEngineResult(visual_matches: matches)
        }

        if let visualMatches = try? container.decode([CheaterBusterVisualMatch].self, forKey: .visual_matches) {
            normalizedResults["default"] = CheaterBusterEngineResult(visual_matches: visualMatches)
        } else if let imageResults = try? container.decode([CheaterBusterVisualMatch].self, forKey: .image_results) {
            normalizedResults["default"] = CheaterBusterEngineResult(visual_matches: imageResults)
        } else if let imagesResults = try? container.decode([CheaterBusterVisualMatch].self, forKey: .images_results) {
            normalizedResults["default"] = CheaterBusterEngineResult(visual_matches: imagesResults)
        }

        if let nestedData = try? container.decode(CheaterBusterTaskResponse.self, forKey: .data) {
            if let nestedStatus = nestedData.status {
                normalizedStatus.merge(nestedStatus, uniquingKeysWith: { _, new in new })
            }
            if let nestedResults = nestedData.results {
                normalizedResults.merge(nestedResults, uniquingKeysWith: { _, new in new })
            }
        }

        if let nestedResult = try? container.decode(CheaterBusterTaskResponse.self, forKey: .result) {
            if let nestedStatus = nestedResult.status {
                normalizedStatus.merge(nestedStatus, uniquingKeysWith: { _, new in new })
            }
            if let nestedResults = nestedResult.results {
                normalizedResults.merge(nestedResults, uniquingKeysWith: { _, new in new })
            }
        }

        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
        let reservedKeys: Set<String> = [
            CodingKeys.status.rawValue,
            CodingKeys.results.rawValue,
            CodingKeys.visual_matches.rawValue,
            CodingKeys.image_results.rawValue,
            CodingKeys.images_results.rawValue,
            CodingKeys.data.rawValue,
            CodingKeys.result.rawValue,
            "task_id",
            "message",
            "error"
        ]

        for key in dynamicContainer.allKeys where !reservedKeys.contains(key.stringValue) {
            if let engineResult = try? dynamicContainer.decode(CheaterBusterEngineResult.self, forKey: key) {
                normalizedResults[key.stringValue] = engineResult
                continue
            }
            if let matches = try? dynamicContainer.decode([CheaterBusterVisualMatch].self, forKey: key) {
                normalizedResults[key.stringValue] = CheaterBusterEngineResult(visual_matches: matches)
                continue
            }
            if let statusValue = try? dynamicContainer.decode(String.self, forKey: key) {
                normalizedStatus[key.stringValue] = statusValue
            }
        }

        status = normalizedStatus.isEmpty ? nil : normalizedStatus
        results = normalizedResults.isEmpty ? nil : normalizedResults
    }
}

struct CheaterBusterEngineResult: Decodable {
    let visual_matches: [CheaterBusterVisualMatch]?

    private enum CodingKeys: String, CodingKey {
        case visual_matches
        case image_results
        case images_results
        case items
        case result
        case data
    }

    init(visual_matches: [CheaterBusterVisualMatch]?) {
        self.visual_matches = visual_matches
    }

    init(from decoder: Decoder) throws {
        if let singleValueContainer = try? decoder.singleValueContainer(),
           let directMatches = try? singleValueContainer.decode([CheaterBusterVisualMatch].self) {
            visual_matches = directMatches
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let matches = try? container.decode([CheaterBusterVisualMatch].self, forKey: .visual_matches) {
            visual_matches = matches
        } else if let matches = try? container.decode([CheaterBusterVisualMatch].self, forKey: .image_results) {
            visual_matches = matches
        } else if let matches = try? container.decode([CheaterBusterVisualMatch].self, forKey: .images_results) {
            visual_matches = matches
        } else if let matches = try? container.decode([CheaterBusterVisualMatch].self, forKey: .items) {
            visual_matches = matches
        } else if let matches = try? container.decode([CheaterBusterVisualMatch].self, forKey: .result) {
            visual_matches = matches
        } else if let matches = try? container.decode([CheaterBusterVisualMatch].self, forKey: .data) {
            visual_matches = matches
        } else {
            visual_matches = nil
        }
    }
}

struct CheaterBusterVisualMatch: Decodable {
    let position: Int?
    let title: String?
    let link: String?
    let source: String?
    let source_icon: String?
    let thumbnail: String?
    let image: String?
    let thumbnail_width: Int?
    let thumbnail_height: Int?
    let image_width: Int?
    let image_height: Int?

    private enum CodingKeys: String, CodingKey {
        case position
        case title
        case link
        case source
        case source_icon
        case sourceIcon
        case thumbnail
        case image
        case thumbnail_width
        case thumbnailWidth
        case thumbnail_height
        case thumbnailHeight
        case image_width
        case imageWidth
        case image_height
        case imageHeight
        case url
    }

    private struct NestedImage: Decodable {
        let link: String?
        let url: String?
        let serpapi_link: String?
        let height: Int?
        let width: Int?
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        position = try? container.decode(Int.self, forKey: .position)
        title = try? container.decode(String.self, forKey: .title)
        link = (try? container.decode(String.self, forKey: .link))
            ?? (try? container.decode(String.self, forKey: .url))
        source = try? container.decode(String.self, forKey: .source)
        source_icon = (try? container.decode(String.self, forKey: .source_icon))
            ?? (try? container.decode(String.self, forKey: .sourceIcon))
        thumbnail = try? container.decode(String.self, forKey: .thumbnail)
        let imageString = try? container.decode(String.self, forKey: .image)
        let nestedImage = try? container.decode(NestedImage.self, forKey: .image)
        image = imageString ?? nestedImage?.link ?? nestedImage?.url
        thumbnail_width = (try? container.decode(Int.self, forKey: .thumbnail_width))
            ?? (try? container.decode(Int.self, forKey: .thumbnailWidth))
            ?? nestedImage?.width
        thumbnail_height = (try? container.decode(Int.self, forKey: .thumbnail_height))
            ?? (try? container.decode(Int.self, forKey: .thumbnailHeight))
            ?? nestedImage?.height
        image_width = (try? container.decode(Int.self, forKey: .image_width))
            ?? (try? container.decode(Int.self, forKey: .imageWidth))
            ?? nestedImage?.width
        image_height = (try? container.decode(Int.self, forKey: .image_height))
            ?? (try? container.decode(Int.self, forKey: .imageHeight))
            ?? nestedImage?.height
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        stringValue = String(intValue)
        self.intValue = intValue
    }
}
