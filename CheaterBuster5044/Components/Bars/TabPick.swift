import SwiftUI

enum TabPick: Identifiable, CaseIterable {
    case home
    case history
    case settings
    
    var id: Self { self }
    
    var title: String {
        switch self {
            case .home:     "Home"
            case .history:  "History"
            case .settings: "Settings"
        }
    }
    
    var icnPick: ImageResource {
        switch self {
            case .home:     .Tab.tabHomePick
            case .history:  .Tab.tabHistoryPick
            case .settings: .Tab.tabSettingsPick
        }
    }
    
    var icnBase: ImageResource {
        switch self {
            case .home:     .Tab.tabHomeBase
            case .history:  .Tab.tabHistoryBase
            case .settings: .Tab.tabSettingsBase
        }
    }
    
    
    @ViewBuilder
    var view: some View {
        switch self {
            case .home:     HomeView()
            case .history:  HistoryView()
            case .settings: SettingsView()
        }
    }
}

let tabBarHeight: CGFloat = 54
struct TabBar: View {
    @EnvironmentObject var vm: MainVM
    
    @State private var tabBarWidth: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(TabPick.allCases) { tab in
                tabPick(tab)
                    .onTapGesture {
                        vm.tabPick = tab
                    }
            }
        }
        .padding(2)
        .background(
            Image(.Tab.tabBarBG)
                .resizable()
                .aspectRatio(contentMode: .fit)
        )
        .background(
            GeometryReader { geo in
                Color.white.opacity(0.01)
                    .onAppear { tabBarWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in tabBarWidth = w }
            }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    DispatchQueue.global(qos: .userInteractive).async {
                        updateTabSelection(at: value.location.x, in: tabBarWidth)
                    }
                }
        )
        .animation(.interpolatingSpring(duration: 0.15), value: vm.tabPick)
    }
    
    private func tabPick(_ tab: TabPick) -> some View {
        Group {
            var isPicked: Bool { vm.tabPick == tab }
            
            Image(isPicked ? tab.icnPick : tab.icnBase)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
            .contentShape(Rectangle())
        }
    }
}

extension TabBar {
    private func updateTabSelection(at x: CGFloat, in width: CGFloat) {
        guard width > 0 else { return }
        let tabs = Array(TabPick.allCases)
        let count = tabs.count
        let segment = width / CGFloat(count)
        let rawIndex = Int((x / segment).rounded(.down))
        let clampedIndex = max(0, min(count - 1, rawIndex))
        let newTab = tabs[clampedIndex]
        DispatchQueue.main.async {
            if vm.tabPick != newTab {
                vm.tabPick = newTab
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
}


#Preview {
    ZStack {
        Color.green.ignoresSafeArea()
        TabBar()
            .environmentObject(MainVM())
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

