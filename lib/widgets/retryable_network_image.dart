import 'package:flutter/material.dart';

/// A network image widget that handles expired Firebase Storage URLs gracefully
class RetryableNetworkImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int maxRetries;
  final Duration retryDelay;

  const RetryableNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });

  @override
  State<RetryableNetworkImage> createState() => _RetryableNetworkImageState();
}

class _RetryableNetworkImageState extends State<RetryableNetworkImage> {
  int _retryCount = 0;
  bool _isLoading = true;
  bool _hasError = false;
  late ImageProvider _imageProvider;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(RetryableNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _retryCount = 0;
      _isLoading = true;
      _hasError = false;
      _loadImage();
    }
  }

  void _loadImage() {
    _imageProvider = NetworkImage(widget.url);

    // Preload the image to detect errors early
    final ImageStream stream = _imageProvider.resolve(ImageConfiguration.empty);
    stream.addListener(
      ImageStreamListener(
        (info, synchronousCall) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = false;
            });
          }
        },
        onError: (exception, stackTrace) {
          _handleImageError(exception);
        },
      ),
    );
  }

  void _handleImageError(dynamic exception) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }

    // Check if it's a network error that might be due to expired URL
    if (_retryCount < widget.maxRetries && _isNetworkError(exception)) {
      _retryCount++;
      Future.delayed(widget.retryDelay * _retryCount, () {
        if (mounted) {
          setState(() {
            _isLoading = true;
            _hasError = false;
          });
          _loadImage();
        }
      });
    }
  }

  bool _isNetworkError(dynamic exception) {
    // Check for common network errors that might indicate expired URLs
    if (exception is NetworkImageLoadException) {
      return true;
    }

    final errorString = exception.toString().toLowerCase();
    return errorString.contains('404') ||
        errorString.contains('403') ||
        errorString.contains('400') ||
        errorString.contains('expired') ||
        errorString.contains('invalid') ||
        errorString.contains('unauthorized');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          Container(
            color: Colors.grey[200],
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
    }

    if (_hasError) {
      return widget.errorWidget ??
          Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
          );
    }

    return Image(
      image: _imageProvider,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        _handleImageError(error);
        return widget.errorWidget ??
            Container(
              color: Colors.grey[200],
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 40,
              ),
            );
      },
    );
  }

  @override
  void dispose() {
    // Clear the image cache for this URL to prevent memory leaks
    _imageProvider.evict();
    super.dispose();
  }
}
