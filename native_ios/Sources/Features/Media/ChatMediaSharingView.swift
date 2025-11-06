#if os(iOS)
import SwiftUI
import PhotosUI
import AVFoundation

@available(iOS 17, *)
struct ChatMediaSharingView: View {
    @StateObject private var viewModel: ChatMediaSharingViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var sharedMediaURLs: [URL]
    
    let conversationID: String
    let maxImages: Int = 4
    let maxVideoDuration: TimeInterval = 30 // seconds
    
    @MainActor
    init(conversationID: String, sharedMediaURLs: Binding<[URL]> = .constant([])) {
        self.conversationID = conversationID
        self._sharedMediaURLs = sharedMediaURLs
        _viewModel = StateObject(wrappedValue: ChatMediaSharingViewModel(conversationID: conversationID))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                mediaTypeSelector
                mediaContentSection
                uploadProgressSection
                actionButtons
            }
            .padding()
            .background(AroosiColors.groupedBackground)
            .navigationTitle("Share Media")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        sendMedia()
                    }
                    .disabled(sharedMediaURLs.isEmpty || viewModel.state.isUploading)
                }
                
                if viewModel.state.isUploading {
                    ToolbarItem(placement: .principal) {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
            .overlay(alignment: .top) {
                if let errorMessage = viewModel.state.errorMessage {
                    errorBanner(errorMessage)
                }
            }
        }
        .tint(AroosiColors.primary)
        .photosPicker(
            isPresented: viewModel.photoPickerBinding,
            selection: viewModel.selectedItemsBinding,
            maxSelectionCount: maxImages - sharedMediaURLs.count,
            matching: .any(of: [.images, .videos])
        )
        .sheet(isPresented: viewModel.voiceRecorderBinding) {
            VoiceRecorderView(
                onRecordingComplete: { audioURL in
                    viewModel.processVoiceRecording(audioURL)
                }
            )
            .presentationDetents([.medium])
        }
        .onChange(of: viewModel.state.selectedItems) { items in
            viewModel.processSelectedItems(items)
        }
        .onChange(of: viewModel.state.uploadedURLs) { urls in
            sharedMediaURLs = urls
        }
    }
    
    private var mediaTypeSelector: some View {
        VStack(spacing: 16) {
            Text("Choose Media Type")
                .font(AroosiTypography.heading(.h3))
                .foregroundStyle(AroosiColors.primary)
            
            HStack(spacing: 16) {
                Button {
                    viewModel.presentPhotoPicker()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                        Text("Photos")
                            .font(AroosiTypography.caption())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.state.selectedMediaType == .photo ? AroosiColors.primary : AroosiColors.cardBackground)
                    .foregroundStyle(viewModel.state.selectedMediaType == .photo ? .white : AroosiColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    viewModel.presentVoiceRecorder()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "mic")
                            .font(.title2)
                        Text("Voice")
                            .font(AroosiTypography.caption())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.state.selectedMediaType == .voice ? AroosiColors.primary : AroosiColors.cardBackground)
                    .foregroundStyle(viewModel.state.selectedMediaType == .voice ? .white : AroosiColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.vertical, 20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var mediaContentSection: some View {
        VStack(spacing: 16) {
            if sharedMediaURLs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo.stack")
                        .font(.title)
                        .foregroundStyle(AroosiColors.muted)
                    Text("No media selected")
                        .font(AroosiTypography.body())
                        .foregroundStyle(AroosiColors.muted)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .background(AroosiColors.groupedSecondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(Array(sharedMediaURLs.enumerated()), id: \.offset) { index, url in
                        ChatMediaThumbnailView(
                            url: url,
                            onDelete: {
                                removeMedia(at: index)
                            }
                        )
                    }
                    
                    if sharedMediaURLs.count < maxImages {
                        Button {
                            viewModel.presentPhotoPicker()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                Text("Add")
                                    .font(AroosiTypography.caption())
                            }
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .background(AroosiColors.groupedSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }
    
    private var uploadProgressSection: some View {
        VStack(spacing: 12) {
            if viewModel.state.isUploading {
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.state.uploadProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("Uploading... \(Int(viewModel.state.uploadProgress * 100))%")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
                .padding(.horizontal)
            }
            
            if !sharedMediaURLs.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AroosiColors.success)
                    Text("\(sharedMediaURLs.count) media files ready")
                        .font(AroosiTypography.body())
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                sendMedia()
            } label: {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("Send Media")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AroosiColors.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(sharedMediaURLs.isEmpty || viewModel.state.isUploading)
            
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AroosiColors.cardBackground)
                    .foregroundStyle(AroosiColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func removeMedia(at index: Int) {
        guard index < sharedMediaURLs.count else { return }
        sharedMediaURLs.remove(at: index)
    }
    
    private func sendMedia() {
        Task {
            do {
                try await viewModel.sendMedia(sharedMediaURLs, to: conversationID)
                dismiss()
            } catch {
                viewModel.state.errorMessage = "Failed to send media: \(error.localizedDescription)"
            }
        }
    }
    
    private func errorBanner(_ message: String) -> some View {
        VStack {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(AroosiColors.error.opacity(0.85))
                .clipShape(Capsule())
                .padding(.top, 8)
                .onTapGesture {
                    viewModel.clearError()
                }
            Spacer()
        }
    }
}

@available(iOS 17, *)
struct ChatMediaThumbnailView: View {
    let url: URL
    let onDelete: () -> Void
    
    private var isVideo: Bool {
        url.pathExtension.lowercased() == "mp4" || 
        url.pathExtension.lowercased() == "mov" ||
        url.pathExtension.lowercased() == "avi"
    }
    
    private var isAudio: Bool {
        url.pathExtension.lowercased() == "m4a" ||
        url.pathExtension.lowercased() == "mp3" ||
        url.pathExtension.lowercased() == "wav"
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if isVideo {
                VideoThumbnailView(url: url)
            } else if isAudio {
                AudioThumbnailView(url: url)
            } else {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white)
                    .background(Circle().fill(AroosiColors.background.opacity(0.6)))
            }
            .offset(x: 4, y: -4)
        }
    }
}

@available(iOS 17, *)
struct VideoThumbnailView: View {
    let url: URL
    @State private var thumbnail: UIImage?
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(AroosiColors.muted.opacity(0.3))
            }
            
            Image(systemName: "play.circle.fill")
                .font(.title)
                .foregroundStyle(.white)
                .background(Circle().fill(AroosiColors.background.opacity(0.5)))
        }
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        Task {
            do {
                thumbnail = try await MediaProcessingUtilities.generateThumbnail(from: url)
            } catch {
                print("Failed to generate thumbnail: \(error)")
            }
        }
    }
}

@available(iOS 17, *)
struct AudioThumbnailView: View {
    let url: URL
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(AroosiColors.accent.opacity(0.1))
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "waveform")
                            .font(.title)
                            .foregroundStyle(AroosiColors.accent)
                        Text("Voice Message")
                            .font(AroosiTypography.caption())
                            .foregroundStyle(AroosiColors.accent)
                    }
                )
        }
    }
}

@available(iOS 17, *)
#Preview {
    ChatMediaSharingView(conversationID: "test-conversation")
        .environmentObject(NavigationCoordinator())
}

#endif
