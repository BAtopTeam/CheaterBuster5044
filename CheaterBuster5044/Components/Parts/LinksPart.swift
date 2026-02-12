import SwiftUI

struct LinksPart: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.openURL) var openURL
    
    @Binding var isLoading: Bool
    var onRestored: () -> Void
    
    @State private var showAlert: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            link(title: "Terms of Use", onAction: {
                if let url = URL(string: LinksEnum.terms.link) {
                    openURL(url)
                }
            })
            
            Text("|")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.Colors.black.opacity(0.8))
            
            link(title: "Restore", onAction: {
                isLoading = true
                purchaseManager.restorePurchase { isSuccess in
                    if isSuccess { onRestored() }
                    isLoading = false
                }
            })
            
            Text("|")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.Colors.black.opacity(0.8))
            
            link(title: "Privacy Policy", onAction: {
                if let url = URL(string: LinksEnum.privacy.link) {
                    openURL(url)
                }
            })
        }
        .padding(.horizontal, 21)
        .alert("Error",
               isPresented: $showAlert,
               actions: {
            Button("Ok", role: .cancel) { }
        },
               message: {
            Text(purchaseManager.failRestoreText ?? "")
        })
        
        .onChange(of: purchaseManager.failRestoreText != nil) { _, newValue in
            if newValue { showAlert = true }
        }
        .onChange(of: showAlert == false) { _, newValue in
            if newValue { purchaseManager.failRestoreText = nil }
        }
    }
    
    func link(title: String, onAction: @escaping () -> Void) -> some View {
        Button(action: onAction, label: {
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.Colors.black.opacity(0.8))
                .padding(2)
                .contentShape(Rectangle())
        })
    }
}

#Preview {
    LinksPart(isLoading: .constant(false), onRestored: { })
        .environmentObject(PurchaseManager.shared)
        .padding()
}
