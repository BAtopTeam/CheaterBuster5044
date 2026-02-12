import SwiftUI

struct OnBoardCards: View {
    var currentPage: Int
    
    var body: some View {
        ZStack {
            if currentPage == 0 {
                card(img: .OnBoard.onBoard1)
            } else if currentPage == 1 {
                card(img: .OnBoard.onBoard2)
            } else if currentPage == 2 {
                card(img: .OnBoard.onBoard3)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }
    
    @ViewBuilder
    private func card(img: ImageResource) -> some View {
        Image(img)
            .resizable()
            .ignoresSafeArea()
            .aspectRatio(contentMode: .fill)
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 230, alignment: .top)
            .frame(maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
    }
}
