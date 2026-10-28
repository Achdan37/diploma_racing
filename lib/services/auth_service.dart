import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../models/model.dart'; // Pastikan ini diaktifkan

class AuthService {
  static const _storage = FlutterSecureStorage();

  Future<AuthResult> login({
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/api/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'password': password,
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        await _storage.write(key: 'token', value: data['token']);
        return AuthResult.success(AuthUser.fromJson(data['user']));
      }
      return AuthResult.failure(data['message'] ?? 'Login gagal');
    } on TimeoutException {
      return const AuthResult.failure('Koneksi timeout, coba lagi');
    } on SocketException {
      return const AuthResult.failure('Tidak dapat terhubung ke server');
    } catch (e) {
      return AuthResult.failure('Error: $e');
    }
  }

  Future<String?> getToken() => _storage.read(key: 'token');

  Future<void> logout() => _storage.delete(key: 'token');
}