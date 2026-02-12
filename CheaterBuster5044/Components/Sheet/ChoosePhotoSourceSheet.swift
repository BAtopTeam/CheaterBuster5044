import Photos
import SwiftUI
import UniformTypeIdentifiers

struct ChoosePhotoSourceSheet: View {
    @Environment(\.dismiss) var dismiss
    var onImg: (UIImage) -> Void
    
    @State private var showGalleryPick: Bool = false
    @State private var showFilesPick: Bool = false
    @State private var galleryImages: [UIImage] = []
    @State private var showGalleryPermissionAlert: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.Colors.black2.opacity(0.2))
                .frame(width: 24, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.bottom, 1)
            
            Text("Choose a photo source")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.Colors.black2)
            
            pickers
                .padding(.bottom, 6)
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.Colors.primaryBG)
        .presentationDetents([.height(192)])
        .presentationCornerRadius(24)
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showGalleryPick) {
            PhotoPicker(
                images: $galleryImages,
                maxSelection: 1,
                includeVideos: false,
                onComplete: { images in
                    if let firstImage = images.first {
                        onImg(firstImage)
                        dismiss()
                    }
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showFilesPick) {
            DocumentPicker(
                allowsMultipleSelection: false,
                contentTypes: [.image, .jpeg, .png, .heic],
                onDocumentsPicked: { urls in
                    if let firstURL = urls.first,
                       let imageData = try? Data(contentsOf: firstURL),
                       let image = UIImage(data: imageData) {
                        onImg(image)
                        dismiss()
                    }
                }
            )
            .ignoresSafeArea()
        }
        .alert("Gallery Access Needed", isPresented: $showGalleryPermissionAlert) {
            Button("Open Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please allow photo library access in Settings to import photos.")
        }
    }
    
    var pickers: some View {
        VStack(spacing: 8) {
            SettingsButton(icn: .Icns.gallery,
                           title: "Gallery", showChevron: false, onAction: {
                requestGalleryAccess()
            })
            
            SettingsButton(icn: .Icns.files,
                           title: "Files", showChevron: false, onAction: {
                showFilesPick = true
            })
        }
    }

    private func requestGalleryAccess() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
            case .authorized, .limited:
                showGalleryPick = true
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                    DispatchQueue.main.async {
                        switch newStatus {
                            case .authorized, .limited:
                                showGalleryPick = true
                            default:
                                showGalleryPermissionAlert = true
                        }
                    }
                }
            default:
                showGalleryPermissionAlert = true
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    @Previewable @State var showSheet: Bool = false
    
    Button("Show Sheet") {
        showSheet.toggle()
    }
    .buttonStyle(.borderedProminent)
    .sheet(isPresented: $showSheet) {
        ChoosePhotoSourceSheet(onImg: { _ in })
    }
}
