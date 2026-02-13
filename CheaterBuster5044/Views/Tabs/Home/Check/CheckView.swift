import SwiftUI

struct CheckView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var purchaseManager: PurchaseManager
    let checkType: CheckType
    @State private var showPaywall: Bool = false
    @State private var showConsentAlert: Bool = false
    
    @AppStorage("aiConsentProfileAuthent") private var consentProfileAuthent = false
    @AppStorage("aiConsentMessageAnalysis") private var consentMessageAnalysis = false
    @AppStorage("aiConsentLocationInsights") private var consentLocationInsights = false
    
    @StateObject private var checkVM: CheckVM
    @State private var showLikeResultSheet: Bool = false
    
    private var isConsentGiven: Bool {
        switch checkType {
        case .profileAuthent: consentProfileAuthent
        case .messageAnalysis: consentMessageAnalysis
        case .locationInsights: consentLocationInsights
        }
    }
    
    init(checkType: CheckType) {
        self.checkType = checkType
        _checkVM = StateObject(wrappedValue: CheckVM())
    }

    init(checkType: CheckType, checkVM: CheckVM) {
        self.checkType = checkType
        _checkVM = StateObject(wrappedValue: checkVM)
    }

    init(checkType: CheckType, personResult: PersonResultEntity, img: UIImage? = nil) {
        self.checkType = checkType
        let vm = CheckVM()
        vm.step = .result
        vm.personResult = personResult
        vm.img = img
            ?? ImageCache.shared.entityImage(forEntityType: .person, id: personResult.id)
            ?? personResult.queryUIImage
        _checkVM = StateObject(wrappedValue: vm)
    }

    init(checkType: CheckType, conversationResult: CheaterResultEntity, img: UIImage? = nil) {
        self.checkType = checkType
        let vm = CheckVM()
        vm.step = .result
        vm.conversationResult = conversationResult
        vm.img = img
            ?? ImageCache.shared.entityImage(forEntityType: .cheater, id: conversationResult.id)
            ?? conversationResult.queryUIImage
        _checkVM = StateObject(wrappedValue: vm)
    }

    init(checkType: CheckType, locationResult: LocationResultEntity, img: UIImage? = nil) {
        self.checkType = checkType
        let vm = CheckVM()
        vm.step = .result
        vm.locationResult = locationResult
        vm.img = img
            ?? ImageCache.shared.entityImage(forEntityType: .location, id: locationResult.id)
            ?? locationResult.uiImage
        _checkVM = StateObject(wrappedValue: vm)
    }
    var headerTitle: String {
        switch checkVM.step {
            case .addPhoto:     checkType.rawValue
            case .rotateCrop:   checkType.rotateCropTitle
            case .analyze:      checkType.analyzeTitle
            case .result:       checkType.resultTitle
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            main
        }
        .background(Color.Colors.primaryBG)
        .animation(.interpolatingSpring(duration: 0.2), value: checkVM.step)
        .sheet(isPresented: $showLikeResultSheet) {
            DoYouLikeResultSheet(onNo: { }, onYes: { })
        }
        .onAppear {
            handleResultAppearance()
        }
        .onChange(of: checkVM.step) { _, newValue in
            guard newValue == .result else { return }
            handleResultAppearance()
        }
        
        .sheet(isPresented: $checkVM.showPhotoSourcePick) {
            ChoosePhotoSourceSheet(onImg: { img in
                checkVM.loadImage(img)
            })
        }
        .fullScreenCover(isPresented: $checkVM.showCropSheet) {
            if let img = checkVM.img {
                CropImage(image: img, onDone: {
                    checkVM.img = $0
                })
            }
        }
        
        .fullScreenCover(isPresented: $showPaywall, content: {
            PaywallView()
        })
        .overlay {
            if showConsentAlert {
                CheckAlert(
                    checkType: checkType,
                    onCancel: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            showConsentAlert = false
                        }
                    },
                    onContinue: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            showConsentAlert = false
                        }
                        saveConsentAndAnalyze()
                    }
                )
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.9), value: showConsentAlert)
        .toolbar(.hidden)
    }
    
    var header: some View {
        Text(headerTitle)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Color.Colors.black)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 48)
            .frame(height: 40)
            .overlay(alignment: .leading) {
                CircleGlassButton(icn: .Icns.chevronLeft, action: {
                    dismiss()
                })
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
    }
    
    var main: some View {
        
        ZStack {
            switch checkVM.step {
                case .addPhoto:
                    addPhotoPart
                case .rotateCrop, .analyze:
                    rotateCropPart
                case .result:
                    resultPart
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var addPhotoPart: some View {
        Button {
            checkVM.showPhotoSourcePick = true
        } label: {
            VStack(spacing: 16) {
                Image(.Icns.add)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .padding(16)
                    .embedInLightGlass(radius: 24, showShadow: true)
                
                VStack(spacing: 8) {
                    Text("Add a photo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.Colors.black2)
                    
                    Text("Choose where to upload a photo from")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.Colors.black2)
                }
            }
            .padding(.vertical, 41)
            .frame(maxWidth: .infinity)
            .embedInLightGlass(radius: 24, showShadow: true)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
    
    private var rotateCropPart: some View {
        VStack(spacing: 42) {
            VStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.Colors.primaryBG)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        if let img = checkVM.img {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: .infinity)
                        }
                    }
                
                if checkVM.step == .rotateCrop {
                    HStack(spacing: 24) {
                        CircleGlassButton(icn: .Icns.rotateLeft, action: {
                            checkVM.rotateLeft()
                        })
                        
                        CircleGlassButton(icn: .Icns.crop, action: {
                            checkVM.showCropSheet = true
                        })
                        
                        CircleGlassButton(icn: .Icns.rotateRight, action: {
                            checkVM.rotateRight()
                        })
                    }
                }
            }
            
            if checkVM.step == .rotateCrop {
                PrimeButton(title: checkType.analyzeButtonTitle, action: {
                    guard purchaseManager.isSubscribed else {
                        showPaywall = true
                        return
                    }
                    
                    if isConsentGiven {
                        checkVM.startAnalyze(checkType: checkType, modelContext: modelContext)
                    } else {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            showConsentAlert = true
                        }
                    }
                })
            }
            
            if checkVM.step == .analyze {
                analyzePart
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
    
    private var analyzePart: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(checkType.analyzeHints.indices, id: \.self) { ind in
                var isReached: Bool { checkVM.analyzeIndex > ind }
                var isCurrentReach: Bool { checkVM.analyzeIndex >= ind }
                
                HStack(spacing: 8) {
                    if isReached {
                        Image(.Icns.done)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.Colors.accentTop)
                            .frame(width: 20, height: 20)
                    }
                    
                    Text(checkType.analyzeHints[ind])
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.Colors.black2)
                }
                .opacity(isCurrentReach ? 1 : 0.5)
                
                .animation(.easeInOut(duration: 0.2), value: isReached)
                .animation(.easeInOut(duration: 0.2), value: isCurrentReach)
            }
        }
        .padding(.bottom, 42)
    }
    
    private var resultPart: some View {
        Group {
            switch checkType {
                case .profileAuthent:
                    if let result = checkVM.personResult {
                        ProfileResultView(onTryAnotherPhoto: {
                            checkVM.personResult = nil
                            checkVM.step = .addPhoto
                        }, result: result)
                    } else {
                        ProfileResultView(onTryAnotherPhoto: {
                            checkVM.personResult = nil
                            checkVM.step = .addPhoto
                        })
                    }
                case .messageAnalysis:
                    if let result = checkVM.conversationResult {
                        ConversationView(onAnotherConversation: {
                            checkVM.conversationResult = nil
                            checkVM.step = .addPhoto
                        }, result: result)
                    } else {
                        ConversationView(
                            onAnotherConversation: {
                                checkVM.conversationResult = nil
                                checkVM.step = .addPhoto
                            },
                            concernLevel: 0,
                            yourMessages: 0,
                            theirMessages: 0,
                            yourEngagement: "Low",
                            theirEngagement: "Low",
                            potentialConcerns: checkVM.errorMessage.map {
                                [ConcernItem(title: "Error", example: $0)]
                            } ?? [],
                            positiveSignals: []
                        )
                    }
                case .locationInsights:
                    if let result = checkVM.locationResult {
                        LocationResultView(
                            img: checkVM.img,
                            visualMatch: 82,
                            title: result.locationText,
                            onAnotherPhoto: {
                                checkVM.locationResult = nil
                                checkVM.step = .addPhoto
                            }
                        )
                    } else {
                        LocationResultView(
                            img: checkVM.img,
                            visualMatch: 0,
                            title: checkVM.errorMessage ?? "No location data",
                            onAnotherPhoto: {
                                checkVM.locationResult = nil
                                checkVM.step = .addPhoto
                            }
                        )
                    }
            }
        }
    }
}

private extension CheckView {
    func saveConsentAndAnalyze() {
        switch checkType {
        case .profileAuthent: consentProfileAuthent = true
        case .messageAnalysis: consentMessageAnalysis = true
        case .locationInsights: consentLocationInsights = true
        }
        checkVM.startAnalyze(checkType: checkType, modelContext: modelContext)
    }
    
    func handleResultAppearance() {
        guard checkVM.step == .result else { return }

        switch checkType {
            case .locationInsights:
                guard let result = checkVM.locationResult,
                      result.userVoted == false else { return }
                result.userVoted = true
            case .messageAnalysis:
                guard let result = checkVM.conversationResult,
                      result.userVoted == false else { return }
                result.userVoted = true
            case .profileAuthent:
                guard let result = checkVM.personResult,
                      result.userVoted == false else { return }
                result.userVoted = true
        }

        try? modelContext.save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showLikeResultSheet = true
        }
    }
}

#Preview("CheckView - default") {
    CheckView(checkType: .profileAuthent)
        .environmentObject(PurchaseManager.shared)
}

#Preview("CheckView - injected VM") {
    let checkVM = CheckVM()
    checkVM.step = .addPhoto
    return CheckView(checkType: .locationInsights, checkVM: checkVM)
        .environmentObject(PurchaseManager.shared)
}

#Preview("CheckView - location result") {
    let result = LocationResultEntity(
        locationText: "Place de Stanislas, Nancy, France",
        mapSnapshotData: UIImage.rateUs.pngData()
    )
    return CheckView(checkType: .locationInsights, locationResult: result)
        .environmentObject(PurchaseManager.shared)
}

#Preview("CheckView - conversation result") {
    let flags = [
        FlagEntity(title: "Red Flag", desc: "Urgency-related phrasing", isRed: true),
        FlagEntity(title: "Recommendation", desc: "Keep responses balanced", isRed: false)
    ]
    let result = CheaterResultEntity(
        riskScore: 72,
        yourInterest: 65,
        theirInterest: 45,
        messageCountYou: 18,
        messageCountThem: 27,
        flags: flags,
        queryImageData: UIImage.rateUs.pngData()
    )
    return CheckView(checkType: .messageAnalysis, conversationResult: result)
        .environmentObject(PurchaseManager.shared)
}

#Preview("CheckView - profile result") {
    let alice = PersonEntity(
        name: "Alice Smith",
        imageData: UIImage.rateUs.pngData(),
        linkURLString: "https://www.instagram.com/",
        sourceText: "Instagram",
        siteHost: "instagram.com"
    )
    let bob = PersonEntity(
        name: "Bob Jones",
        imageData: UIImage.rateUs.pngData(),
        linkURLString: "https://www.tinder.com/",
        sourceText: "Tinder",
        siteHost: "tinder.com"
    )
    let result = PersonResultEntity(
        foundPeople: [alice, bob],
        queryImageData: UIImage.rateUs.pngData()
    )
    return CheckView(checkType: .profileAuthent, personResult: result)
        .environmentObject(PurchaseManager.shared)
}
