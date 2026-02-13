import SwiftUI

struct CheckAlert: View {
    var checkType: CheckType
    var onCancel: () -> Void
    var onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(checkType.alertTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.Colors.black2)
                    
                    Text(checkType.alertText)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.Colors.black2)
                }
                
                Image(checkType.alertTextsCard)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .shadow(color: Color(hex: "111214").opacity(0.07), radius: 12, y: 5)
            }
            
            HStack(spacing: 8) {
                Button(action: onCancel, label: {
                    Image(.cancelButton)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .contentShape(Rectangle())
                })
                
                Button(action: onContinue, label: {
                    Image(.continueButton)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .contentShape(Rectangle())
                })
            }
        }
        .multilineTextAlignment(.center)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.Colors.primaryBG)
        )
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
        .background(Color(hex: "111214").opacity(0.7))
    }
}

#Preview {
    CheckAlert(checkType: .profileAuthent, onCancel: { }, onContinue: { })
}
