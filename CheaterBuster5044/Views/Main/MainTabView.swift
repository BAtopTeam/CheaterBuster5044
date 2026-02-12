import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject private var vm: MainVM

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                vm.tabPick.view
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                TabBar()
            }
            .animation(.interpolatingSpring(duration: 0.2), value: vm.tabPick)
        }
        .environmentObject(vm)
        .background(
            Color.Colors.primaryBG.ignoresSafeArea()
        )
        
        .fullScreenCover(isPresented: $purchaseManager.isShowedPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(MainVM())
        .environmentObject(PurchaseManager.shared)
}
