import SwiftData
import SwiftUI
import Foundation

@Model
class PersonResultEntity {
    var id: UUID
    var date: Date
    var customName: String?
    var userVoted: Bool
    @Relationship(deleteRule: .cascade) var foundPeople: [PersonEntity]

    
    @Attribute(.externalStorage) var queryImageData: Data?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        customName: String? = nil,
        userVoted: Bool = false,
        foundPeople: [PersonEntity] = [],
        queryImageData: Data? = nil
    ) {
        self.id = id
        self.date = date
        self.customName = customName
        self.userVoted = userVoted
        self.foundPeople = foundPeople
        self.queryImageData = queryImageData
    }

    var queryUIImage: UIImage? {
        guard let data = queryImageData else { return nil }
        return UIImage(data: data)
    }
}

@Model
class PersonEntity {
    var name: String
    @Attribute(.externalStorage) var imageData: Data?
    @Attribute(.externalStorage) var faviconData: Data?
    var imageURLString: String?
    var faviconURLString: String?

    var linkURLString: String?
    var sourceText: String?
    var siteHost: String?

    init(
        name: String,
        imageData: Data? = nil,
        faviconData: Data? = nil,
        imageURLString: String? = nil,
        faviconURLString: String? = nil,
        linkURLString: String? = nil,
        sourceText: String? = nil,
        siteHost: String? = nil
    ) {
        self.name = name
        self.imageData = imageData
        self.faviconData = faviconData
        self.imageURLString = imageURLString
        self.faviconURLString = faviconURLString
        self.linkURLString = linkURLString
        self.sourceText = sourceText
        self.siteHost = siteHost
    }

    var uiImage: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }

    var faviconUIImage: UIImage? {
        guard let data = faviconData else { return nil }
        return UIImage(data: data)
    }

    var imageURL: URL? {
        guard let imageURLString else { return nil }
        return PersonEntity.normalizedWebURL(from: imageURLString)
    }

    var faviconURL: URL? {
        guard let faviconURLString else { return nil }
        return PersonEntity.normalizedWebURL(from: faviconURLString)
    }

    var linkURL: URL? {
        guard let linkURLString else { return nil }
        return PersonEntity.normalizedWebURL(from: linkURLString)
    }

    private static func normalizedWebURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        if let url = URL(string: trimmed),
           let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https" {
            return url
        }

        return URL(string: "https://\(trimmed)")
    }
}

@Model
class LocationResultEntity {
    var id: UUID
    var date: Date
    var customName: String?
    var locationText: String
    var userVoted: Bool
    @Attribute(.externalStorage) var mapSnapshotData: Data?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        customName: String? = nil,
        locationText: String,
        userVoted: Bool = false,
        mapSnapshotData: Data? = nil
    ) {
        self.id = id
        self.date = date
        self.customName = customName
        self.locationText = locationText
        self.userVoted = userVoted
        self.mapSnapshotData = mapSnapshotData
    }

    var uiImage: UIImage? {
        guard let data = mapSnapshotData else { return nil }
        return UIImage(data: data)
    }
}

@Model
class CheaterResultEntity {
    var id: UUID
    var date: Date
    var customName: String?
    var userVoted: Bool

    var riskScore: Int
    var yourInterest: Int
    var theirInterest: Int
    var messageCountYou: Int
    var messageCountThem: Int

    @Relationship(deleteRule: .cascade) var flags: [FlagEntity]

    
    @Attribute(.externalStorage) var queryImageData: Data?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        customName: String? = nil,
        userVoted: Bool = false,
        riskScore: Int,
        yourInterest: Int,
        theirInterest: Int,
        messageCountYou: Int,
        messageCountThem: Int,
        flags: [FlagEntity] = [],
        queryImageData: Data? = nil
    ) {
        self.id = id
        self.date = date
        self.customName = customName
        self.userVoted = userVoted
        self.riskScore = riskScore
        self.yourInterest = yourInterest
        self.theirInterest = theirInterest
        self.messageCountYou = messageCountYou
        self.messageCountThem = messageCountThem
        self.flags = flags
        self.queryImageData = queryImageData
    }

    var redFlags: [FlagEntity] {
        flags.filter { $0.isRed }
    }

    var greenFlags: [FlagEntity] {
        flags.filter { !$0.isRed }
    }

    var queryUIImage: UIImage? {
        guard let data = queryImageData else { return nil }
        return UIImage(data: data)
    }
}

@Model
class FlagEntity {
    var title: String
    var desc: String
    var isRed: Bool

    init(title: String, desc: String, isRed: Bool) {
        self.title = title
        self.desc = desc
        self.isRed = isRed
    }
}

@Model
class CachedImageEntity {
    @Attribute(.unique) var urlString: String
    @Attribute(.externalStorage) var imageData: Data?

    init(urlString: String, imageData: Data? = nil) {
        self.urlString = urlString
        self.imageData = imageData
    }
}
