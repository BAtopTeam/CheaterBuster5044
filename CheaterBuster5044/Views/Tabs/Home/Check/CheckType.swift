import Foundation
import SwiftUI

enum CheckType: String, Identifiable, CaseIterable {
    case profileAuthent     = "Check Photo"
    case messageAnalysis    = "Message analysis"
    case locationInsights   = "Location insights"
    
    var id: String { rawValue }
    
    var card: ImageResource {
        switch self {
            case .profileAuthent:   .Cards.cardProfileAuth
            case .messageAnalysis:  .Cards.cardMessageAnalysis
            case .locationInsights: .Cards.cardLocationInsights
        }
    }
    
    var text: String {
        switch self {
            case .profileAuthent:   "Check where a photo\nappears in dating profiles."
            case .messageAnalysis:  "Understand potential red\nflags in conversations."
            case .locationInsights: "Get clues about where a\nphoto was taken."
        }
    }

    var rotateCropTitle: String {
        switch self {
            case .profileAuthent:   "Image analysis"
            case .messageAnalysis:  "Conversation analysis"
            case .locationInsights: "Location insights"
        }
    }
    
    var analyzeButtonTitle: String {
        switch self {
            case .profileAuthent:   "Analyze image"
            case .messageAnalysis:  "Analyze conversation"
            case .locationInsights: "Analyze location"
        }
    }
    
    var analyzeTitle: String {
        switch self {
            case .profileAuthent:   "Analyzing image"
            case .messageAnalysis:  "Analyzing conversation"
            case .locationInsights: "Analyzing photo location"
        }
    }
    
    var analyzeHints: [String] {
        switch self {
            case .profileAuthent:   [
                "Analyzing image content",
                "Checking public signals",
                "Reviewing context check",
                "Preparing your results"
            ]
            case .messageAnalysis:  [
                "Analyzing message patterns",
                "Detecting suspicious language",
                "Checking conversation context",
                "Preparing insights"
            ]
            case .locationInsights: [
                "Analyzing visual details",
                "Detecting landmarks",
                "Checking environment context",
                "Matching public references"
            ]
        }
    }
    
    var resultTitle: String {
        switch self {
            case .profileAuthent:   "Result"
            case .messageAnalysis:  "Conversation insights"
            case .locationInsights: "Location match found"
        }
    }
}

struct CheckCard: View {
    var check: CheckType
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                Text(check.rawValue)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.Colors.black)
                
                Text(check.text)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.Colors.black2.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Image(check.card)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90)
        }
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .embedInLightGlass(radius: 24, showShadow: true)
    }
}

#Preview {
    CheckCard(check: .profileAuthent)
}
