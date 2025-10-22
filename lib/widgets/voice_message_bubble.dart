import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:aroosi_flutter/features/chat/chat_models.dart';
import 'package:aroosi_flutter/core/api_client.dart';

/// Lightweight voice message playback bubble.
/// Fetches secure URL on first play via /voice-messages/{storageId}/url with fallback direct path.
class VoiceMessageBubble extends StatefulWidget {
  const VoiceMessageBubble({
    super.key,
    required this.message,
    this.isMine = false,
  });

  final ChatMessage message;
  final bool isMine;

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final _player = AudioPlayer();
  String? _resolvedUrl;
  bool _loading = false;
  bool _error = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.positionStream.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _player.playerStateStream.listen((st) {
      if (!mounted) return;
      if (st.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  Future<void> _ensureLoaded() async {
    if (_resolvedUrl != null) return;
    final audioUrl = widget.message.audioUrl;
    if (audioUrl == null) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    final dio = ApiClient.dio;
    try {
      String? url;
      try {
        final res = await dio.get('/voice-messages/$audioUrl/url');
        if (res.data is Map && res.data['url'] is String) {
          url = res.data['url'] as String;
        }
      } catch (_) {}
      url ??= '${dio.options.baseUrl}/voice-messages/$audioUrl';
      await _player.setUrl(url);
      _resolvedUrl = url;
    } catch (_) {
      setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    if (_loading) return;
    if (_player.playing) {
      await _player.pause();
      setState(() {});
      return;
    }
    await _ensureLoaded();
    if (_error) return;
    await _player.play();
    setState(() {});
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final durationSecs = widget.message.duration ?? 0;
    final total = Duration(seconds: durationSecs);
    final progress = total.inMilliseconds > 0
        ? _position.inMilliseconds / total.inMilliseconds
        : 0.0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isMine
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _loading
              ? SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _toggle,
                  icon: Icon(
                    _player.playing ? Icons.pause : Icons.play_arrow,
                    size: 24,
                  ),
                ),
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 4),
                Text(_format(total), style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          if (_error) ...[
            const SizedBox(width: 8),
            Icon(Icons.error, color: theme.colorScheme.error, size: 18),
          ],
        ],
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
