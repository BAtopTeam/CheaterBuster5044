import Foundation
import UIKit

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 100
    }
    
    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    
    func save(image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    func entityImage(forEntityType type: HistoryDBEntityType, id: UUID) -> UIImage? {
        image(forKey: entityCacheKey(type: type, id: id))
    }

    func saveEntityImage(_ image: UIImage, forEntityType type: HistoryDBEntityType, id: UUID) {
        save(image: image, forKey: entityCacheKey(type: type, id: id))
    }

    private func entityCacheKey(type: HistoryDBEntityType, id: UUID) -> String {
        "db:\(type.rawValue):\(id.uuidString)"
    }
}

enum HistoryDBEntityType: String {
    case person
    case cheater
    case location
}

