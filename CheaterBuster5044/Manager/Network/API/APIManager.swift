import Foundation
import UIKit

final class APIManager: ObservableObject {
    static let shared = APIManager()

    let baseURL = "https://cheaterbuster.webberapp.shop"
    let rembgBaseURL = "https://rmbgr.webberapp.shop"

    private let keychainService = "com.kam.5044cheater"
    private let keychainAccount = "accessToken"
    private let keychainUserIDAccount = "userID"

    @Published var accessToken: String? {
        didSet {
            if let token = accessToken, let data = token.data(using: .utf8) {
                KeychainManager.shared.save(data, service: keychainService, account: keychainAccount)
            }
        }
    }

    @Published var userID: String? {
        didSet {
            if let id = userID, let data = id.data(using: .utf8) {
                KeychainManager.shared.save(data, service: keychainService, account: keychainUserIDAccount)
            }
        }
    }

    var useMockData: Bool

    private init() {
#if DEBUG
        useMockData = true
//        useMockData = false
#else
        useMockData = false
#endif
        loadCredentialsFromKeychain()
    }

    private func loadCredentialsFromKeychain() {
        if let data = KeychainManager.shared.read(service: keychainService, account: keychainAccount),
           let token = String(data: data, encoding: .utf8) {
            self.accessToken = token
            print("APIManager: Loaded Access Token from Keychain")
        }

        if let data = KeychainManager.shared.read(service: keychainService, account: keychainUserIDAccount),
           let id = String(data: data, encoding: .utf8) {
            self.userID = id
            print("APIManager: Loaded UserID from Keychain: \(id)")
        }
    }
}
