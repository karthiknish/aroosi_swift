import 'package:equatable/equatable.dart';

/// Represents an uploaded profile image returned by the backend.
class ProfileImage extends Equatable {
  const ProfileImage({
    required this.id,
    required this.storageId,
    this.url,
    this.isPrimary = false,
    this.thumbnailUrl,
  });

  final String id;
  final String storageId;
  final String? url;
  final String? thumbnailUrl;
  final bool isPrimary;

  /// Returns the best identifier to send back to the API when referencing
  /// this image. Mirrors aroosi-mobile by preferring the document id, then
  /// storage id.
  String get identifier => id.isNotEmpty ? id : storageId;

  ProfileImage copyWith({
    String? id,
    String? storageId,
    String? url,
    String? thumbnailUrl,
    bool? isPrimary,
  }) => ProfileImage(
        id: id ?? this.id,
        storageId: storageId ?? this.storageId,
        url: url ?? this.url,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        isPrimary: isPrimary ?? this.isPrimary,
      );

  factory ProfileImage.fromJson(Map<String, dynamic> json) {
    String readId() {
      final id = json['id'] ?? json['_id'] ?? json['imageId'] ?? json['storageId'];
      return id?.toString() ?? '';
    }

    String readStorageId() {
      final value = json['storageId'] ?? json['id'] ?? json['_id'];
      return value?.toString() ?? '';
    }

    return ProfileImage(
      id: readId(),
      storageId: readStorageId(),
      url: json['url']?.toString() ?? json['imageUrl']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString() ??
          json['thumbUrl']?.toString(),
      isPrimary: json['isPrimary'] == true || json['primary'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'storageId': storageId,
        if (url != null) 'url': url,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        'isPrimary': isPrimary,
      };

  @override
  List<Object?> get props => [id, storageId, url, thumbnailUrl, isPrimary];
}
