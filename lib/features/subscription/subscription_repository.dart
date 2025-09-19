import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/core/api_client.dart';
import 'package:aroosi_flutter/utils/debug_logger.dart';

import 'subscription_models.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(),
);

class SubscriptionRepository {
  SubscriptionRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<SubscriptionStatus?> fetchStatus({int maxRetries = 3}) async {
    logApi('💳 Fetching subscription status | Max retries: $maxRetries');
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio.get('/subscription/status');
        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          final status = SubscriptionStatus.fromJson(
            response.data as Map<String, dynamic>,
          );
          logApi('✅ Subscription status fetched | Plan: ${status.plan} | Active: ${status.isActive} | Attempt: $attempt');
          return status;
        }
        
        if (attempt == maxRetries) {
          logApi('❌ Subscription status fetch failed after $maxRetries attempts | Status: ${response.statusCode}');
          return null;
        }
        
        logApi('⚠️ Subscription status fetch attempt $attempt failed, retrying...');
        await Future.delayed(const Duration(seconds: 2));
        
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          logApi('🔐 Subscription status fetch failed: Unauthorized (401)');
          return null;
        }
        
        if (attempt == maxRetries) {
          logApi('❌ Subscription status fetch failed after $maxRetries attempts | Error: ${e.message}');
          return null;
        }
        
        logApi('⚠️ Subscription status fetch attempt $attempt failed with error, retrying... | Error: ${e.message}');
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        if (attempt == maxRetries) {
          logApi('❌ Subscription status fetch failed after $maxRetries attempts | Unexpected error: ${e.toString()}');
          return null;
        }
        
        logApi('⚠️ Subscription status fetch attempt $attempt failed with unexpected error, retrying... | Error: ${e.toString()}');
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    
    return null;
  }

  Future<Map<String, dynamic>?> fetchUsage({int maxRetries = 2}) async {
    logApi('💳 Fetching subscription usage | Max retries: $maxRetries');
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio.get('/subscription/usage');
        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          logApi('✅ Subscription usage fetched | Attempt: $attempt');
          return response.data as Map<String, dynamic>;
        }
        
        if (attempt == maxRetries) {
          logApi('❌ Subscription usage fetch failed after $maxRetries attempts | Status: ${response.statusCode}');
          return null;
        }
        
        await Future.delayed(const Duration(seconds: 1));
        
      } catch (e) {
        if (attempt == maxRetries) {
          logApi('❌ Subscription usage fetch failed after $maxRetries attempts | Error: ${e.toString()}');
          return null;
        }
        
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    
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

  Future<FeatureAvailabilityResult?> canUseFeature(String feature, {int maxRetries = 2}) async {
    logApi('💳 Checking feature availability | Feature: $feature | Max retries: $maxRetries');
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final res = await _dio.get('/subscription/can-use/$feature');
        if ((res.statusCode ?? 500) >= 200 && (res.statusCode ?? 500) < 300) {
          final data = res.data;
          if (data is Map<String, dynamic>) {
            if (data['canUse'] != null) {
              logApi('✅ Feature availability checked | Feature: $feature | Can use: ${data['canUse']} | Attempt: $attempt');
              return FeatureAvailabilityResult.fromJson(data);
            }
            final nested = data['data'];
            if (nested is Map<String, dynamic> && nested['canUse'] != null) {
              logApi('✅ Feature availability checked | Feature: $feature | Can use: ${nested['canUse']} | Attempt: $attempt');
              return FeatureAvailabilityResult.fromJson(nested);
            }
          }
        }
        
        if (attempt == maxRetries) {
          logApi('❌ Feature availability check failed after $maxRetries attempts | Feature: $feature | Status: ${res.statusCode}');
          return null;
        }
        
        await Future.delayed(const Duration(seconds: 1));
        
      } catch (e) {
        if (attempt == maxRetries) {
          logApi('❌ Feature availability check failed after $maxRetries attempts | Feature: $feature | Error: ${e.toString()}');
          return null;
        }
        
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    
    return null;
  }

  Future<bool> validatePurchase({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? receiptData,
  }) async {
    logApi('💳 Validating purchase | Platform: $platform | Product: $productId');
    
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
          logApi('✅ Purchase validation successful | Product: $productId');
          return true;
        }
      }
      logApi('❌ Purchase validation failed | Status: ${res.statusCode} | Response: ${res.data}');
      return false;
    } on DioException catch (e) {
      if (e.response?.data is Map &&
          (e.response?.data as Map)['success'] == true) {
        logApi('✅ Purchase validation successful (via error response) | Product: $productId');
        return true;
      }
      logApi('❌ Purchase validation failed | Error: ${e.message}');
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

  Future<bool> refreshSubscription() async {
    try {
      final res = await _dio.post('/subscription/refresh');
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data['success'] == true) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>?> getFeatures() async {
    try {
      final res = await _dio.get('/subscription/features');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getUsageHistory() async {
    try {
      final res = await _dio.get('/subscription/usage-history');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getBoostQuota() async {
    try {
      final res = await _dio.get('/subscription/quota/boosts');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getVoiceQuota() async {
    try {
      final res = await _dio.get('/subscription/quota/voice');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> updateSubscriptionStatus(Map<String, dynamic> statusData) async {
    try {
      final res = await _dio.put('/subscription/status', data: statusData);
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data['success'] == true) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<bool> validatePurchaseWithRetry({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? receiptData,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    logApi('💳 Validating purchase with retry | Platform: $platform | Product: $productId | Max retries: $maxRetries');
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
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
            logApi('✅ Purchase validation successful | Product: $productId | Attempt: $attempt');
            return true;
          }
        }
        
        if (attempt == maxRetries) {
          logApi('❌ Purchase validation failed after $maxRetries attempts | Product: $productId');
          return false;
        }
        
        logApi('⚠️ Purchase validation attempt $attempt failed, retrying in ${retryDelay.inSeconds}s | Product: $productId');
        await Future.delayed(retryDelay);
        
      } on DioException catch (e) {
        if (e.response?.data is Map &&
            (e.response?.data as Map)['success'] == true) {
          logApi('✅ Purchase validation successful (via error response) | Product: $productId | Attempt: $attempt');
          return true;
        }
        
        if (attempt == maxRetries) {
          logApi('❌ Purchase validation failed after $maxRetries attempts | Error: ${e.message} | Product: $productId');
          return false;
        }
        
        logApi('⚠️ Purchase validation attempt $attempt failed with error, retrying in ${retryDelay.inSeconds}s | Error: ${e.message} | Product: $productId');
        await Future.delayed(retryDelay);
      }
    }
    
    return false;
  }
}
