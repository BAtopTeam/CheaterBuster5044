import SwiftUI

struct HistoryCard<ImageContent: View>: View {
    @ViewBuilder var imageContent: () -> ImageContent
    var title: String
    var text: String

    init(
        @ViewBuilder imageContent: @escaping () -> ImageContent,
        title: String,
        text: String
    ) {
        self.imageContent = imageContent
        self.title = title
        self.text = text
    }


    var body: some View {
        HStack(spacing: 8) {
            imageContent()
                .frame(width: 64, height: 64)
                .background(Color(hex: "F0F5FA"))
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.Colors.black2)
                
                Text(text)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.Colors.black2.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(.Icns.chevronRight)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
        }
        .lineLimit(1)
        .padding(8)
        .padding(.trailing, 8)
        .embedInLightGlass(radius: 24, showShadow: true)
    }
}

#Preview {
    HistoryCard(
        imageContent: {
            Image(uiImage: .rateUs)
                .resizable()
                .aspectRatio(contentMode: .fit)
        },
        title: "Example",
        text: "82%"
    )
}
