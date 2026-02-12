import SwiftUI

struct ConversationView: View {
    var onAnotherConversation: () -> Void

    var concernLevel: Int
    var yourMessages: Int
    var theirMessages: Int
    var yourEngagement: String
    var theirEngagement: String

    var potentialConcerns: [ConcernItem]
    var positiveSignals: [String]

    init(
        onAnotherConversation: @escaping () -> Void,
        concernLevel: Int = 82,
        yourMessages: Int = 23,
        theirMessages: Int = 45,
        yourEngagement: String = "High",
        theirEngagement: String = "Medium",
        potentialConcerns: [ConcernItem] = [
            ConcernItem(title: "Urgency-related phrasing", example: "Example: \"I've been waiting for 10 minutes…\""),
            ConcernItem(title: "Repeated follow-up messages", example: "Example: \"I've been waiting for 10 minutes…\""),
            ConcernItem(title: "Imbalanced response timing", example: "Example: \"I've been waiting for 10 minutes…\"")
        ],
        positiveSignals: [String] = [
            "Consistent tone",
            "Clear responses",
            "Balanced message length"
        ]
    ) {
        self.onAnotherConversation = onAnotherConversation
        self.concernLevel = concernLevel
        self.yourMessages = yourMessages
        self.theirMessages = theirMessages
        self.yourEngagement = yourEngagement
        self.theirEngagement = theirEngagement
        self.potentialConcerns = potentialConcerns
        self.positiveSignals = positiveSignals
    }

    init(onAnotherConversation: @escaping () -> Void, result: CheaterResultEntity) {
        self.onAnotherConversation = onAnotherConversation
        self.concernLevel = result.riskScore
        self.yourMessages = result.messageCountYou
        self.theirMessages = result.messageCountThem
        self.yourEngagement = Self.engagementLabel(from: result.yourInterest)
        self.theirEngagement = Self.engagementLabel(from: result.theirInterest)
        self.potentialConcerns = result.redFlags.map {
            ConcernItem(title: $0.title, example: $0.desc)
        }
        self.positiveSignals = result.greenFlags.map { $0.desc }
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                concernLevelCard
                messagesCard
                engagementCard
                potentialConcernsCard
                positiveSignalsCard
                actionButton
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.Colors.primaryBG)
    }
    
    var concernLevelCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Conversation dynamics")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.Colors.black)
                
                Text("Based on detected conversation patterns")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.Colors.black2.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color(hex: "25262B").opacity(0.04), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(concernLevel) / 100)
                        .stroke(LinearGradient(
                            colors: [Color.Colors.accentTop, Color.Colors.accentBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        ), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                        .rotationEffect(Angle(degrees: -90))
                }
                .padding(4)
                .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Potential concern level")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.Colors.black.opacity(0.7))
                    
                    Text("\(concernLevel)%")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.Colors.black)
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .embedInLightGlass(radius: 24, showShadow: true)
    }
    
    var messagesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Conversation dynamics")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.Colors.black)
                
                Text("Messages sent")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.Colors.black2.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            let total = max(yourMessages + theirMessages, 1)
            VStack(spacing: 12) {
                messageRow(label: "You", count: yourMessages, percentage: Double(yourMessages) / Double(total))
                messageRow(label: "Them", count: theirMessages, percentage: Double(theirMessages) / Double(total))
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .embedInLightGlass(radius: 24, showShadow: true)
    }
    
    func messageRow(label: String, count: Int, percentage: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.Colors.black2)
                
                Spacer()
                
                Text("\(count)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.Colors.black)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.Colors.black2.opacity(0.04))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.Colors.accentTop, Color.Colors.accentBottom],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
    
    var engagementCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Engagement level")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.Colors.black)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 24) {
                engagementItem(label: "You", level: yourEngagement)
                
                Rectangle()
                    .fill(Color.Colors.black2.opacity(0.07))
                    .frame(width: 2, height: 32)
                
                engagementItem(label: "Them", level: theirEngagement)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .embedInLightGlass(radius: 24, showShadow: true)
    }
    
    func engagementItem(label: String, level: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color(hex: "25262B").opacity(0.04), lineWidth: 5)
                
                Circle()
                    .trim(from: 0, to: level == "High" ? 0.75 : 0.5)
                    .stroke(LinearGradient(
                        colors: [Color.Colors.accentTop, Color.Colors.accentBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    ), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .rotationEffect(Angle(degrees: -90))
            }
            .padding(2.5)
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.Colors.black2.opacity(0.8))
                
                Text(level)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.Colors.black2)
            }
        }
    }
    
    var potentialConcernsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 4) {
                Text("Potential concerns")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.Colors.black2)
                
                Text("(\(potentialConcerns.count))")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.Colors.black2.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(potentialConcerns.enumerated()), id: \.offset) { index, concern in
                    if index > 0 {
                        Rectangle()
                            .fill(Color.Colors.black2.opacity(0.07))
                            .frame(height: 1)
                            .padding(.leading, 27)
                    }
                    
                    concernRow(
                        icon: "info.circle.fill",
                        title: concern.title,
                        example: concern.example
                    )
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .embedInLightGlass(radius: 24, showShadow: true)
    }
    
    func concernRow(icon: String, title: String, example: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(.Icns.potential)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.Colors.black2)
                
                Text(example)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.Colors.black2.opacity(0.8))
            }
        }
        .multilineTextAlignment(.leading)
    }
    
    var positiveSignalsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 4) {
                Text("Positive signals")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.Colors.black2)
                
                Text("(\(positiveSignals.count))")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.Colors.black2.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(positiveSignals.enumerated()), id: \.offset) { index, signal in
                    if index > 0 {
                        Rectangle()
                            .fill(Color.Colors.black2.opacity(0.07))
                            .frame(height: 1)
                            .padding(.leading, 27)
                    }
                    
                    positiveSignalRow(title: signal)
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .embedInLightGlass(radius: 24, showShadow: true)
    }
    
    func positiveSignalRow(title: String) -> some View {
        HStack(spacing: 8) {
            Image(.Icns.positive)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.Colors.black2)
                .multilineTextAlignment(.leading)
        }
    }
    
    var actionButton: some View {
        PrimeButton(title: "Analyze another conversation", action: onAnotherConversation)
            .padding(.top, 10)
            .padding(.bottom, 8)
    }
}

struct ConcernItem {
    let title: String
    let example: String
}

private extension ConversationView {
    static func engagementLabel(from value: Int) -> String {
        switch value {
            case 70...:
                return "High"
            case 40...:
                return "Medium"
            default:
                return "Low"
        }
    }
}

#Preview {
    ConversationView(onAnotherConversation: { })
}
