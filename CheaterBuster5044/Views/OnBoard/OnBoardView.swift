import SwiftUI
import StoreKit

struct OnBoardView: View {
    @AppStorage("OnBoardEnd") var onBoardEnd: Bool = false
    @AppStorage("nativeReviewShown") private var nativeReviewShown: Bool = false
    @State private var currentPage: Int = 0
    
    @State private var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            if currentPage > 2 {
                PaywallView(onDismiss: {
                    onBoardEnd = true
                })
            } else {
                main
            }
            
            if isLoading {
                ProgressView()
                    .tint(Color.Colors.white)
                    .scaleEffect(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.Colors.black.opacity(0.3))
            }
        }
        .animation(.interpolatingSpring(duration: 0.2), value: currentPage)
        .animation(.interpolatingSpring(duration: 0.2), value: isLoading)
        .disabled(isLoading)
    }
    
    var main: some View {
        ZStack {
            Color.Colors.primaryBG.ignoresSafeArea()
            
            OnBoardCards(currentPage: currentPage)
            
            footer
        }
    }
    
    var footer: some View {
        VStack(spacing: 24) {
            pageIndicator
            OnBoardText(currentPage: currentPage)
            VStack(spacing: 16) {
                btnPart
                LinksPart(isLoading: $isLoading, onRestored: {
                    isLoading = false
                })
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 70)
        .padding(.bottom, 8)
        .background(
            LinearGradient(stops: [
                .init(color: Color.Colors.primaryBG.opacity(0), location: 0),
                .init(color: Color.Colors.primaryBG.opacity(1), location: 0.2),
            ], startPoint: .top, endPoint: .bottom)
        )
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
    
    var pageIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { ind in
                var isWas: Bool { currentPage >= ind }
                
                Capsule()
                    .fill(LinearGradient(colors: isWas ? [Color.Colors.accentTop, Color.Colors.accentBottom] : [Color.Colors.white], startPoint: .top, endPoint: .bottom))
                    .frame(width: currentPage == ind ? 24 : 8, height: 8)
            }
        }
        .animation(.interpolatingSpring(duration: 0.2), value: currentPage)
    }
    
    var btnPart: some View {
        PrimeButton(title: "Continue", action: {
            currentPage += 1
        })
    }
    
    func requestRateReview() {
        if !nativeReviewShown {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                    nativeReviewShown = true
                }
            }
        }
    }
}

#Preview {
    OnBoardView()
        .environmentObject(PurchaseManager.shared)
}
