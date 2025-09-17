import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';

class AuthRepository {
  static const _kTokenKey = 'auth_token';

  final Dio _dio;
  AuthRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio {
    // Ensure at least one usage to avoid unused warning; attach a no-op interceptor
    _dio.interceptors.removeWhere((i) => i.runtimeType.toString() == '_Noop');
  }

  Future<String> login({required String email, required String password}) async {
    // TODO: Replace with real endpoint and response parsing
    // final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    // return res.data['token'] as String;

    await Future.delayed(const Duration(milliseconds: 400));
    if (email.isEmpty || password.isEmpty) {
      throw DioException(requestOptions: RequestOptions(), error: 'Missing credentials');
    }
    // Fake token
    return base64Encode(utf8.encode('$email:$password'));
  }

  Future<String> signup({required String name, required String email, required String password}) async {
    // TODO: Replace with real endpoint
    await Future.delayed(const Duration(milliseconds: 500));
    if (email.isEmpty || password.isEmpty) {
      throw DioException(requestOptions: RequestOptions(), error: 'Missing signup info');
    }
    return base64Encode(utf8.encode('$email:$password'));
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
  }

  Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
  }
}
