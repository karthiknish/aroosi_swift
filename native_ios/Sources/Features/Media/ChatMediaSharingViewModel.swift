#if os(iOS)
import Foundation
import PhotosUI
import Combine
import SwiftUI

@available(iOS 17, *)
@MainActor
final class ChatMediaSharingViewModel: ObservableObject {
    struct State {
        enum MediaType {
            case photo
            case voice
        }

        var selectedItems: [PhotosPickerItem] = []
        var uploadedURLs: [URL] = []
        var isUploading = false
        var uploadProgress: Double = 0
        var errorMessage: String?
        var showingPhotoPicker = false
        var showingVoiceRecorder = false
        var selectedMediaType: MediaType = .photo
    }

    @Published private(set) var state = State()

    private let conversationID: String
    private let mediaUploadViewModel: MediaUploadViewModel
    private var cancellables = Set<AnyCancellable>()

    init(conversationID: String,
         mediaUploadViewModel: MediaUploadViewModel? = nil) {
        self.conversationID = conversationID
        self.mediaUploadViewModel = mediaUploadViewModel ?? MediaUploadViewModel()
        bindToMediaState()
    }

    func processSelectedItems(_ items: [PhotosPickerItem]) {
        state.selectedMediaType = .photo
        state.selectedItems = items
        mediaUploadViewModel.state.selectedItems = items
        mediaUploadViewModel.processSelectedItems(items)
    }

    func processVoiceRecording(_ url: URL) {
        state.selectedMediaType = .voice
        state.uploadedURLs.append(url)
    }

    func sendMedia(_ urls: [URL], to conversationID: String) async throws {
        guard !urls.isEmpty else { return }
        // TODO: Integrate with chat repository once available.
        try await Task.sleep(nanoseconds: 50_000_000)
    }

    func clearError() {
        state.errorMessage = nil
        mediaUploadViewModel.clearError()
    }

    func presentPhotoPicker() {
        state.selectedMediaType = .photo
        state.showingPhotoPicker = true
        mediaUploadViewModel.state.showingPhotoPicker = true
    }

    func presentVoiceRecorder() {
        state.selectedMediaType = .voice
        state.showingVoiceRecorder = true
    }

    var photoPickerBinding: Binding<Bool> {
        Binding(
            get: { self.state.showingPhotoPicker },
            set: { newValue in
                self.state.showingPhotoPicker = newValue
                self.mediaUploadViewModel.state.showingPhotoPicker = newValue
            }
        )
    }

    var selectedItemsBinding: Binding<[PhotosPickerItem]> {
        Binding(
            get: { self.state.selectedItems },
            set: { newItems in
                self.state.selectedItems = newItems
                self.mediaUploadViewModel.state.selectedItems = newItems
            }
        )
    }

    var voiceRecorderBinding: Binding<Bool> {
        Binding(
            get: { self.state.showingVoiceRecorder },
            set: { newValue in
                self.state.showingVoiceRecorder = newValue
            }
        )
    }

    private func bindToMediaState() {
        mediaUploadViewModel.state.$selectedItems
            .receive(on: RunLoop.main)
            .sink { [weak self] items in
                self?.state.selectedItems = items
            }
            .store(in: &cancellables)

        mediaUploadViewModel.state.$uploadedURLs
            .receive(on: RunLoop.main)
            .sink { [weak self] urls in
                self?.state.uploadedURLs = urls
            }
            .store(in: &cancellables)

        mediaUploadViewModel.state.$isUploading
            .receive(on: RunLoop.main)
            .sink { [weak self] isUploading in
                self?.state.isUploading = isUploading
            }
            .store(in: &cancellables)

        mediaUploadViewModel.state.$uploadProgress
            .receive(on: RunLoop.main)
            .sink { [weak self] progress in
                self?.state.uploadProgress = progress
            }
            .store(in: &cancellables)

        mediaUploadViewModel.state.$errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                self?.state.errorMessage = error
            }
            .store(in: &cancellables)

        mediaUploadViewModel.state.$showingPhotoPicker
            .receive(on: RunLoop.main)
            .sink { [weak self] showing in
                self?.state.showingPhotoPicker = showing
            }
            .store(in: &cancellables)
    }
}

#endif
