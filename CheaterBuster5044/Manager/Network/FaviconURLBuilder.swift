import Foundation

enum FaviconURLBuilder {

    static func faviconURLs(for pageURL: URL?, size: Int = 64) -> [URL] {
        guard let pageURL else { return [] }
        guard let host = pageURL.host?.trimmingCharacters(in: .whitespacesAndNewlines),
              host.isEmpty == false
        else { return [] }

        let safeSize = "\(max(16, min(size, 256)))"
        var urls: [URL] = []

        var googleDomain = URLComponents(string: "https://www.google.com/s2/favicons")
        googleDomain?.queryItems = [
            URLQueryItem(name: "domain", value: host),
            URLQueryItem(name: "sz", value: safeSize)
        ]
        if let url = googleDomain?.url {
            urls.append(url)
        }

        var googleDomainURL = URLComponents(string: "https://www.google.com/s2/favicons")
        googleDomainURL?.queryItems = [
            URLQueryItem(name: "domain_url", value: pageURL.absoluteString),
            URLQueryItem(name: "sz", value: safeSize)
        ]
        if let url = googleDomainURL?.url {
            urls.append(url)
        }

        if let ddg = URL(string: "https://icons.duckduckgo.com/ip3/\(host).ico") {
            urls.append(ddg)
        }

        var unique: [URL] = []
        var seen = Set<String>()
        for url in urls {
            if seen.insert(url.absoluteString).inserted {
                unique.append(url)
            }
        }
        return unique
    }

    static func faviconURL(for pageURL: URL?, size: Int = 64) -> URL? {
        faviconURLs(for: pageURL, size: size).first
    }

    static func faviconURLString(for pageURL: URL?, size: Int = 64) -> String? {
        faviconURL(for: pageURL, size: size)?.absoluteString
    }
}
