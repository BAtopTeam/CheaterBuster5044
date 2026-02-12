import ImageIO
import SwiftData
import SwiftUI

struct ProfileCard: View {
    var imageData: Data?
    var faviconData: Data?
    var imageURL: URL?
    var faviconURL: URL?
    var pageURL: URL?
    var name: String?
    var social: String?
    var username: String?
    var person: PersonEntity? = nil
    var modelContext: ModelContext? = nil
    var onMainImageLoaded: (() -> Void)? = nil

    @State private var image: UIImage? = nil
    @State private var favicon: UIImage? = nil

    var info: String {
        var showDot: Bool { social != nil && username != nil }
        if showDot {
            return "\(social ?? "") · \(username ?? "")"
        } else {
            return "\(social ?? "")\(username ?? "")"
        }
    }
    
    private var wCard: CGFloat { (UIScreen.main.bounds.width - 40) / 2 }
    private var faviconURLs: [URL] {
        let generated = FaviconURLBuilder.faviconURLs(for: pageURL, size: 64)
        if let faviconURL {
            return ([faviconURL] + generated).removingDuplicateURLs()
        }
        return generated
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            imgPart

            VStack(alignment: .leading, spacing: 4) {
                Text(name ?? "")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.Colors.black2)

                Text(info)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.Colors.black2)
            }
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .embedInLightGlass(radius: 24, showShadow: true)
        .task(id: imageData?.hashValue ?? 0) {
            await loadMainImageIfNeeded()
        }
        .task(id: faviconData?.hashValue ?? 0) {
            await loadFaviconIfNeeded()
        }
    }

    private func onMainImageLoadedFromRemote(_ uiImage: UIImage) {
        if let person, let modelContext {
            person.imageData = uiImage.jpegData(compressionQuality: 0.9) ?? uiImage.pngData()
            try? modelContext.save()
        }
        onMainImageLoaded?()
    }

    var imgPart: some View {
        Color(hex: "A8A7A7")
            .overlay {
                if let imageURL {
                    CachedRemoteImageView(
                        url: imageURL,
                        contentMode: .fill,
                        onImageLoaded: onMainImageLoadedFromRemote
                    ) {
                        fallbackMainImage
                    }
                    .clipped()
                    .allowsHitTesting(false)
                } else {
                    fallbackMainImage
                }
            }
            .overlay(alignment: .topLeading) {
                if let primaryURL = faviconURLs.first {
                    CachedRemoteImageView(
                        url: primaryURL,
                        fallbackURLs: Array(faviconURLs.dropFirst()),
                        maxAttemptsPerURL: 3,
                        contentMode: .fit
                    ) {
                        fallbackFavicon
                    }
                    .frame(width: 20, height: 20)
                    .padding(12)
                } else {
                    fallbackFavicon
                }
            }
            .frame(width: wCard, height: wCard)
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    @ViewBuilder
    private var fallbackMainImage: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var fallbackFavicon: some View {
        if let favicon {
            Image(uiImage: favicon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .padding(12)
        }
    }

    private func loadMainImageIfNeeded() async {
        guard imageURL == nil else { return }
        guard image == nil, let data = imageData else { return }
        image = await decodeThumbnail(from: data, maxPixel: Int(wCard * 2))
    }

    private func loadFaviconIfNeeded() async {
        guard faviconURL == nil else { return }
        guard favicon == nil, let data = faviconData else { return }
        favicon = await decodeThumbnail(from: data, maxPixel: 40)
    }

    private func decodeThumbnail(from data: Data, maxPixel: Int) async -> UIImage? {
        await Task.detached(priority: .utility) {
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixel,
                kCGImageSourceShouldCacheImmediately: true
            ]

            if let source = CGImageSourceCreateWithData(data as CFData, nil),
               let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                return UIImage(cgImage: cgImage)
            }
            return UIImage(data: data)
        }.value
    }
}

#Preview {
    ProfileCard(
        imageData: UIImage.rateUs.pngData(),
        faviconData: UIImage.Icns.add.pngData(),
        imageURL: URL(string: "https://images.unsplash.com/photo-1494790108377-be9c29b29330"),
        faviconURL: URL(string: "https://www.google.com/s2/favicons?domain=tinder.com&sz=64"),
        pageURL: URL(string: "https://tinder.com"),
        name: "alena",
        social: "Tinder",
        username: "@alenakoroleva"
    )
}

private extension Array where Element == URL {
    func removingDuplicateURLs() -> [URL] {
        var unique: [URL] = []
        var seen = Set<String>()
        for url in self {
            if seen.insert(url.absoluteString).inserted {
                unique.append(url)
            }
        }
        return unique
    }
}
