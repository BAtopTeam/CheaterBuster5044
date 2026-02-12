import SwiftUI

struct DoYouLikeResultSheet: View {
    @Environment(\.dismiss) var dismiss
    var onNo: () -> Void
    var onYes: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.Colors.black2.opacity(0.2))
                .frame(width: 24, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.bottom, 1)
            
            Text("Did you like the result?")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.Colors.black2)
            
            actions
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.Colors.white)
        .presentationDetents([.height(130)])
        .presentationCornerRadius(24)
        .presentationDragIndicator(.hidden)
    }
    
    var actions: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
                onNo()
            } label: {
                Text("No")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.Colors.black)
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(LinearGradient(colors: [
                                Color.Colors.accentTop,
                                Color.Colors.accentBottom,
                            ],
                                                 startPoint: .top,
                                                 endPoint: .bottom))
                            .opacity(0.07)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 18))
            }
            
            Button {
                dismiss()
                onYes()
            } label: {
                Text("Yes")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.Colors.white)
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(LinearGradient(colors: [
                                Color.Colors.accentTop,
                                Color.Colors.accentBottom,
                            ],
                                                 startPoint: .top,
                                                 endPoint: .bottom))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 18))
            }
        }
    }
}

#Preview {
    @Previewable @State var showSheet: Bool = false
    
    Button("Show Sheet") {
        showSheet.toggle()
    }
    .buttonStyle(.borderedProminent)
    .sheet(isPresented: $showSheet) {
        DoYouLikeResultSheet(onNo: { }, onYes: { })
    }
}
