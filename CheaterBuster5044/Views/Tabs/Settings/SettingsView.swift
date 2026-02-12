import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var mainVM: MainVM
    @Environment(\.openURL) var openURL
    
    @State private var isShareSheetShowing = false
    @State private var showPaywall = false
    @State private var showRateUs = false
    
    var body: some View {
        VStack(spacing: 8) {
            header
            main
        }
        .background(Color.Colors.primaryBG)
        
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        
        .fullScreenCover(isPresented: $showRateUs) {
            CustomRateUsView()
        }
        
        .sheet(isPresented: $isShareSheetShowing) {
            ShareSheet(activityItems: [LinksEnum.share.link])
                .presentationDetents([.medium, .large])
        }
    }
    
    var header: some View {
        Text("Settings")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(Color.Colors.black2)
            .padding(.top, 6)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var main: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                if !purchaseManager.isSubscribed {
                    subscribe
                }
                rateApp
                support
                appVersion
                privacy
                terms
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .padding(.bottom, tabBarHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
    
    var subscribe: some View {
        SettingsButton(icn: .Icns.crown, title: "Subscribe to Pro", onAction: {
            showPaywall = true
        })
    }
    
    var rateApp: some View {
        SettingsButton(icn: .Icns.rate, title: "Rate App", onAction: {
            showRateUs = true
        })
    }
    
    var support: some View {
        SettingsButton(icn: .Icns.support, title: "Support", onAction: {
            if let url = URL(string: LinksEnum.support.link) {
                openURL(url)
            }
        })
    }
    
    var appVersion: some View {
        SettingsButton(icn: .Icns.version, title: "App version", showChevron: false, onAction: { })
            .disabled(true)
            .overlay(alignment: .trailing) {
                Text(mainVM.appVersion)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.Colors.black)
                    .opacity(0.6)
                    .padding(.trailing, 24)
            }
    }
    
    var privacy: some View {
        SettingsButton(icn: .Icns.privacy, title: "Privacy policy", onAction: {
            if let url = URL(string: LinksEnum.privacy.link) {
                openURL(url)
            }
        })
    }
    
    var terms: some View {
        SettingsButton(icn: .Icns.terms, title: "Terms of Service", onAction: {
            if let url = URL(string: LinksEnum.terms.link) {
                openURL(url)
            }
        })
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(PurchaseManager.shared)
    .environmentObject(MainVM())
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
