import SwiftData
import SwiftUI

private struct WebViewItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct ProfileResultView: View {
    var onTryAnotherPhoto: () -> Void
    var people: [PersonEntity]
    @Environment(\.modelContext) private var modelContext
    @State private var loadedImageCount: Int = 0
    @State private var webViewItem: WebViewItem? = nil

    init(onTryAnotherPhoto: @escaping () -> Void, people: [PersonEntity] = []) {
        self.onTryAnotherPhoto = onTryAnotherPhoto
        self.people = people
    }

    init(onTryAnotherPhoto: @escaping () -> Void, result: PersonResultEntity) {
        self.onTryAnotherPhoto = onTryAnotherPhoto
        self.people = result.foundPeople
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Similar profiles found: \(loadedImageCount)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.Colors.black.opacity(0.7))

                LazyVGrid(columns: Array(repeating: GridItem(spacing: 8), count: 2), alignment: .leading, spacing: 8) {
                    ForEach(people) { person in
                        profileCard(for: person)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            loadedImageCount = people.filter { $0.imageData != nil }.count
        }
        .overlay {
            if people.isEmpty {
                emptyPart
            }
        }
        .fullScreenCover(item: $webViewItem) { item in
            InAppWebView(url: item.url)
        }
    }

    var emptyPart: some View {
        VStack(spacing: 24) {
            Image(.Icns.similar)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)

            VStack(spacing: 12) {
                Text("No similar profiles found")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.Colors.black2)

                Text("We couldn’t find this photo used\non public dating profiles.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.Colors.black2)
            }
            .multilineTextAlignment(.center)

            PrimeButton(title: "Try another photo", action: onTryAnotherPhoto)
                .frame(width: 172)
        }
    }

    @ViewBuilder
    private func profileCard(for person: PersonEntity) -> some View {
        let card = ProfileCard(
            imageData: person.imageData,
            faviconData: person.faviconData,
            imageURL: person.imageURL,
            faviconURL: person.faviconURL,
            pageURL: person.linkURL,
            name: person.name,
            social: person.sourceText ?? person.siteHost,
            username: nil,
            person: person,
            modelContext: modelContext,
            onMainImageLoaded: {
                loadedImageCount = people.filter { $0.imageData != nil }.count
            }
        )

        if let url = person.linkURL {
            Button {
                webViewItem = WebViewItem(url: url)
            } label: {
                card
                    .contentShape(Rectangle())
            }
        } else {
            card
        }
    }
}

#Preview {
    let alice = PersonEntity(
        name: "Alice Smith",
        imageData: UIImage.rateUs.pngData(),
        imageURLString: "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
        faviconURLString: "https://www.google.com/s2/favicons?domain=instagram.com&sz=64",
        linkURLString: "https://www.instagram.com/",
        sourceText: "Instagram",
        siteHost: "instagram.com"
    )
    let bob = PersonEntity(
        name: "Bob Jones",
        imageData: UIImage.rateUs.pngData(),
        imageURLString: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
        faviconURLString: "https://www.google.com/s2/favicons?domain=tinder.com&sz=64",
        linkURLString: "https://www.tinder.com/",
        sourceText: "Tinder",
        siteHost: "tinder.com"
    )
    return ProfileResultView(onTryAnotherPhoto: { }, people: [alice, bob])
}
