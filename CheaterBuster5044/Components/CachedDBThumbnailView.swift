import SwiftUI
import UIKit

struct CachedDBThumbnailView: View {
    let entityType: HistoryDBEntityType
    let entityId: UUID
    let placeholder: UIImage

    @State private var uiImage: UIImage?
    @State private var loadTask: Task<Void, Never>?

    init(
        entityType: HistoryDBEntityType,
        entityId: UUID,
        placeholder: UIImage = .rateUs
    ) {
        self.entityType = entityType
        self.entityId = entityId
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let img = uiImage ?? ImageCache.shared.entityImage(forEntityType: entityType, id: entityId) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(uiImage: placeholder)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: uiImage != nil)
        .task(id: entityId) {
            await loadIfNeeded()
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }

    private func loadIfNeeded() async {
        if ImageCache.shared.entityImage(forEntityType: entityType, id: entityId) != nil {
            return
        }
        loadTask?.cancel()

        loadTask = Task {
            let data: Data? = switch entityType {
            case .person:
                await ImageStorageReader.shared.queryImageDataForPersonResult(id: entityId)
            case .cheater:
                await ImageStorageReader.shared.queryImageDataForCheaterResult(id: entityId)
            case .location:
                await ImageStorageReader.shared.queryImageDataForLocationResult(id: entityId)
            }

            if Task.isCancelled { return }
            guard let data else { return }

            let decoded = await Task.detached(priority: .userInitiated) {
                UIImage(data: data)
            }.value
            guard let decoded else { return }

            if Task.isCancelled { return }
            ImageCache.shared.saveEntityImage(decoded, forEntityType: entityType, id: entityId)
            await MainActor.run {
                uiImage = decoded
            }
        }
        await loadTask?.value
    }
}

#Preview("CachedDBThumbnailView") {
    CachedDBThumbnailView(
        entityType: .person,
        entityId: UUID(),
        placeholder: .rateUs
    )
    .frame(width: 64, height: 64)
    .background(Color(hex: "F0F5FA"))
}
