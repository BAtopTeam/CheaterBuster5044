import SwiftUI

struct SettingsButton: View {
    var icn:    ImageResource
    var title:  String
    var showChevron: Bool = true
    var onAction: () -> Void
    
    var body: some View {
        Button {
            onAction()
        } label: {
            HStack(spacing: 8) {
                Image(icn)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .padding(9)
                    .embedInLightGlass(radius: 16)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.Colors.black2)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
                
                if showChevron {
                    Image(.Icns.chevronRight)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(Color.Colors.black2)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(8)
            .padding(.trailing, 8)
            .embedInLightGlass(radius: 24, showShadow: true)
        }
    }
}
