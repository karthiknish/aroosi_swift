import 'package:aroosi_flutter/core/api_client.dart';

enum DeliveryStatus { delivered, read, failed }

class DeliveryReceipt {
  final String id;
  final String messageId;
  final String userId;
  final DeliveryStatus status;
  final DateTime updatedAt;

  const DeliveryReceipt({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.status,
    required this.updatedAt,
  });

  factory DeliveryReceipt.fromJson(Map<String, dynamic> json) {
    return DeliveryReceipt(
      id: json['id']?.toString() ?? '',
      messageId: json['messageId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      status: _parseStatus(json['status']?.toString()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        json['updatedAt'] as int? ?? 0,
      ),
    );
  }

  static DeliveryStatus _parseStatus(String? status) {
    switch (status) {
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'read':
        return DeliveryStatus.read;
      case 'failed':
        return DeliveryStatus.failed;
      default:
        return DeliveryStatus.delivered;
    }
  }

  String get statusText {
    switch (status) {
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.read:
        return 'Read';
      case DeliveryStatus.failed:
        return 'Failed';
    }
  }
}

class DeliveryReceiptService {
  Future<List<DeliveryReceipt>> getDeliveryReceipts(
    String conversationId,
  ) async {
    try {
      final response = await ApiClient.dio.get(
        '/delivery-receipts',
        queryParameters: {'conversationId': conversationId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['deliveryReceipts'] != null) {
          final List<dynamic> receipts = data['deliveryReceipts'];
          return receipts.map((r) => DeliveryReceipt.fromJson(r)).toList();
        }
      }
      return [];
    } catch (e) {
      // Error handling
      return [];
    }
  }

  Future<bool> recordDeliveryReceipt(
    String messageId,
    DeliveryStatus status,
  ) async {
    try {
      final response = await ApiClient.dio.post(
        '/delivery-receipts',
        data: {
          'messageId': messageId,
          'status': status.name,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      // Error handling
      return false;
    }
  }

  Future<bool> markConversationRead(String conversationId) async {
    try {
      final response = await ApiClient.dio.post(
        '/messages/mark-read',
        data: {
          'conversationId': conversationId,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      // Error handling
      return false;
    }
  }
}
