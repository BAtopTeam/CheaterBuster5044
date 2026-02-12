import SwiftUI
import Combine
import ApphudSDK
import AdServices
import OSLog

@MainActor
final class PurchaseManager: ObservableObject {
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CatFishFinder5044", category: "PurchaseManager")
    
    enum PurchaseState: Equatable {
        case idle
        case loading
        case ready
        case purchasing
        case error(String)
        
        static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.ready, .ready), (.purchasing, .purchasing):
                return true
            case (.error(let lhsMsg), .error(let rhsMsg)):
                return lhsMsg == rhsMsg
            default:
                return false
            }
        }
    }
    
    @Published private(set) var paywall: ApphudPaywall?
    @Published private(set) var products: [ApphudProduct] = []
    @Published private(set) var isSubscribed: Bool = false
    @Published private(set) var purchaseState: PurchaseState = .idle
    @Published var purchaseError: String? = nil
    @Published var isLoad: Bool = false
    @Published var failRestoreText: String? = nil
    
    @AppStorage("OnBoardEnd") var isOnboardingFinished: Bool = false
    @Published var isShowedPaywall: Bool = false
    
    public var userId: String {
#if DEBUG
        Apphud.userID()
#else
        Apphud.userID()
#endif
    }
    
    var isReady: Bool {
        purchaseState == .ready && !products.isEmpty && paywall != nil
    }
    
    var isLoading: Bool {
        purchaseState == .loading || purchaseState == .purchasing
    }

    static let shared = PurchaseManager()
    
    private init() {
        logger.info("PurchaseManager: Initializing Apphud SDK")
        Apphud.setPaywallsCacheTimeout(3600)
        Apphud.start(apiKey: "app_TZDsHNqKL7UkoaScjN6oyShxkzRX97")
        logger.info("PurchaseManager: Apphud.start() called")
        
        purchaseState = .loading
        
        Task {
            await loadPaywalls()
        }
        
#if DEBUG
        self.isSubscribed = Apphud.hasPremiumAccess()
#else
        self.isSubscribed = Apphud.hasPremiumAccess()
#endif
        isShowedPaywall = !isSubscribed && isOnboardingFinished
    }
    
    private func loadPaywalls() async {
        logger.info("PurchaseManager: Starting paywall fetch")
        let paywalls = await Apphud.fetchPaywallsWithFallback()
        logger.info("PurchaseManager: Fetched \(paywalls.count) paywalls")
        self.configure(with: paywalls)
    }

    private func configure(with paywalls: [ApphudPaywall]) {
        logger.info("PurchaseManager: Configuring paywalls, looking for 'main' identifier")
        guard let paywall = paywalls.first(where: { $0.identifier == "main" }) else {
            logger.error("PurchaseManager: Paywall with identifier 'main' not found. Available: \(paywalls.map { $0.identifier }.joined(separator: ", "))")
            purchaseState = .error("Subscription options not available. Please check your connection and try again.")
            purchaseError = "Subscription options not available. Please check your connection and try again."
            return
        }
        
        self.paywall = paywall
        self.products = paywall.products
        logger.info("PurchaseManager: Configured paywall 'main' with \(self.products.count) products")
        
        if self.products.isEmpty {
            logger.warning("PurchaseManager: Paywall 'main' has no products!")
            purchaseState = .error("No subscription products available. Please try again later.")
            purchaseError = "No subscription products available. Please try again later."
        } else {
            purchaseState = .ready
            purchaseError = nil
            logger.info("PurchaseManager: Products ready: \(self.products.map { $0.productId }.joined(separator: ", "))")
        }
    }

    func makePurchase(product: ApphudProduct, completion: @escaping(Bool, String?) -> Void) {
        guard purchaseState != .purchasing else {
            logger.warning("PurchaseManager: Purchase already in progress, ignoring duplicate request")
            completion(false, "Purchase already in progress")
            return
        }
        
        guard let _ = paywall, !products.isEmpty else {
            logger.error("PurchaseManager: Cannot purchase - paywall or products not loaded")
            let errorMsg = "Subscription options not loaded. Please try again."
            purchaseError = errorMsg
            completion(false, errorMsg)
            return
        }
        
        guard products.contains(where: { $0.productId == product.productId }) else {
            logger.error("PurchaseManager: Product \(product.productId) not found in available products")
            let errorMsg = "Selected product is not available"
            purchaseError = errorMsg
            completion(false, errorMsg)
            return
        }
        
        logger.info("PurchaseManager: Starting purchase for product \(product.productId)")
        purchaseState = .purchasing
        purchaseError = nil
        
        Task { @MainActor in
            let result = await Apphud.fallbackPurchase(product: product)
            
            if result {
                logger.info("PurchaseManager: Purchase successful for product \(product.productId)")
                self.isSubscribed = Apphud.hasPremiumAccess()
                self.purchaseState = .ready
                self.purchaseError = nil
                completion(true, nil)
            } else {
                logger.error("PurchaseManager: Purchase failed for product \(product.productId)")
                let errorMsg = "Purchase was not completed. Please try again."
                self.purchaseState = .ready
                self.purchaseError = errorMsg
                completion(false, errorMsg)
            }
        }
    }

    func restorePurchase(completion: @escaping(Bool) -> Void) {
        logger.info("PurchaseManager: Starting restore purchases")
        Apphud.restorePurchases { [weak self] subscriptions, purchases, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.logger.error("PurchaseManager: Restore failed - \(error.localizedDescription)")
                    self.failRestoreText = "Restore purchases failed: \(error.localizedDescription)"
                    completion(false)
                    return
                }

                if let subscriptions = subscriptions, subscriptions.contains(where: { $0.isActive() }) {
                    self.logger.info("PurchaseManager: Restore successful - active subscription found")
                    self.isSubscribed = Apphud.hasPremiumAccess()
                    self.failRestoreText = nil
                    completion(true)
                    return
                }

                if let purchases = purchases, purchases.contains(where: { $0.isActive() }) {
                    self.logger.info("PurchaseManager: Restore successful - active purchase found")
                    self.isSubscribed = Apphud.hasPremiumAccess()
                    self.failRestoreText = nil
                    completion(true)
                    return
                }

                self.logger.warning("PurchaseManager: Nothing to restore")
                self.failRestoreText = "Nothing to restore"
                completion(false)
            }
        }
    }
}

