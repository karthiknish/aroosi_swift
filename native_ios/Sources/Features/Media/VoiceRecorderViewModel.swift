#if os(iOS)
import Foundation
import AVFoundation
import Combine

@available(iOS 17, *)
@MainActor
final class VoiceRecorderViewModel: NSObject, ObservableObject {
    @Published var state = VoiceRecorderState()
    
    private var audioRecorder: AVAudioRecorder?
    private var audioEngine: AVAudioEngine?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private let maxRecordingDuration: TimeInterval = 60 // 1 minute max
    private let permissionManager: PermissionManager
    
    init(permissionManager: PermissionManager = .shared) {
        self.permissionManager = permissionManager
        super.init()
        setupAudioSession()
    }
    
    deinit {
        stopRecording()
        timer?.invalidate()
    }
    
    func requestMicrophonePermission() async {
        do {
            let granted = await permissionManager.handleMicrophonePermission()
            state.hasMicrophonePermission = granted
            
            if !granted {
                state.errorMessage = "Microphone permission is required for voice recording"
            }
        } catch {
            state.errorMessage = "Failed to request microphone permission: \(error.localizedDescription)"
        }
    }
    
    func startRecording() {
        guard state.hasMicrophonePermission else {
            state.errorMessage = "Microphone permission not granted"
            return
        }
        
        guard !state.isRecording else { return }
        
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioURL = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            state.isRecording = true
            state.isPaused = false
            state.recordingURL = audioURL
            state.recordingDuration = 0
            
            startTimer()
            
        } catch {
            state.errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func pauseRecording() {
        guard state.isRecording else { return }
        
        audioRecorder?.pause()
        state.isPaused = true
        timer?.invalidate()
    }
    
    func resumeRecording() {
        guard state.isPaused else { return }
        
        audioRecorder?.record()
        state.isPaused = false
        startTimer()
    }
    
    func stopRecording() {
        guard state.isRecording || state.isPaused else { return }
        
        audioRecorder?.stop()
        audioRecorder = nil
        state.isRecording = false
        state.isPaused = false
        
        // Show success toast for recording completed
        if state.recordingURL != nil {
            ToastManager.shared.showSuccess("Voice recording completed!")
        }
        
        timer?.invalidate()
        timer = nil
    }
    
    func deleteRecording() {
        stopRecording()
        
        if let url = state.recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        state.recordingURL = nil
        state.recordingDuration = 0
        state.recordingFileSize = 0
    }
    
    func clearError() {
        state.errorMessage = nil
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRecordingDuration()
            }
        }
    }
    
    private func updateRecordingDuration() {
        guard let recorder = audioRecorder else { return }
        
        state.recordingDuration = recorder.currentTime
        
        // Auto-stop if max duration reached
        if state.recordingDuration >= maxRecordingDuration {
            stopRecording()
        }
    }
    
    private func updateRecordingInfo() {
        guard let url = state.recordingURL else { return }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                state.recordingFileSize = fileSize
            }
        } catch {
            print("Failed to get file attributes: \(error)")
        }
    }
}

// MARK: - AVAudioRecorderDelegate

@available(iOS 17, *)
@MainActor
extension VoiceRecorderViewModel: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            state.errorMessage = "Recording failed to complete"
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            state.errorMessage = "Recording error: \(error.localizedDescription)"
        }
    }
}

// MARK: - State

@available(iOS 17, *)
class VoiceRecorderState: ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingURL: URL?
    @Published var recordingDuration: TimeInterval = 0
    @Published var recordingFileSize: Int64 = 0
    @Published var hasMicrophonePermission = false
    @Published var errorMessage: String?
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Audio Processing Utilities

class AudioProcessingUtilities {
    static func compressAudioFile(_ inputURL: URL, outputURL: URL, quality: Float = 0.7) async throws {
        let asset = AVAsset(url: inputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetLowQuality) else {
            throw AudioError.compressionFailed
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.shouldOptimizeForNetworkUse = true
        
        try await exportSession.export()
        
        if exportSession.status == .failed {
            throw exportSession.error ?? AudioError.compressionFailed
        }
    }
    
    static func generateWaveform(from audioURL: URL) async throws -> [Float] {
        let asset = AVAsset(url: audioURL)
        
        guard let track = asset.tracks(withMediaType: .audio).first else {
            throw AudioError.noAudioTrack
        }
        
        let reader = try AVAssetReader(asset: asset)
        let settings = [AVFormatIDKey: kAudioFormatLinearPCM,
                       AVLinearPCMBitDepthKey: 16,
                       AVLinearPCMIsBigEndianKey: false,
                       AVLinearPCMIsFloatKey: false,
                       AVLinearPCMIsNonInterleaved: false]
        
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        reader.add(output)
        
        reader.startReading()
        
        var samples: [Float] = []
        var bufferSize = 1024
        
        while reader.status == .reading {
            if let sampleBuffer = output.copyNextSampleBuffer(),
               let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                let length = CMBlockBufferGetDataLength(blockBuffer)
                var data = Data(count: length)
                data.withUnsafeMutableBytes { buffer in
                    CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: buffer.baseAddress!)
                }
                
                let channelData = data.withUnsafeBytes { buffer in
                    buffer.bindMemory(to: Int16.self)
                }
                
                let frameCount = length / 2
                var sum: Float = 0
                
                for i in 0..<frameCount {
                    let sample = Float(channelData[i]) / Float(Int16.max)
                    sum += abs(sample)
                }
                
                let average = sum / Float(frameCount)
                samples.append(average)
            }
        }
        
        if reader.status == .failed {
            throw reader.error ?? AudioError.waveformGenerationFailed
        }
        
        return samples
    }
}

// MARK: - Errors

enum AudioError: Error {
    case compressionFailed
    case noAudioTrack
    case waveformGenerationFailed
    case permissionDenied
    case recordingFailed
    
    var localizedDescription: String {
        switch self {
        case .compressionFailed:
            return "Failed to compress audio file"
        case .noAudioTrack:
            return "No audio track found in file"
        case .waveformGenerationFailed:
            return "Failed to generate audio waveform"
        case .permissionDenied:
            return "Microphone permission denied"
        case .recordingFailed:
            return "Audio recording failed"
        }
    }
}

#endif
