import SwiftUI
import AdServices
import ApphudSDK
import AppTrackingTransparency
import OSLog

@main
struct CheaterBuster5044App: App {
    @StateObject var purchaseManager = PurchaseManager.shared
    @StateObject var vm = MainVM()
    @AppStorage("OnBoardEnd") var onBoardEnd: Bool = false
    @StateObject var apiManager = APIManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if purchaseManager.paywall == nil {
                    LaunchView()
                } else if !onBoardEnd {
                    OnBoardView()
                        .environmentObject(purchaseManager)
                } else {
                    MainTabView()
                        .environmentObject(purchaseManager)
                        .environmentObject(vm)
                        .modelContainer(DBManager.shared.container)
                        .onAppear {
                            let userId = Apphud.userID()
                            Task {
                                await apiManager.authenticate(apphudID: userId)
                            }
                        }
                }
            }
            .task {
                await fetchAppStoreVersion()
            }
            
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    requestTrackingPermission()
                }
                trackAppleSearchAds()
            }
        }
    }
    
    func trackAppleSearchAds() {
        if #available(iOS 14.3, *) {
            Task {
                if let asaToken = try? AAAttribution.attributionToken() {
                    Apphud.setAttribution(data: nil, from: .appleAdsAttribution, identifer: asaToken, callback: nil)
                }
            }
        }
    }
    
    private func fetchAppStoreVersion() async {
        let appStoreId = "6759000863"
        
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(appStoreId)&country=us") else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(AppStoreLookupResponse.self, from: data)
            let version = response.results.first?.version
            await MainActor.run {
                vm.appStoreVersion = version
            }
        } catch {
        }
        
        struct AppStoreLookupResponse: Decodable {
            let results: [AppStoreLookupResult]
        }

        struct AppStoreLookupResult: Decodable {
            let version: String
        }
    }
}

func requestTrackingPermission() {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "5044", category: "Tracking")
    if #available(iOS 14, *) {
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
                case .authorized:
                    logger.info("User authorized tracking.")
                case .denied:
                    logger.info("User denied tracking permission.")
                case .restricted:
                    logger.info("Tracking is restricted.")
                case .notDetermined:
                    logger.info("Permission not requested.")
                @unknown default:
                    logger.info("Unknown status.")
            }
        }
    } else {
        logger.info("App Tracking Transparency is not available on this iOS version.")
    }
}
