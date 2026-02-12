import SwiftUI
import UIKit

struct CachedRemoteImageView<Placeholder: View>: View {

    let url: URL?
    let fallbackURLs: [URL]
    let maxAttemptsPerURL: Int
    let contentMode: ContentMode
    var onImageLoaded: ((UIImage) -> Void)?
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var uiImage: UIImage? = nil
    @State private var task: Task<Void, Never>? = nil

    init(
        url: URL?,
        fallbackURLs: [URL] = [],
        maxAttemptsPerURL: Int = 3,
        contentMode: ContentMode = .fill,
        onImageLoaded: ((UIImage) -> Void)? = nil,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.fallbackURLs = fallbackURLs
        self.maxAttemptsPerURL = max(1, maxAttemptsPerURL)
        self.contentMode = contentMode
        self.onImageLoaded = onImageLoaded
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: uiImage != nil)
        .onAppear { startIfNeeded() }
        .onChange(of: requestKey) { _, _ in
            resetAndStart()
        }
        .onDisappear {
            task?.cancel()
            task = nil
        }
    }

    private func resetAndStart() {
        task?.cancel()
        task = nil
        uiImage = nil
        startIfNeeded()
    }

    private var allRequestURLs: [URL] {
        var all: [URL] = []
        if let url {
            all.append(url)
        }
        all.append(contentsOf: fallbackURLs)

        var unique: [URL] = []
        var seen = Set<String>()
        for item in all {
            let key = item.absoluteString
            if seen.insert(key).inserted {
                unique.append(item)
            }
        }
        return unique
    }

    private var requestKey: String {
        allRequestURLs.map(\.absoluteString).joined(separator: "|")
    }

    private func startIfNeeded() {
        guard uiImage == nil else { return }
        guard task == nil else { return }
        let urls = allRequestURLs
        guard urls.isEmpty == false else { return }

        if let cached = urls.compactMap({ ImageCache.shared.image(forKey: $0.absoluteString) }).first {
            uiImage = cached
            onImageLoaded?(cached)
            return
        }

        task = Task {
            let result = await loadImage(from: urls)
            if Task.isCancelled { return }
            guard let result else { return }

            await MainActor.run {
                ImageCache.shared.save(image: result.image, forKey: result.cacheKey)
                self.uiImage = result.image
                self.onImageLoaded?(result.image)
            }
            if let data = result.image.jpegData(compressionQuality: 0.9) ?? result.image.pngData() {
                await MainActor.run {
                    ImageStorageManager.shared.saveImage(data, forKey: result.cacheKey)
                }
            }
        }
    }

    private func loadImage(from urls: [URL]) async -> (image: UIImage, cacheKey: String)? {
        for url in urls {
            if Task.isCancelled { return nil }

            if let cached = ImageCache.shared.image(forKey: url.absoluteString) {
                return (cached, url.absoluteString)
            }

            if let data = await ImageStorageReader.shared.imageData(forKey: url.absoluteString),
               let image = await Task.detached(priority: .userInitiated) { UIImage(data: data) }.value {
                await MainActor.run {
                    ImageCache.shared.save(image: image, forKey: url.absoluteString)
                }
                return (image, url.absoluteString)
            }

            for attempt in 1...maxAttemptsPerURL {
                if Task.isCancelled { return nil }

                if let image = await fetchImage(from: url) {
                    return (image, url.absoluteString)
                }

                if attempt < maxAttemptsPerURL {
                    let delay = UInt64(attempt) * 300_000_000
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }
        return nil
    }

    private func fetchImage(from url: URL) async -> UIImage? {
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.timeoutInterval = 15
            req.cachePolicy = .returnCacheDataElseLoad

            let (data, response) = try await URLSession.shared.data(for: req)

            if Task.isCancelled { return nil }

            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                return nil
            }

            return await Task.detached(priority: .userInitiated) { UIImage(data: data) }.value
        } catch {
            do {
                if let urlError = error as? URLError, urlError.code == .networkConnectionLost {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }
            }
            return nil
        }
    }
}
