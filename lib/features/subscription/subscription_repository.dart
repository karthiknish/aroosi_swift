import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/core/api_client.dart';

import 'subscription_models.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(),
);

class SubscriptionRepository {
  SubscriptionRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<SubscriptionStatus?> fetchStatus() async {
    try {
      final response = await _dio.get('/subscription/status');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return SubscriptionStatus.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchUsage() async {
    try {
      final response = await _dio.get('/subscription/usage');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> trackFeatureUsage(String feature) async {
    try {
      final res = await _dio.post(
        '/subscription/track-usage',
        data: {'feature': feature},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<FeatureAvailabilityResult?> canUseFeature(String feature) async {
    try {
      final res = await _dio.get('/subscription/can-use/$feature');
      if ((res.statusCode ?? 500) >= 200 && (res.statusCode ?? 500) < 300) {
        final data = res.data;
        if (data is Map<String, dynamic>) {
          if (data['canUse'] != null) {
            return FeatureAvailabilityResult.fromJson(data);
          }
          final nested = data['data'];
          if (nested is Map<String, dynamic> && nested['canUse'] != null) {
            return FeatureAvailabilityResult.fromJson(nested);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> validatePurchase({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? receiptData,
  }) async {
    try {
      final payload = <String, dynamic>{
        'platform': platform,
        'productId': productId,
        'purchaseToken': platform == 'ios' ? receiptData : purchaseToken,
      };
      if (receiptData != null) {
        payload['receiptData'] = receiptData;
      }
      final res = await _dio.post('/subscription/purchase', data: payload);
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data['success'] == true) {
          return true;
        }
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.data is Map &&
          (e.response?.data as Map)['success'] == true) {
        return true;
      }
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final res = await _dio.post('/subscription/restore');
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data['success'] == true) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<bool> cancelSubscription() async {
    try {
      final res = await _dio.post('/subscription/cancel');
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data['success'] == true) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }
}
