import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../data/app_state.dart';
import 'auth_service.dart';

/// Semua fungsi mengembalikan null jika berhasil, atau pesan error.
class AccountService {
  final _auth = AuthService();
  final _app = AppState.instance;

  Future<String?> _call(
    String method,
    String path, {
    Map<String, dynamic>? body,
    void Function(dynamic data)? onOk,
    String fallbackError = 'Terjadi kesalahan',
  }) async {
    try {
      final token = await _auth.getToken();
      if (token == null) return 'Sesi habis, silakan login ulang';

      final uri = Uri.parse('${_auth.baseUrl}$path');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final Future<http.Response> req = switch (method) {
        'GET' => http.get(uri, headers: headers),
        'POST' => http.post(uri, headers: headers, body: jsonEncode(body)),
        'PUT' => http.put(uri, headers: headers, body: jsonEncode(body)),
        'DELETE' => http.delete(uri, headers: headers),
        _ => throw ArgumentError('Method tidak didukung: $method'),
      };

      final res = await req.timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        onOk?.call(data);
        return null;
      }
      return (data is Map ? data['message'] : null) ?? fallbackError;
    } on TimeoutException {
      return 'Koneksi timeout, coba lagi';
    } on SocketException {
      return 'Tidak dapat terhubung ke server';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// READ: ambil semua akun mekanik dari server.
  Future<String?> fetchAccounts() {
    return _call(
      'GET',
      '/api/accounts',
      fallbackError: 'Gagal memuat akun',
      onOk: (data) {
        final list = (data as List)
            .map(
              (r) => MechanicAccount(
                id: r['id'].toString(),
                name: r['name'] ?? '',
                username: r['username'] ?? '',
                password: '',
                active: r['active'] == true,
              ),
            )
            .toList();
        _app.setAccounts(list);
      },
    );
  }

  /// CREATE
  Future<String?> addAccount({
    required String name,
    required String username,
    required String password,
  }) {
    return _call(
      'POST',
      '/api/accounts',
      body: {'name': name, 'username': username, 'password': password},
      fallbackError: 'Gagal menambah akun',
      onOk: (data) {
        _app.addAccount(
          MechanicAccount(
            id: data['id'].toString(),
            name: data['name'] ?? name,
            username: data['username'] ?? username,
            password: '',
            active: true,
          ),
        );
      },
    );
  }

  /// DELETE
  Future<String?> deleteAccount(MechanicAccount account) {
    return _call(
      'DELETE',
      '/api/accounts/${account.id}',
      fallbackError: 'Gagal menghapus akun',
      onOk: (_) => _app.deleteAccount(account.id),
    );
  }

  /// Aktifkan / nonaktifkan akun
  Future<String?> toggleAccount(MechanicAccount account) {
    return _call(
      'PUT',
      '/api/accounts/${account.id}/active',
      body: {'active': !account.active},
      fallbackError: 'Gagal mengubah status akun',
      onOk: (_) => _app.toggleAccount(account.id),
    );
  }

  /// Reset password akun mekanik
  Future<String?> resetPassword(
    MechanicAccount account, {
    required String newPassword,
  }) {
    return _call(
      'PUT',
      '/api/accounts/${account.id}/password',
      body: {'password': newPassword},
      fallbackError: 'Gagal mereset password',
    );
  }
}