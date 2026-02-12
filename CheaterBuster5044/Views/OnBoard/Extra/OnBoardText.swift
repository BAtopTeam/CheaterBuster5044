import SwiftUI

struct OnBoardText: View {
    var currentPage: Int
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if currentPage == 0 {
                textPage(title: "Check profile authenticity",
                         text: "Find where photos appear across dating\nplatforms")
            } else if currentPage == 1 {
                textPage(title: "Analyze conversations",
                         text: "Spot red flags, pressure, and unusual\nbehavior patterns")
            } else if currentPage == 2 {
                textPage(title: "Reveal photo locations",
                         text: "Estimate where a photo was taken using\nvisual clues")
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }
    
    @ViewBuilder
    private func textPage(title: String,
                          text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.Colors.black2)
                .lineLimit(1)
                .font(.system(size: 28, weight: .black))
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.Colors.black2.opacity(0.8))
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(2)
        .minimumScaleFactor(0.6)
    }
}
