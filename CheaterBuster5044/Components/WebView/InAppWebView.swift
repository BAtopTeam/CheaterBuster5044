import SwiftUI

struct InAppWebView: View {
    let url: URL
    var onDismiss: (() -> Void)? = nil
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.Colors.primaryBG
                .ignoresSafeArea()
            
            WebView(url: url)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .bottom)
            
            closeButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var closeButton: some View {
        Button {
            if let onDismiss {
                onDismiss()
            } else {
                dismiss()
            }
        } label: {
            Image(.Icns.xmark)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Color.Colors.black2)
                .frame(width: 16, height: 16)
                .padding(12)
                .background {
                    Circle()
                        .fill(Color.Colors.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
                }
                .contentShape(Rectangle())
        }
        .padding(16)
    }
}

#Preview {
    InAppWebView(url: URL(string: "https://www.apple.com")!)
}
