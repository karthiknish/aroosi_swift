import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// Simple voice recorder widget (long press to record) producing bytes + duration.
/// This is a minimal MVP to enable voice message sending; can be enhanced with waveform.
class VoiceRecorderWidget extends StatefulWidget {
  const VoiceRecorderWidget({
    super.key,
    required this.onComplete,
    this.maxSeconds = 120,
  });

  final void Function(Uint8List bytes, int durationSeconds) onComplete;
  final int maxSeconds;

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  final AudioRecorder _rec = AudioRecorder();
  bool _recording = false;
  DateTime? _start;
  Timer? _ticker;
  int _elapsed = 0;
  String? _error;

  Future<bool> _showRecordingConsentDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission'),
        content: const Text(
          'Aroosi needs access to your microphone to record voice messages. Your audio will only be used for the voice messages you send.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _startRecordingIndicators() {
    // Visual feedback for recording state
    setState(() {});
  }

  Future<void> _startRecording() async {
    // Show explicit consent dialog first
    final consent = await _showRecordingConsentDialog();
    if (!consent) return;

    setState(() => _error = null);
    final hasPerm = await _rec.hasPermission();
    if (!hasPerm) {
      try {
        final microphoneStatus = await Permission.microphone.request();
        if (!microphoneStatus.isGranted) {
          setState(() => _error = 'Microphone permission required');
          return;
        }
      } catch (e) {
        setState(() => _error = 'Failed to request microphone permission');
        return;
      }
    }
    
    _elapsed = 0;
    _start = DateTime.now();
    final dir = await Directory.systemTemp.createTemp('voice_rec');
    final outPath =
        '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _rec.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 96000,
        sampleRate: 44100,
      ),
      path: outPath,
    );
    
    // Start visual indicators
    _startRecordingIndicators();
    
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted || !_recording) return;
      setState(() => _elapsed = DateTime.now().difference(_start!).inSeconds);
      if (_elapsed >= widget.maxSeconds) {
        await _stopRecording(send: true);
      }
    });
    setState(() => _recording = true);
  }

  Future<void> _stopRecording({bool send = false}) async {
    if (!_recording) return;
    _ticker?.cancel();
    _ticker = null;
    final path = await _rec.stop();
    setState(() => _recording = false);
    if (send && path != null) {
      try {
        final fileData = await File(path).readAsBytes();
        final dur = _elapsed;
        widget.onComplete(fileData, dur);
      } catch (e) {
        setState(() => _error = 'Failed to read recording');
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _rec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onLongPressStart: (_) => _startRecording(),
          onLongPressEnd: (_) => _stopRecording(send: true),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _recording
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _recording ? Icons.mic : Icons.mic_none,
              size: 36,
              color: _recording
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _recording ? 'Recording... ${_elapsed}s' : 'Hold to record',
          style: theme.textTheme.bodySmall,
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
