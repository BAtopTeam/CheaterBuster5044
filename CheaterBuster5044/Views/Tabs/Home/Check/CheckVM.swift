import Foundation
import SwiftData
import SwiftUI
import UIKit

class CheckVM: ObservableObject {
    enum Step {
        case addPhoto
        case rotateCrop
        case analyze
        case result
    }
    
    @Published var step: Step = .addPhoto
    
    @Published var showPhotoSourcePick: Bool = false
    @Published var showCropSheet: Bool = false
    @Published var img: UIImage? = nil
    
    @Published var analyzeIndex: Int = 0
    @Published var locationResult: LocationResultEntity? = nil
    @Published var conversationResult: CheaterResultEntity? = nil
    @Published var personResult: PersonResultEntity? = nil
    @Published var errorMessage: String? = nil

    private var shouldFastForwardProgress: Bool = false
    private var shouldFinishProgress: Bool = false
    
    public func loadImage(_ img: UIImage) {
        self.img = img
        step = .rotateCrop
    }
    
    public func rotateLeft() {
        guard let img = img else { return }
        self.img = img.rotated(by: -90)
    }
    
    public func rotateRight() {
        guard let img = img else { return }
        self.img = img.rotated(by: 90)
    }
    
    public func startAnalyze(checkType: CheckType, modelContext: ModelContext?) {
        step = .analyze
        analyzeIndex = 0
        errorMessage = nil
        locationResult = nil
        conversationResult = nil
        personResult = nil
        shouldFastForwardProgress = false
        shouldFinishProgress = false

        Task {
            switch checkType {
                case .locationInsights:
                    await startLocationAnalyze(modelContext: modelContext)
                case .messageAnalysis:
                    await startConversationAnalyze(modelContext: modelContext)
                case .profileAuthent:
                    await startProfileAnalyze(modelContext: modelContext)
            }
        }
    }

    private func runMockAnalyze() async {
        await runAnalyzeProgress(steps: CheckType.profileAuthent.analyzeHints.count)
        await MainActor.run {
            step = .result
        }
    }
}

extension UIImage {
    func rotated(by degrees: CGFloat) -> UIImage? {
        let radians = degrees * .pi / 180
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        
        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        context.rotate(by: radians)
        draw(in: CGRect(origin: CGPoint(x: -size.width / 2, y: -size.height / 2), size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

private extension CheckVM {
    func startConversationAnalyze(modelContext: ModelContext?) async {
        guard let img else {
            await MainActor.run {
                errorMessage = "No image selected"
                step = .rotateCrop
            }
            return
        }

        let progressTask = Task {
            await runAnalyzeProgress(steps: CheckType.messageAnalysis.analyzeHints.count)
        }

        var resultEntity: CheaterResultEntity?
        var resultError: String?
        do {
            let appBundle = Bundle.main.bundleIdentifier ?? "com.kam.5044cheater"
            let response = try await APIManager.shared.analyzeConversation(image: img, appBundle: appBundle)

                if let result = response.result {
                let flags =
                result.red_flags.map { FlagEntity(title: "Red Flag", desc: $0, isRed: true) } +
                result.recommendations.map { FlagEntity(title: "Recommendation", desc: $0, isRed: false) }

                let queryThumbData = makeHistoryThumbData(from: img)

                let cheaterResult = CheaterResultEntity(
                    riskScore: result.risk_score,
                    yourInterest: 0,
                    theirInterest: 0,
                    messageCountYou: 0,
                    messageCountThem: 0,
                    flags: flags,
                    queryImageData: queryThumbData
                )
                if let modelContext {
                    modelContext.insert(cheaterResult)
                }
                if let data = queryThumbData, let thumb = UIImage(data: data) {
                    ImageCache.shared.saveEntityImage(thumb, forEntityType: .cheater, id: cheaterResult.id)
                }
                resultEntity = cheaterResult
            } else {
                resultError = "No result received from server"
            }
        } catch {
            resultError = error.localizedDescription
        }

        await MainActor.run {
            shouldFastForwardProgress = true
            shouldFinishProgress = true
        }
        _ = await progressTask.value
        await MainActor.run {
            conversationResult = resultEntity
            errorMessage = resultError
            step = .result
        }
    }

    func startProfileAnalyze(modelContext: ModelContext?) async {
        guard let img else {
            await MainActor.run {
                errorMessage = "No image selected"
                step = .rotateCrop
            }
            return
        }

        let progressTask = Task {
            await runAnalyzeProgress(steps: CheckType.profileAuthent.analyzeHints.count)
        }

        var resultEntity: PersonResultEntity?
        var resultError: String?

        do {
            let processedImage = try await APIManager.shared.removeBackground(image: img)
            let response = try await APIManager.shared.fetchCheaterBuster(image: processedImage)

            let statusMap = response.status ?? [:]
            let resultsMap = response.results ?? [:]
            let engineNames = Set(statusMap.keys).union(resultsMap.keys)

            if engineNames.isEmpty {
                resultError = "No results received from server"
            } else {
                var allMatches: [CheaterBusterVisualMatch] = []
                for engineName in engineNames.sorted() {
                    let matches = resultsMap[engineName]?.visual_matches ?? []
                    allMatches.append(contentsOf: matches)
                }
                let validMatches = await filterMatchesWithWorkingMainImage(allMatches, timeoutSeconds: 2.5)
                if validMatches.isEmpty {
                    resultError = "No results with working images"
                } else {
                    var people: [PersonEntity] = []
                    for match in validMatches {
                        let title = match.title?.trimmingCharacters(in: .whitespacesAndNewlines)
                        let safeTitle = title?.isEmpty == false ? title! : (match.source ?? "Result")
                        let normalizedLink = normalizedWebURLString(match.link)
                        let pageURL = normalizedLink.flatMap { URL(string: $0) }
                        let imageURL = match.thumbnail.flatMap { URL(string: $0) } ?? match.image.flatMap { URL(string: $0) }
                        let faviconURL = match.source_icon.flatMap { URL(string: $0) } ?? FaviconURLBuilder.faviconURL(for: pageURL, size: 64)

                        let person = PersonEntity(
                            name: safeTitle,
                            imageURLString: imageURL?.absoluteString,
                            faviconURLString: faviconURL?.absoluteString,
                            linkURLString: normalizedLink,
                            sourceText: match.source,
                            siteHost: pageURL?.host
                        )
                        people.append(person)
                    }

                    let queryThumbData = makeHistoryThumbData(from: img)
                    let personResult = PersonResultEntity(
                        foundPeople: people,
                        queryImageData: queryThumbData
                    )
                    if let modelContext {
                        modelContext.insert(personResult)
                    }
                    if let data = queryThumbData, let thumb = UIImage(data: data) {
                        ImageCache.shared.saveEntityImage(thumb, forEntityType: .person, id: personResult.id)
                    }
                    resultEntity = personResult
                }
            }
        } catch {
            resultError = error.localizedDescription
        }

        await MainActor.run {
            shouldFastForwardProgress = true
            shouldFinishProgress = true
        }
        _ = await progressTask.value
        await MainActor.run {
            personResult = resultEntity
            errorMessage = resultError
            step = .result
        }
    }

    func startLocationAnalyze(modelContext: ModelContext?) async {
        guard let img else {
            await MainActor.run {
                errorMessage = "No image selected"
                step = .rotateCrop
            }
            return
        }

        let progressTask = Task {
            await runAnalyzeProgress(steps: CheckType.locationInsights.analyzeHints.count)
        }

        var resultEntity: LocationResultEntity?
        var resultError: String?
        do {
            let appBundle = Bundle.main.bundleIdentifier ?? "com.kam.5044cheater"
            let response = try await APIManager.shared.searchLocation(image: img, appBundle: appBundle)

            if let locationText = response.result {
                let queryThumbData = makeHistoryThumbData(from: img)
                let locationResult = LocationResultEntity(
                    locationText: locationText,
                    mapSnapshotData: queryThumbData
                )
                if let modelContext {
                    modelContext.insert(locationResult)
                }
                if let data = queryThumbData, let thumb = UIImage(data: data) {
                    ImageCache.shared.saveEntityImage(thumb, forEntityType: .location, id: locationResult.id)
                }
                resultEntity = locationResult
            } else {
                resultError = "No location result received from server"
            }
        } catch {
            resultError = error.localizedDescription
        }

        await MainActor.run {
            shouldFastForwardProgress = true
            shouldFinishProgress = true
        }
        _ = await progressTask.value
        await MainActor.run {
            locationResult = resultEntity
            errorMessage = resultError
            step = .result
        }
    }

    func runAnalyzeProgress(steps: Int) async {
        let total = max(steps, 1)
        let lastStepIndex = max(total - 1, 0)
        for i in 0..<lastStepIndex {
            let fastForward = await MainActor.run { shouldFastForwardProgress }
            if fastForward {
                break
            }
            await MainActor.run {
                analyzeIndex = i
            }
            let delay: UInt64 = fastForward ? 200_000_000 : 1_500_000_000
            try? await Task.sleep(nanoseconds: delay)
        }
        await MainActor.run {
            analyzeIndex = lastStepIndex
        }

        while true {
            let shouldFinish = await MainActor.run { shouldFinishProgress }
            if shouldFinish {
                await MainActor.run {
                    analyzeIndex = total
                }
                return
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
    }

    func makeHistoryThumbData(from image: UIImage) -> Data? {
        let targetMaxSide: CGFloat = 240
        let resized = image.resizedKeepingAspect(maxSide: targetMaxSide)
        return resized.jpegData(compressionQuality: 0.85)
    }

    func filterMatchesWithWorkingMainImage(_ matches: [CheaterBusterVisualMatch], timeoutSeconds: Double) async -> [CheaterBusterVisualMatch] {
        guard matches.isEmpty == false else { return [] }
        let timeoutNanoseconds = UInt64(timeoutSeconds * 1_000_000_000)

        let results = await withTaskGroup(of: (CheaterBusterVisualMatch, Bool).self) { group in
            for match in matches {
                group.addTask {
                    let imageOK = await self.fetchMainImageWithinTimeout(for: match, timeoutNanoseconds: timeoutNanoseconds)
                    guard imageOK else { return (match, false) }
                    let linkOK = await self.fetchMainLinkWithinTimeout(for: match, timeoutNanoseconds: timeoutNanoseconds)
                    return (match, linkOK)
                }
            }
            var out: [(CheaterBusterVisualMatch, Bool)] = []
            for await pair in group {
                out.append(pair)
            }
            return out
        }
        return results.filter { $0.1 }.map { $0.0 }
    }

    private func mainImageURL(for match: CheaterBusterVisualMatch) -> URL? {
        let urlString = match.thumbnail ?? match.image
        return urlString.flatMap { URL(string: $0) }
    }

    private func fetchMainImageWithinTimeout(for match: CheaterBusterVisualMatch, timeoutNanoseconds: UInt64) async -> Bool {
        guard let url = mainImageURL(for: match) else { return false }
        if ImageCache.shared.image(forKey: url.absoluteString) != nil { return true }
        if await ImageStorageReader.shared.imageData(forKey: url.absoluteString) != nil { return true }

        return await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await self.fetchAndCacheImage(from: url, maxAttempts: 1)
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                return false
            }
            let first = await group.next() ?? false
            group.cancelAll()
            return first
        }
    }

    private func fetchMainLinkWithinTimeout(for match: CheaterBusterVisualMatch, timeoutNanoseconds: UInt64) async -> Bool {
        guard let url = normalizedWebURL(from: match.link) else { return false }

        return await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await self.isReachableMainLink(url)
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                return false
            }
            let first = await group.next() ?? false
            group.cancelAll()
            return first
        }
    }

    private func isReachableMainLink(_ url: URL) async -> Bool {
        var headRequest = URLRequest(url: url)
        headRequest.httpMethod = "HEAD"
        headRequest.timeoutInterval = 2.0
        headRequest.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (_, response) = try await URLSession.shared.data(for: headRequest)
            if let http = response as? HTTPURLResponse {
                if (200...399).contains(http.statusCode) {
                    return true
                }
                if http.statusCode != 405 {
                    return false
                }
            }
        } catch {
            // Continue with GET fallback for hosts that reject HEAD.
        }

        var getRequest = URLRequest(url: url)
        getRequest.httpMethod = "GET"
        getRequest.timeoutInterval = 2.0
        getRequest.cachePolicy = .reloadIgnoringLocalCacheData
        getRequest.setValue("bytes=0-0", forHTTPHeaderField: "Range")

        do {
            let (_, response) = try await URLSession.shared.data(for: getRequest)
            if let http = response as? HTTPURLResponse {
                return (200...399).contains(http.statusCode)
            }
            return true
        } catch {
            return false
        }
    }

    private func normalizedWebURLString(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        if let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" {
            return url.absoluteString
        }

        let withScheme = "https://\(trimmed)"
        guard let url = URL(string: withScheme) else { return nil }
        return url.absoluteString
    }

    private func normalizedWebURL(from raw: String?) -> URL? {
        normalizedWebURLString(raw).flatMap { URL(string: $0) }
    }

    func fetchAndCacheImage(from url: URL, maxAttempts: Int) async -> Bool {
        let cacheKey = url.absoluteString
        if ImageCache.shared.image(forKey: cacheKey) != nil {
            return true
        }

        if let data = await ImageStorageReader.shared.imageData(forKey: cacheKey),
           let image = await Task.detached(priority: .userInitiated) { UIImage(data: data) }.value {
            await MainActor.run {
                ImageCache.shared.save(image: image, forKey: cacheKey)
            }
            return true
        }

        let attempts = max(1, maxAttempts)
        for attempt in 1...attempts {
            if Task.isCancelled { return false }

            do {
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.timeoutInterval = 15
                request.cachePolicy = .returnCacheDataElseLoad

                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    continue
                }
                guard let image = await Task.detached(priority: .userInitiated) { UIImage(data: data) }.value else { continue }

                await MainActor.run {
                    ImageCache.shared.save(image: image, forKey: cacheKey)
                }
                await MainActor.run {
                    ImageStorageManager.shared.saveImage(data, forKey: cacheKey)
                }
                return true
            } catch {
                if let urlError = error as? URLError, urlError.code == .networkConnectionLost {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                }
            }

            if attempt < attempts {
                let backoff = UInt64(attempt) * 300_000_000
                try? await Task.sleep(nanoseconds: backoff)
            }
        }

        return false
    }

}
private extension UIImage {
    func resizedKeepingAspect(maxSide: CGFloat) -> UIImage {
        guard maxSide > 0 else { return self }

        let w = size.width
        let h = size.height
        guard w > 0, h > 0 else { return self }

        let scale = min(maxSide / max(w, h), 1.0)
        if scale >= 1.0 { return self }

        let newSize = CGSize(width: w * scale, height: h * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

