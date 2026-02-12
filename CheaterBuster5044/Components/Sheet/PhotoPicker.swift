import SwiftUI
import UniformTypeIdentifiers

struct PickedMediaItem {
    let data: Data
    let suggestedName: String
    let typeRaw: String
}

import UIKit
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    var maxSelection: Int
    var includeVideos: Bool = false
    var onBeginLoading: ((Int) -> Void)? = nil
    var onComplete: (([UIImage]) -> Void)? = nil
    var onPickedMedia: (([PickedMediaItem]) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = maxSelection
        config.filter = includeVideos ? .any(of: [.images, .videos]) : .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator

        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        var expectedCount: Int = 0
        var loadedCount: Int = 0
        var pickedItems: [PickedMediaItem] = []

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            DispatchQueue.main.async { self.parent.onBeginLoading?(results.count) }
            picker.dismiss(animated: true, completion: nil)

            parent.images = []
            expectedCount = results.count
            loadedCount = 0
            pickedItems = []

            let itemProviders = results.map { $0.itemProvider }

            for provider in itemProviders {
                if expectedCount == 0 { break }
                if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) || provider.hasItemConformingToTypeIdentifier(UTType.video.identifier) {
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                        self.handleLoadedFile(url: url, error: error, fallbackImageFrom: provider)
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.jpeg.identifier) {
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.jpeg.identifier) { url, error in
                        self.handleLoadedFile(url: url, error: error, fallbackImageFrom: provider)
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.png.identifier) {
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.png.identifier) { url, error in
                        self.handleLoadedFile(url: url, error: error, fallbackImageFrom: provider)
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.heic.identifier) {
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.heic.identifier) { url, error in
                        self.handleLoadedFile(url: url, error: error, fallbackImageFrom: provider)
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                        self.handleLoadedFile(url: url, error: error, fallbackImageFrom: provider)
                    }
                } else if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { image, error in
                        self.handleLoadedImage(image: image as? UIImage, provider: provider)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.incrementAndFinishIfNeeded()
                    }
                }
            }
        }

        private func handleLoadedFile(url: URL?, error: Error?, fallbackImageFrom provider: NSItemProvider) {
            if let url {
                do {
                    let data = try Data(contentsOf: url)
                    let filename = url.lastPathComponent
                    let ext = url.pathExtension.lowercased()
                    let name = url.deletingPathExtension().lastPathComponent
                    let item = PickedMediaItem(data: data, suggestedName: name, typeRaw: ext)
                    DispatchQueue.main.async {
                        if let image = UIImage(data: data) {
                            self.parent.images.append(image)
                        }
                        self.pickedItems.append(item)
                        self.incrementAndFinishIfNeeded()
                    }
                    return
                } catch {
                }
            }
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    self.handleLoadedImage(image: image as? UIImage, provider: provider)
                }
            } else {
                DispatchQueue.main.async { self.incrementAndFinishIfNeeded() }
            }
        }

        private func handleLoadedImage(image: UIImage?, provider: NSItemProvider) {
            DispatchQueue.main.async {
                if let image {
                    self.parent.images.append(image)
                    if let data = image.jpegData(compressionQuality: 0.95) ?? image.pngData() {
                        let type = image.jpegData(compressionQuality: 0.95) != nil ? "jpg" : "png"
                        let suggested = provider.suggestedName ?? "Photo"
                        let item = PickedMediaItem(data: data, suggestedName: suggested, typeRaw: type)
                        self.pickedItems.append(item)
                    }
                }
                self.incrementAndFinishIfNeeded()
            }
        }

        private func incrementAndFinishIfNeeded() {
            loadedCount += 1
            if loadedCount == expectedCount {
                parent.onComplete?(parent.images)
                parent.onPickedMedia?(pickedItems)
            }
        }
    }
}



struct DocumentPicker: UIViewControllerRepresentable {
    var allowsMultipleSelection: Bool = false
    var contentTypes: [UTType] = [.image, .jpeg, .png, .heic]
    var onDocumentsPicked: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = allowsMultipleSelection
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentsPicked: onDocumentsPicked)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentsPicked: ([URL]) -> Void

        init(onDocumentsPicked: @escaping ([URL]) -> Void) {
            self.onDocumentsPicked = onDocumentsPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onDocumentsPicked(urls)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onDocumentsPicked([])
        }
    }
}
