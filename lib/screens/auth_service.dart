// pubspec.yaml -> dependencies:
//   http: ^1.2.0
//   flutter_secure_storage: ^9.2.2
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthUser {
  final int id;
  final String name;
  final String username;
  final String role; // 'mechanic' | 'owner'

  AuthUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id: j['id'],
    name: j['name'] ?? '',
    username: j['username'],
    role: j['role'],
  );
}

class AuthResult {
  final AuthUser? user;
  final String? error;
  const AuthResult.success(this.user) : error = null;
  const AuthResult.failure(this.error) : user = null;
  bool get ok => user != null;
}

class AuthService {
  // Emulator Android: 10.0.2.2 | HP asli: IP laptop di WiFi yang sama, mis. http://192.168.1.10:3000
  // static const String baseUrl = 'http://localhost:3000';
  // static const String baseUrl = 'http://192.168.1.10:3000';
  static const String baseUrl = 'http://127.0.0.1:3000';

  static const _storage = FlutterSecureStorage();

  /// Login hanya butuh username + password. Role ditentukan oleh server.
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
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

  /// Ganti password. Mengembalikan null jika berhasil, atau pesan error.
  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return 'Sesi habis, silakan login ulang';

      final res = await http
          .put(
            Uri.parse('$baseUrl/api/change-password'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'oldPassword': oldPassword,
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) return null;
      return data['message'] ?? 'Gagal mengganti password';
    } on TimeoutException {
      return 'Koneksi timeout, coba lagi';
    } on SocketException {
      return 'Tidak dapat terhubung ke server';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Simpan nama ke database. Mengembalikan null jika berhasil, atau pesan error.
  Future<String?> updateProfile({required String username}) async {
    try {
      final token = await getToken();
      if (token == null) return 'Sesi habis, silakan login ulang';

      final res = await http
          .put(
            Uri.parse('$baseUrl/api/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'username': username}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) return null;
      return data['message'] ?? 'Gagal memperbarui profil';
    } on TimeoutException {
      return 'Koneksi timeout, coba lagi';
    } on SocketException {
      return 'Tidak dapat terhubung ke server';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> getToken() => _storage.read(key: 'token');

  Future<void> logout() => _storage.delete(key: 'token');
}
