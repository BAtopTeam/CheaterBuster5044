import ApphudSDK
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    var onDismiss: (() -> Void)? = nil
    
    @State private var isLoading: Bool = false
    @State private var pickedProd: ApphudProduct?
    @State private var showCloseButton: Bool = false
    @State private var showPurchaseError: Bool = false
    @State private var purchaseErrorMessage: String = ""
    @AppStorage("OnBoardEnd") var onBoardEnd: Bool = false
    
    var body: some View {
        VStack(spacing: 10) {
            Image(.paywallImg)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: .infinity)
            
            VStack(spacing: 24) {
                featurePart
                footerBlock
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .overlay(alignment: .topLeading, content: {
            closeButton
                .opacity(showCloseButton ? 1 : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        })
        .overlay(content: {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.white)
                        .scaleEffect(2)
                }
            }
        })
        .background(Color.Colors.primaryBG)
        
        .animation(.snappy, value: isLoading)
        .animation(.easeInOut(duration: 0.2), value: purchaseManager.products)
        .alert("Purchase Error", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) {
                purchaseErrorMessage = ""
            }
        } message: {
            Text(purchaseErrorMessage)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showCloseButton = true
                }
            }
        }
    }
    
    var closeButton: some View {
        Button {
            if let onDismiss = onDismiss {
                onDismiss()
            } else {
                dismiss()
            }
        } label: {
            Image(.Icns.xmark)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Color.Colors.black2)
                .opacity(0.4)
                .frame(width: 32, height: 32)
                .padding(6)
                .contentShape(Rectangle())
        }
        .padding(16)
    }
    
    var footerBlock: some View {
        VStack(spacing: 24) {
            productsPart
            
            VStack(spacing: 16) {
                Text("Cancel anytime")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.Colors.black2.opacity(0.8))
                
                PrimeButton(title: "Continue", action: {
                    guard let pickedProd = pickedProd else {
                        purchaseErrorMessage = "Please select a subscription plan"
                        showPurchaseError = true
                        return
                    }
                    
                    guard purchaseManager.isReady else {
                        purchaseErrorMessage = purchaseManager.purchaseError ?? "Subscription options are not ready. Please try again."
                        showPurchaseError = true
                        return
                    }
                    
                    isLoading = true
                    purchaseManager.makePurchase(product: pickedProd, completion: { success, errorMessage in
                        isLoading = false
                        
                        if success {
                            if let onDismiss = onDismiss {
                                onDismiss()
                            } else {
                                dismiss()
                            }
                        } else {
                            purchaseErrorMessage = errorMessage ?? "Purchase failed. Please try again."
                            showPurchaseError = true
                        }
                    })
                }, isActive: pickedProd != nil)
                
                links
            }
        }
    }
    
    var featurePart: some View {
        VStack(spacing: 16) {
            Text("Unlock PRO Access")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.Colors.black2)
            
            let features: [String] = [
                "Unlimited photo checks",
                "Full conversation analysis",
                "Advanced location insights",
                "Priority processing"
            ]
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(.Icns.check)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                        
                        Text(feature)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.Colors.black2)
                    }
                }
            }
        }
        .padding(.horizontal, 33.5)
    }
    
    var productsPart: some View {
        VStack(spacing: 8) {
            if purchaseManager.purchaseState == .loading || purchaseManager.products.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.white)
                        .scaleEffect(1.5)
                    
                    if let error = purchaseManager.purchaseError {
                        Text(error)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.Colors.accentTop)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 32)
            } else {
                ForEach(purchaseManager.products, id: \.productId) { product in
                    Button {
                        pickedProd = product
                    } label: {
                        productCard(prod: product, isPicked: pickedProd == product)
                    }
                    .onAppear {
                        if pickedProd == nil || (pickedProd?.price ?? 0) > product.price {
                            pickedProd = product
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func productCard(prod: ApphudProduct, isPicked: Bool) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Image(isPicked ? .Icns.circlePicked : .Icns.circle)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(prod.timeString.capitalizingFirstLetter() + "ly")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.Colors.black2)
                    
                    if prod.timeString.lowercased() != "week" {
                        Text(prod.localizedPriceWeek + " / week")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.Colors.black2.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(prod.localizedPrice + " / \(prod.timeString.lowercased())")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.Colors.black2)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 73)
        .embedInLightGlass(radius: 24, showShadow: true)
        .overlay(content: {
            if isPicked {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.Colors.accentTop, lineWidth: 2)
                    .padding(1)
            }
        })
        .animation(.snappy(duration: 0.2), value: isPicked)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .topTrailing) {
            if prod.timeString.lowercased() != "week" {
                Text("Popular")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.Colors.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.Colors.accentTop)
                    )
                    .offset(x: -16, y: -11)
            }
        }
    }
    
    var links: some View {
        LinksPart(isLoading: $isLoading, onRestored: {
            dismiss()
        })
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager.shared)
}

