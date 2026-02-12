import Foundation
import SwiftData
import UIKit

actor ImageStorageReader {
    static let shared = ImageStorageReader()

    private var container: ModelContainer?
    private var backgroundContext: ModelContext?

    private func getContext() -> ModelContext? {
        if let ctx = backgroundContext { return ctx }
        guard let cont = container else { return nil }
        let ctx = ModelContext(cont)
        backgroundContext = ctx
        return ctx
    }

    func imageData(forKey key: String) async -> Data? {
        if container == nil {
            container = await MainActor.run { DBManager.shared.container }
        }
        guard let ctx = getContext() else { return nil }
        let key = key
        var descriptor = FetchDescriptor<CachedImageEntity>(
            predicate: #Predicate<CachedImageEntity> { $0.urlString == key }
        )
        descriptor.fetchLimit = 1
        guard let entity = try? ctx.fetch(descriptor).first else { return nil }
        return entity.imageData
    }

    func queryImageDataForPersonResult(id: UUID) async -> Data? {
        if container == nil {
            container = await MainActor.run { DBManager.shared.container }
        }
        guard let ctx = getContext() else { return nil }
        let predicateId = id
        var descriptor = FetchDescriptor<PersonResultEntity>(
            predicate: #Predicate<PersonResultEntity> { $0.id == predicateId }
        )
        descriptor.fetchLimit = 1
        guard let entity = try? ctx.fetch(descriptor).first else { return nil }
        return entity.queryImageData
    }

    func queryImageDataForCheaterResult(id: UUID) async -> Data? {
        if container == nil {
            container = await MainActor.run { DBManager.shared.container }
        }
        guard let ctx = getContext() else { return nil }
        let predicateId = id
        var descriptor = FetchDescriptor<CheaterResultEntity>(
            predicate: #Predicate<CheaterResultEntity> { $0.id == predicateId }
        )
        descriptor.fetchLimit = 1
        guard let entity = try? ctx.fetch(descriptor).first else { return nil }
        return entity.queryImageData
    }

    func queryImageDataForLocationResult(id: UUID) async -> Data? {
        if container == nil {
            container = await MainActor.run { DBManager.shared.container }
        }
        guard let ctx = getContext() else { return nil }
        let predicateId = id
        var descriptor = FetchDescriptor<LocationResultEntity>(
            predicate: #Predicate<LocationResultEntity> { $0.id == predicateId }
        )
        descriptor.fetchLimit = 1
        guard let entity = try? ctx.fetch(descriptor).first else { return nil }
        return entity.mapSnapshotData
    }
}

@MainActor
final class ImageStorageManager {
    static let shared = ImageStorageManager()

    private init() {}

    private var container: ModelContainer {
        DBManager.shared.container
    }

    func saveImage(_ data: Data, forKey key: String) {
        let ctx = container.mainContext
        let key = key
        var descriptor = FetchDescriptor<CachedImageEntity>(
            predicate: #Predicate<CachedImageEntity> { $0.urlString == key }
        )
        descriptor.fetchLimit = 1

        if let existing = try? ctx.fetch(descriptor).first {
            existing.imageData = data
        } else {
            let entity = CachedImageEntity(urlString: key, imageData: data)
            ctx.insert(entity)
        }
        try? ctx.save()
    }
}
