import SwiftUI
import StoreKit

struct CustomRateUsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Spacer()
            
            VStack(spacing: 9) {
                Image(.rateUs)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.width - 12)
                
                VStack(spacing: 8) {
                    Text("Do you like our app?")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Please rate our app so we can improve\nit for you and make it even cooler!")
                        .font(.system(size: 15, weight: .regular))
                }
                .foregroundStyle(Color.Colors.black)
                .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            actions
        }
        .background(Color.Colors.primaryBG
            .ignoresSafeArea())
        
        .toolbar(.hidden)
    }
    
    var header: some View {
        Button {
            dismiss()
        } label: {
            Image(.Icns.xmark)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
    
    var actions: some View {
        VStack(spacing: 12) {
            PrimeButton(title: "Rate us", action: {
                dismiss()
                DispatchQueue.main.async {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            })
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    CustomRateUsView()
}
