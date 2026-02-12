import SwiftData
import SwiftUI
import UIKit

struct HistoryView: View {
    @Query private var personResults: [PersonResultEntity]
    @Query private var locationResults: [LocationResultEntity]
    @Query private var cheaterResults: [CheaterResultEntity]
    @State private var selectedDestination: HistoryDestination?
    
    var body: some View {
        VStack(spacing: 8) {
            header
            main
        }
        .background(Color.Colors.primaryBG)
        
        .fullScreenCover(item: $selectedDestination, content: { destination in
            switch destination {
                case .profile(let result):
                    CheckView(checkType: .profileAuthent, personResult: result)
                case .location(let result):
                    CheckView(checkType: .locationInsights, locationResult: result)
                case .conversation(let result):
                    CheckView(checkType: .messageAnalysis, conversationResult: result)
            }
        })
    }
    
    var header: some View {
        Text("History")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(Color.Colors.black2)
            .padding(.top, 6)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var main: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ForEach(historyItems) { item in
                    Button {
                        selectedDestination = item.destination
                    } label: {
                        HistoryCard(
                            imageContent: {
                                CachedDBThumbnailView(
                                    entityType: item.entityType,
                                    entityId: item.id,
                                    placeholder: .rateUs
                                )
                            },
                            title: item.title,
                            text: item.subtitle
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .padding(.bottom, tabBarHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        
        .overlay {
            if historyItems.isEmpty {
                emptyPart
                    .padding(.bottom, tabBarHeight)
            }
        }
    }
    
    var emptyPart: some View {
        VStack(spacing: 24) {
            Image(.Icns.emptyHistory)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
            
            VStack(spacing: 12) {
                Text("No History Yet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.Colors.black2)
                
                Text("Your recent searches will appear\nhere for quick access")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.Colors.black2)
                    .opacity(0.7)
            }
        }
        .multilineTextAlignment(.center)
    }
}

private extension HistoryView {
    enum HistoryDestination: Identifiable, Hashable {
        case profile(PersonResultEntity)
        case location(LocationResultEntity)
        case conversation(CheaterResultEntity)

        var id: UUID {
            switch self {
                case .profile(let item):
                    return item.id
                case .location(let item):
                    return item.id
                case .conversation(let item):
                    return item.id
            }
        }
    }

    struct HistoryItem: Identifiable {
        let id: UUID
        let date: Date
        let title: String
        let subtitle: String
        let entityType: HistoryDBEntityType
        let destination: HistoryDestination
    }

    var historyItems: [HistoryItem] {
        let people = personResults.map { item in
            HistoryItem(
                id: item.id,
                date: item.date,
                title: item.customName ?? "Profile authenticity",
                subtitle: "Found: \(item.foundPeople.count)",
                entityType: .person,
                destination: .profile(item)
            )
        }

        let locations = locationResults.map { item in
            HistoryItem(
                id: item.id,
                date: item.date,
                title: item.customName ?? "Location insights",
                subtitle: item.locationText,
                entityType: .location,
                destination: .location(item)
            )
        }

        let cheaters = cheaterResults.map { item in
            HistoryItem(
                id: item.id,
                date: item.date,
                title: item.customName ?? "Message analysis",
                subtitle: "Risk: \(item.riskScore)%",
                entityType: .cheater,
                destination: .conversation(item)
            )
        }

        return (people + locations + cheaters).sorted { $0.date > $1.date }
    }
}

#Preview("HistoryView - empty") {
    let schema = Schema([
        PersonResultEntity.self,
        PersonEntity.self,
        LocationResultEntity.self,
        CheaterResultEntity.self,
        FlagEntity.self
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return HistoryView()
        .modelContainer(container)
}

#Preview("HistoryView - with mock data") {
    NavigationStack {
        HistoryView()
    }
        .modelContainer(DBManager(forPreview: true).container)
}
