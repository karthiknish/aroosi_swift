import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/profiles/profile_image.dart';
import 'package:aroosi_flutter/features/profiles/profiles_repository.dart';
import 'package:aroosi_flutter/widgets/safe_image_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'base_step.dart';
import 'step_constants.dart';

/// Photos step widget
class StepPhotos extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialData;
  final OnDataUpdate? onDataUpdate;
  final GlobalKey<FormState>? formKey;

  const StepPhotos({
    super.key,
    this.initialData = const {},
    this.onDataUpdate,
    this.formKey,
  });

  @override
  ConsumerState<StepPhotos> createState() => _StepPhotosState();
}

class _StepPhotosState extends ConsumerState<StepPhotos> {
  late final ProfilesRepository _profilesRepository;
  final ImagePicker _picker = ImagePicker();

  List<ProfileImage> _images = const [];
  final List<_PendingUpload> _pendingUploads = <_PendingUpload>[];

  bool _loadingImages = false;

  @override
  void initState() {
    super.initState();
    _profilesRepository = ref.read(profilesRepositoryProvider);
    _loadExistingImages();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadExistingImages() async {
    final userId = _currentUserId();
    if (userId == null) return;

    setState(() => _loadingImages = true);
    try {
      final images = await _profilesRepository.fetchProfileImages(
        userId: userId,
      );
      if (!mounted) return;
      setState(() {
        _images = images;
        _loadingImages = false;
      });
      _syncImageIds();
    } catch (_) {
      if (mounted) {
        setState(() => _loadingImages = false);
      }
    }
  }

  String? _currentUserId() {
    final authState = ref.read(authControllerProvider);
    final profileId = authState.profile?.id;
    if (profileId != null && profileId.isNotEmpty) return profileId;
    final firebaseUser = fb.FirebaseAuth.instance.currentUser;
    return firebaseUser?.uid;
  }

  void _syncImageIds() {
    if (_images.isEmpty) {
      widget.onDataUpdate?.call(StepConstants.profileImageIds, null);
      return;
    }
    final ids = _images
        .map((img) => img.identifier)
        .where((id) => id.isNotEmpty)
        .toList();
    widget.onDataUpdate?.call(StepConstants.profileImageIds, ids);
  }

  Future<void> _pickImages() async {
    // On iOS 14+, pickMultiImage automatically uses PHPickerViewController
    // which is privacy-preserving and doesn't require full photo library access
    if (_images.length + _pendingUploads.length >=
        StepConstants.maximumPhotos) {
      ToastService.instance.info(
        'You can upload up to ${StepConstants.maximumPhotos} photos.',
      );
      return;
    }

    final remaining =
        StepConstants.maximumPhotos - (_images.length + _pendingUploads.length);
    try {
      // Use privacy-preserving photo picker
      // iOS 14+: Uses PHPickerViewController (privacy-preserving)
      // iOS 13-: Uses UIImagePickerController with limited access
      final files = await _picker.pickMultiImage(
        imageQuality: 85,
        // Set preferred image size to minimize data transfer
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (files.isEmpty) return;

      // Apply data minimization - only upload selected photos
      final toUpload = files.take(remaining);
      for (final file in toUpload) {
        await _uploadImage(file);
      }
    } on PlatformException catch (e) {
      ToastService.instance.error(
        'Image picker unavailable: ${e.message ?? 'Permission denied'}',
      );
    } catch (e) {
      ToastService.instance.error('Failed to pick images: $e');
    }
  }

  Future<void> _showPhotoPickerInfo() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.photo_library_outlined, color: Colors.pink, size: 24),
            const SizedBox(width: 8),
            const Text('Photo Privacy'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aroosi respects your privacy. Here\'s how we handle your photos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                'Privacy-Preserving Picker',
                'We use Apple\'s native photo picker that lets you select specific photos without accessing your entire photo library',
                Icons.privacy_tip,
              ),
              _buildPrivacyPoint(
                'Minimal Access',
                'Photos are only accessed when you explicitly select them',
                Icons.security,
              ),
              _buildPrivacyPoint(
                'Quality Optimization',
                'Photos are automatically compressed to reduce data usage while maintaining good quality',
                Icons.high_quality,
              ),
              _buildPrivacyPoint(
                'Secure Storage',
                'Your photos are encrypted and stored securely on our servers',
                Icons.lock,
              ),
              _buildPrivacyPoint(
                'Control & Deletion',
                'You can delete any photo from your profile at any time',
                Icons.delete_outline,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'We never scan or analyze your photos beyond what\'s necessary for profile display.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPoint(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.pink, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadImage(XFile file) async {
    final userId = _currentUserId();
    if (userId == null) {
      ToastService.instance.error('You need to be signed in to upload images.');
      return;
    }

    final pending = _PendingUpload(id: file.path, path: file.path);
    setState(() => _pendingUploads.add(pending));

    try {
      final image = await _profilesRepository.uploadProfileImage(
        file: file,
        userId: userId,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => pending.progress = progress);
        },
      );
      if (!mounted) return;

      setState(() {
        _pendingUploads.remove(pending);
        _images = <ProfileImage>[..._images, image];
      });
      _syncImageIds();
    } catch (e) {
      if (!mounted) return;
      setState(() => _pendingUploads.remove(pending));
      ToastService.instance.error('Failed to upload image: $e');
    }
  }

  Future<void> _deleteImage(ProfileImage image) async {
    final userId = _currentUserId();
    if (userId == null) {
      ToastService.instance.error('Unable to delete image without user id.');
      return;
    }

    try {
      await _profilesRepository.deleteProfileImage(
        userId: userId,
        imageId: image.identifier,
      );
      if (!mounted) return;

      setState(() {
        _images = _images
            .where((img) => img.identifier != image.identifier)
            .toList();
      });
      _syncImageIds();
    } catch (e) {
      ToastService.instance.error('Failed to delete image: $e');
    }
  }

  Future<void> _makePrimary(ProfileImage image) async {
    if (_images.isEmpty) return;

    final userId = _currentUserId();
    if (userId == null) {
      ToastService.instance.error('Unable to reorder images without user id.');
      return;
    }

    final reordered = <ProfileImage>[
      image,
      ..._images.where((img) => img.identifier != image.identifier),
    ];

    setState(() {
      _images = reordered;
    });
    _syncImageIds();

    try {
      await _profilesRepository.reorderProfileImages(
        userId: userId,
        imageIds: reordered.map((img) => img.identifier).toList(),
      );
    } catch (e) {
      ToastService.instance.warning('Unable to update photo order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Profile Photos',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add photos to showcase your personality. Your first photo will be your main picture.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Add Photos Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.photo_camera),
              label: const Text('Add photos'),
              onPressed:
                  _images.length + _pendingUploads.length >=
                      StepConstants.maximumPhotos
                  ? null
                  : _pickImages,
            ),
          ),
          const SizedBox(height: 8),
          // Privacy Info Button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: Icon(Icons.privacy_tip_outlined, size: 18),
              label: Text(
                'How we protect your photo privacy',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              onPressed: _showPhotoPickerInfo,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Photo Count
          Text(
            '${_images.length}/${StepConstants.maximumPhotos} photos uploaded',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Photos Grid
          if (_loadingImages && _images.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (_images.isEmpty &&
              _pendingUploads.isEmpty &&
              !_loadingImages)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No photos added yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add at least one clear photo to build trust and make a great first impression.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ..._pendingUploads.map(
                  (upload) => _buildPendingThumbnail(context, upload),
                ),
                ..._images.map((image) => _buildImageThumbnail(context, image)),
              ],
            ),

          const SizedBox(height: 24),

          // Tips Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                  theme.colorScheme.secondary.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Photo Tips',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...[
                  '• Use clear, recent photos that show your face',
                  '• Include a mix of photos (portrait, full body, activities)',
                  '• Avoid group photos or heavily filtered images',
                  '• First photo becomes your main profile picture',
                ].map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      tip,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Validation note
          if (_images.isEmpty && _pendingUploads.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Note: Adding photos is recommended for better matches',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingThumbnail(BuildContext context, _PendingUpload upload) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: theme.colorScheme.surface,
                child: const Icon(Icons.photo, size: 32),
              ),
            ),
          ),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(upload.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(BuildContext context, ProfileImage image) {
    final theme = Theme.of(context);
    final isPrimary = _images.isNotEmpty && image == _images.first;

    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surfaceContainer,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: image.url != null && image.url!.isNotEmpty
                  ? SafeImageNetwork(
                      imageUrl: image.url!,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: theme.colorScheme.surface,
                        child: const Icon(Icons.photo, size: 32),
                      ),
                    )
                  : Container(
                      color: theme.colorScheme.surface,
                      child: const Icon(Icons.photo, size: 32),
                    ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => _deleteImage(image),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                backgroundColor: isPrimary
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                foregroundColor: isPrimary
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
              ),
              onPressed: isPrimary ? null : () => _makePrimary(image),
              child: Text(
                isPrimary ? 'Primary' : 'Make primary',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingUpload {
  _PendingUpload({required this.id, required this.path}) : progress = 0;

  final String id;
  final String path;
  double progress;
}
