import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'config.dart';

import 'package:http/http.dart' as http;

import '../data/app_state.dart';
import 'auth_service.dart';

/// Semua fungsi mengembalikan null jika berhasil, atau pesan error.
class MotorService {
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

      final uri = Uri.parse('${AppConfig.baseUrl}$path');
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
        case 'DELETE':
          res = await http.delete(uri, headers: headers).timeout(timeout);
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

  /// Ambil daftar motor dari server dan ganti isi AppState.motors
  Future<String?> fetchMotors() {
    return _send(
      'GET',
      '/api/motors',
      onOk: (data) {
        final app = AppState.instance;
        app.motors.clear(); // buang data dummy / data lama
        for (final j in (data as List)) {
          app.addMotor(
            MotorItem(
              id: j['id'].toString(),
              name: j['name'] ?? '',
              type: int.tryParse(j['type'].toString()) ?? 0,
            ),
          );
        }
      },
    );
  }

  Future<String?> addMotor({required String name, required int type}) {
    return _send(
      'POST',
      '/api/motors',
      body: {'name': name, 'type': type},
      onOk: (data) {
        AppState.instance.addMotor(
          MotorItem(id: data['id'].toString(), name: name, type: type),
        );
      },
    );
  }

  Future<String?> updateMotor(
    MotorItem motor, {
    required String name,
    required int type,
  }) {
    return _send(
      'PUT',
      '/api/motors/${motor.id}',
      body: {'name': name, 'type': type},
      onOk: (_) {
        motor.name = name;
        motor.type = type;
        AppState.instance.updateMotor(motor);
      },
    );
  }

  Future<String?> deleteMotor(MotorItem motor) {
    return _send(
      'DELETE',
      '/api/motors/${motor.id}',
      onOk: (_) => AppState.instance.deleteMotor(motor.id),
    );
  }
}