import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../data/app_state.dart';
import 'auth_service.dart';

/// Pengelolaan akun mekanik (khusus owner).
/// Semua fungsi mengembalikan null jika berhasil, atau pesan error.
class AccountService {
  final _auth = AuthService();

  Future<String?> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    void Function(dynamic data)? onOk,
  }) async {
    try {
      final token = await _auth.getToken();
      if (token == null) return 'Sesi habis, silakan login ulang';

      final uri = Uri.parse('${AuthService.baseUrl}$path');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final encoded = body == null ? null : jsonEncode(body);
      const timeout = Duration(seconds: 10);

      late http.Response res;
      switch (method) {
        case 'POST':
          res = await http
              .post(uri, headers: headers, body: encoded)
              .timeout(timeout);
          break;
        case 'PUT':
          res = await http
              .put(uri, headers: headers, body: encoded)
              .timeout(timeout);
          break;
        default:
          res = await http.get(uri, headers: headers).timeout(timeout);
      }

      final data = jsonDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        onOk?.call(data);
        return null;
      }
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return 'Permintaan gagal (${res.statusCode})';
    } on TimeoutException {
      return 'Koneksi timeout, coba lagi';
    } on SocketException {
      return 'Tidak dapat terhubung ke server';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Ambil daftar akun mekanik dari server dan ganti isi AppState.accounts
  Future<String?> fetchAccounts() {
    return _send(
      'GET',
      '/api/accounts',
      onOk: (data) {
        final app = AppState.instance;
        app.accounts.clear(); // buang data dummy / data lama
        for (final j in (data as List)) {
          app.addAccount(
            MechanicAccount(
              id: j['id'].toString(),
              name: j['name'] ?? '',
              username: j['username'] ?? '',
              password: '', // password tidak pernah dikirim balik oleh server
              active: j['active'] == true,
            ),
          );
        }
      },
    );
  }

  Future<String?> addAccount({
    required String name,
    required String username,
    required String password,
  }) {
    return _send(
      'POST',
      '/api/accounts',
      body: {'name': name, 'username': username, 'password': password},
      onOk: (data) {
        AppState.instance.addAccount(
          MechanicAccount(
            id: data['id'].toString(),
            name: name,
            username: username,
            password: '',
            active: true,
          ),
        );
      },
    );
  }

  /// Balik status aktif/nonaktif akun
  Future<String?> toggleAccount(MechanicAccount account) {
    return _send(
      'PUT',
      '/api/accounts/${account.id}/active',
      body: {'active': !account.active},
      onOk: (_) => AppState.instance.toggleAccount(account.id),
    );
  }

  Future<String?> resetPassword(
    MechanicAccount account, {
    required String newPassword,
  }) {
    return _send(
      'PUT',
      '/api/accounts/${account.id}/password',
      body: {'password': newPassword},
    );
  }
}