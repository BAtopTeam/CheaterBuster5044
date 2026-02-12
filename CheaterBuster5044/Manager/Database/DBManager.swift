import SwiftData
import SwiftUI

@MainActor
class DBManager {
    static let shared = DBManager()

    let container: ModelContainer

    static let useMockData: Bool = false

    private init() {
        let schema = Schema([
            PersonResultEntity.self,
            PersonEntity.self,
            LocationResultEntity.self,
            CheaterResultEntity.self,
            FlagEntity.self,
            CachedImageEntity.self
        ])

        let modelConfiguration: ModelConfiguration

        if DBManager.useMockData {
            modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        } else {
            modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: false)
        }

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            if DBManager.useMockData {
                seedMockData()
            }
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    init(forPreview: Bool) {
        let schema = Schema([
            PersonResultEntity.self,
            PersonEntity.self,
            LocationResultEntity.self,
            CheaterResultEntity.self,
            FlagEntity.self,
            CachedImageEntity.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
            seedMockData()
        } catch {
            fatalError("Could not create Preview ModelContainer: \(error)")
        }
    }

    private func seedMockData() {
        let context = container.mainContext

        let descriptor = FetchDescriptor<PersonResultEntity>()
        let existing = try? context.fetch(descriptor)
        if let count = existing?.count, count > 0 {
            return
        }

        let person1 = PersonEntity(name: "Alice Smith", imageData: UIImage(named: "paywall")?.pngData())
        let person2 = PersonEntity(name: "Bob Jones", imageData: UIImage(named: "paywall")?.pngData())
        let personResult = PersonResultEntity(
            customName: "Search for Alice",
            foundPeople: [person1, person2]
        )
        context.insert(personResult)

        let locationResult = LocationResultEntity(
            customName: "Home Search",
            locationText: "123 Main St, New York, NY 10001",
            mapSnapshotData: UIImage(named: "paywall")?.pngData()
        )
        context.insert(locationResult)

        let flag1 = FlagEntity(title: "Suspicious Time", desc: "User active at 3 AM", isRed: true)
        let flag2 = FlagEntity(title: "Quick Replies", desc: "Responds instantly", isRed: false)

        let cheaterResult = CheaterResultEntity(
            customName: "Chat Analysis 1",
            riskScore: 85,
            yourInterest: 40,
            theirInterest: 90,
            messageCountYou: 120,
            messageCountThem: 300,
            flags: [flag1, flag2]
        )
        context.insert(cheaterResult)

        try? context.save()
        print("Mock data initialized")
    }

    
    
    func clearAllData(context: ModelContext? = nil) {
        let ctx = context ?? container.mainContext

        do {
            let personResults = try ctx.fetch(FetchDescriptor<PersonResultEntity>())
            personResults.forEach { ctx.delete($0) }

            let locationResults = try ctx.fetch(FetchDescriptor<LocationResultEntity>())
            locationResults.forEach { ctx.delete($0) }

            let cheaterResults = try ctx.fetch(FetchDescriptor<CheaterResultEntity>())
            cheaterResults.forEach { ctx.delete($0) }

            
            let persons = try ctx.fetch(FetchDescriptor<PersonEntity>())
            persons.forEach { ctx.delete($0) }

            let flags = try ctx.fetch(FetchDescriptor<FlagEntity>())
            flags.forEach { ctx.delete($0) }

            try ctx.save()
            print("✅ Database cleared successfully (roots + orphans)")
        } catch {
            print("🔴 Failed to clear database: \(error)")
        }
    }
}
