#if os(iOS)
import SwiftUI
import PhotosUI
import AVFoundation

@available(iOS 17, *)
struct MediaUploadView: View {
    @StateObject private var viewModel: MediaUploadViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var uploadedMediaURLs: [URL]
    
    let maxImages: Int
    let allowVideo: Bool
    let compressionQuality: CGFloat
    
    @MainActor
    init(maxImages: Int = 6, 
         allowVideo: Bool = false, 
         compressionQuality: CGFloat = 0.8,
         uploadedMediaURLs: Binding<[URL]> = .constant([])) {
        self.maxImages = maxImages
        self.allowVideo = allowVideo
        self.compressionQuality = compressionQuality
        self._uploadedMediaURLs = uploadedMediaURLs
        _viewModel = StateObject(wrappedValue: MediaUploadViewModel())
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                uploadSection
                mediaPreviewSection
                uploadProgressSection
            }
            .padding()
            .background(AroosiColors.groupedBackground)
            .navigationTitle("Upload Media")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        uploadedMediaURLs = viewModel.state.uploadedURLs
                        dismiss()
                    }
                    .disabled(viewModel.state.uploadedURLs.isEmpty || viewModel.state.isUploading)
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
            isPresented: $viewModel.state.showingPhotoPicker,
            selection: $viewModel.state.selectedItems,
            maxSelectionCount: maxImages - viewModel.state.uploadedURLs.count,
            matching: allowVideo ? .any(of: [.images, .videos]) : .images
        )
        .onChange(of: viewModel.state.selectedItems) { items in
            viewModel.processSelectedItems(items)
        }
    }
    
    private var uploadSection: some View {
        VStack(spacing: 16) {
            Text("Add Photos")
                .font(AroosiTypography.heading(.h3))
                .foregroundStyle(AroosiColors.primary)
            
            Text("Select up to \(maxImages) photos to showcase your personality")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button {
                    viewModel.state.showingPhotoPicker = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                        Text("Photo Library")
                            .font(AroosiTypography.caption())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AroosiColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.state.uploadedURLs.count >= maxImages)
                
                Button {
                    viewModel.showCamera()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.title2)
                        Text("Camera")
                            .font(AroosiTypography.caption())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AroosiColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.state.uploadedURLs.count >= maxImages)
            }
            
            if allowVideo {
                Button {
                    viewModel.showVideoPicker()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "video")
                            .font(.title2)
                        Text("Add Video")
                            .font(AroosiTypography.body())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AroosiColors.accent.opacity(0.1))
                    .foregroundStyle(AroosiColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.state.uploadedURLs.count >= maxImages)
            }
        }
        .padding(.vertical, 20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var mediaPreviewSection: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            
            ResponsiveVStack(width: width) {
                if viewModel.state.uploadedURLs.isEmpty {
                    ResponsiveCard(
                        width: width,
                        height: Responsive.mediaHeight(for: width, type: .card)
                    ) {
                        VStack(spacing: Responsive.spacing(width: width, multiplier: 0.8)) {
                            Image(systemName: "photo.stack")
                                .font(.title)
                                .foregroundStyle(AroosiColors.muted)
                            Text("No photos selected")
                                .font(AroosiTypography.body(width: width))
                                .foregroundStyle(AroosiColors.muted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    ResponsiveGrid(
                        columns: 3,
                        spacing: Responsive.spacing(width: width),
                        width: width
                    ) {
                        ForEach(Array(viewModel.state.uploadedURLs.enumerated()), id: \.offset) { index, url in
                            MediaThumbnailView(
                                url: url,
                                onDelete: {
                                    viewModel.removeMedia(at: index)
                                }
                            )
                        }
                        
                        if viewModel.state.uploadedURLs.count < maxImages {
                            Button {
                                viewModel.state.showingPhotoPicker = true
                            } label: {
                                ResponsiveCard(
                                    width: Responsive.frameSize(for: width, type: .smallSquare).width,
                                    height: Responsive.frameSize(for: width, type: .smallSquare).height
                                ) {
                                    VStack(spacing: Responsive.spacing(width: width, multiplier: 0.3)) {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                        Text("Add")
                                            .font(AroosiTypography.caption(width: width))
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                            .buttonStyle(.plain)
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
            
            if !viewModel.state.uploadedURLs.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AroosiColors.success)
                    Text("\(viewModel.state.uploadedURLs.count) of \(maxImages) photos uploaded")
                        .font(AroosiTypography.body())
                    Spacer()
                }
                .padding(.horizontal)
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
struct MediaThumbnailView: View {
    let url: URL
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
                    .progressViewStyle(.circular)
            }
            .frame(height: 100)
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
#Preview {
    MediaUploadView(uploadedMediaURLs: .constant([]))
        .environmentObject(NavigationCoordinator())
}

#endif
