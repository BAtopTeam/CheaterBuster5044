import SwiftUI

struct LaunchView: View {
    var body: some View {
        ZStack {
            Image(.OnBoard.launch)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: UIScreen.main.bounds.height)
                .ignoresSafeArea()
                .frame(height: 100)
            
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.Colors.accentTop)
                .scaleEffect(1.5)
                .padding(.bottom, 100)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

#Preview {
    LaunchView()
}
