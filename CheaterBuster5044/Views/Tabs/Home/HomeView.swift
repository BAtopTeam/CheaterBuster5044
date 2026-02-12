import SwiftUI

struct HomeView: View {
    @State private var checkType: CheckType? = nil
    
    var body: some View {
        VStack(spacing: 8) {
            header
            main
        }
        .background(alignment: .top) {
            Image(.homeBG)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        }
        .background(Color.Colors.primaryBG)
        
        .navigationDestination(item: $checkType) { checkType in
            CheckView(checkType: checkType)
        }
    }
    
    var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hi there!")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.Colors.black2)
            
            Text("Let’s get some clarity")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.Colors.black2.opacity(0.8))
        }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var main: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                ForEach(CheckType.allCases) { check in
                    Button {
                        checkType = check
                    } label: {
                        CheckCard(check: check)
                            .contentShape(RoundedRectangle(cornerRadius: 24))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .padding(.bottom, tabBarHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

#Preview {
    HomeView()
}
