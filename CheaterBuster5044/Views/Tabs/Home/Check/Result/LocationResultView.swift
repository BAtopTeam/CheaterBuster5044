import SwiftUI

struct LocationResultView: View {
    var img: UIImage?
    var visualMatch: Int
    var title: String
    var onAnotherPhoto: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            imgPart
            visualMatchPart
            placePart
            action
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .background(Color.Colors.primaryBG)
    }
    
    var imgPart: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.Colors.primaryBG)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if let img {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: .infinity)
                }
            }
    }
    
    var visualMatchPart: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Visual match")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.Colors.black)
                
                Text("From visual details")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.Colors.black2.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("\(visualMatch)%")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.Colors.accentTop)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .overlay {
                    Capsule()
                        .stroke(Color.Colors.accentTop, lineWidth: 2)
                        .padding(1)
                }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .embedInLightGlass(radius: 24, showShadow: true)
    }
    
    var placePart: some View {
        HStack(spacing: 4) {
            Image(.Icns.location)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.Colors.black2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .multilineTextAlignment(.leading)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .embedInLightGlass(radius: 24, showShadow: true)
    }
    
    var action: some View {
        PrimeButton(title: "Analyze another photo", action: onAnotherPhoto)
            .padding(.top, 10)
            .padding(.bottom, 8)
    }
}

#Preview {
    LocationResultView(img: .rateUs,
                       visualMatch: 82,
                       title: "Place de Stanislas, Nancy, France",
                       onAnotherPhoto: { })
}
