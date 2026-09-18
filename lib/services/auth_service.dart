import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class ApiUser {
  final String id;
  final String email;
  final bool isAdmin;

  const ApiUser({required this.id, required this.email, required this.isAdmin});

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: json['id'].toString(),
      email: json['email'] as String,
      isAdmin: json['is_admin'] == true,
    );
  }
}

class AuthService {
  static const _tokenKey = 'quickmart_api_token';
  static final ValueNotifier<ApiUser?> currentUser = ValueNotifier<ApiUser?>(null);
  static String? _token;

  static String? get token => _token;

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _token = preferences.getString(_tokenKey);
    if (_token == null) return;

    try {
      final data = await ApiClient.get('/api/auth/me') as Map<String, dynamic>;
      currentUser.value = ApiUser.fromJson(data);
    } catch (_) {
      await signOut();
    }
  }

  static Future<void> signUp(String email, String password) async {
    final data = await ApiClient.post('/api/auth/register', {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    await _applyAuthResponse(data);
  }

  static Future<void> signIn(String email, String password) async {
    final data = await ApiClient.post('/api/auth/login', {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    await _applyAuthResponse(data);
  }

  static Future<void> _applyAuthResponse(Map<String, dynamic> data) async {
    _token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    currentUser.value = ApiUser.fromJson(user);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, _token!);
  }

  static Future<void> signOut() async {
    _token = null;
    currentUser.value = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
  }

  static Future<bool> isAdmin() async => currentUser.value?.isAdmin == true;
}
