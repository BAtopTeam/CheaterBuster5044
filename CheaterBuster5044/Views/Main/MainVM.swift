import Foundation

class MainVM: ObservableObject {
    @Published var tabPick: TabPick = .home
    
    private let appStoreId = "6756786942"
    @Published var appStoreVersion: String? = nil
    var appVersion: String {
        if let storeVersion = appStoreVersion, !storeVersion.isEmpty {
            return storeVersion
        }
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0"
    }
}
