#if os(iOS)
import SwiftUI
import AVFoundation

@available(iOS 17, *)
struct VoiceRecorderView: View {
    @StateObject private var viewModel: VoiceRecorderViewModel
    @Environment(\.dismiss) private var dismiss
    let onRecordingComplete: (URL) -> Void
    
    @MainActor
    init(onRecordingComplete: @escaping (URL) -> Void) {
        self.onRecordingComplete = onRecordingComplete
        _viewModel = StateObject(wrappedValue: VoiceRecorderViewModel())
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                recordingVisualizer
                recordingControls
                recordingInfo
            }
            .padding()
            .background(AroosiColors.groupedBackground)
            .navigationTitle("Voice Message")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.stopRecording()
                        dismiss()
                    }
                    .disabled(viewModel.state.isRecording)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        if let url = viewModel.state.recordingURL {
                            onRecordingComplete(url)
                            dismiss()
                        }
                    }
                    .disabled(viewModel.state.recordingURL == nil || viewModel.state.isRecording)
                }
            }
            .overlay(alignment: .top) {
                if let errorMessage = viewModel.state.errorMessage {
                    errorBanner(errorMessage)
                }
            }
        }
        .tint(AroosiColors.primary)
        .onAppear {
            viewModel.requestMicrophonePermission()
        }
    }
    
    private var recordingVisualizer: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AroosiColors.primary.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Circle()
                    .fill(AroosiColors.primary.opacity(0.2))
                    .frame(width: 160, height: 160)
                
                if viewModel.state.isRecording {
                    Circle()
                        .fill(AroosiColors.primary)
                        .frame(width: 120, height: 120)
                        .scaleEffect(viewModel.state.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: AroosiMotionDurations.medium).repeatForever(autoreverses: true), value: viewModel.state.isRecording)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                } else {
                    Circle()
                        .fill(AroosiColors.cardBackground)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "mic")
                        .font(.system(size: 40))
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            if viewModel.state.isRecording {
                Text("Recording...")
                    .font(AroosiTypography.body(weight: .semibold))
                    .foregroundStyle(AroosiColors.primary)
            } else if viewModel.state.recordingURL != nil {
                Text("Recording Complete")
                    .font(AroosiTypography.body(weight: .semibold))
                    .foregroundStyle(AroosiColors.success)
            }
        }
        .padding(.vertical, 40)
    }
    
    private var recordingControls: some View {
        HStack(spacing: 40) {
            Button {
                if viewModel.state.isRecording {
                    viewModel.pauseRecording()
                } else if viewModel.state.isPaused {
                    viewModel.resumeRecording()
                }
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: viewModel.state.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.title)
                    Text(viewModel.state.isPaused ? "Resume" : "Pause")
                        .font(AroosiTypography.caption())
                }
                .foregroundStyle(viewModel.state.isRecording || viewModel.state.isPaused ? AroosiColors.primary : AroosiColors.muted)
            }
            .disabled(!viewModel.state.isRecording && !viewModel.state.isPaused)
            
            Button {
                if viewModel.state.isRecording {
                    viewModel.stopRecording()
                } else {
                    viewModel.startRecording()
                }
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: viewModel.state.isRecording ? "stop.circle.fill" : "record.circle")
                        .font(.title)
                        .foregroundStyle(viewModel.state.isRecording ? AroosiColors.error : AroosiColors.primary)
                    Text(viewModel.state.isRecording ? "Stop" : "Record")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(viewModel.state.isRecording ? AroosiColors.error : AroosiColors.primary)
                }
            }
            
            Button {
                if viewModel.state.recordingURL != nil {
                    viewModel.deleteRecording()
                }
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "trash.circle")
                        .font(.title)
                    Text("Delete")
                        .font(AroosiTypography.caption())
                }
                .foregroundStyle(viewModel.state.recordingURL != nil ? AroosiColors.warning : AroosiColors.muted)
            }
            .disabled(viewModel.state.recordingURL == nil)
        }
    }
    
    private var recordingInfo: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Duration:")
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
                Spacer()
                Text(formatDuration(viewModel.state.recordingDuration))
                    .font(AroosiTypography.body(weight: .medium))
                    .foregroundStyle(AroosiColors.primary)
            }
            
            if viewModel.state.recordingURL != nil {
                HStack {
                    Text("File Size:")
                        .font(AroosiTypography.body())
                        .foregroundStyle(AroosiColors.muted)
                    Spacer()
                    Text(formatFileSize(viewModel.state.recordingFileSize))
                        .font(AroosiTypography.body(weight: .medium))
                        .foregroundStyle(AroosiColors.primary)
                }
            }
            
            if !viewModel.state.hasMicrophonePermission {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AroosiColors.warning)
                    Text("Microphone access is required to record voice messages")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.text)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
                .background(AroosiColors.warning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
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
#Preview {
    VoiceRecorderView { url in
        print("Recording completed: \(url)")
    }
    .environmentObject(NavigationCoordinator())
}

#endif
