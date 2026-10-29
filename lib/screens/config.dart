import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Ini akan otomatis membaca dari file .env
  // Jika .env tidak ditemukan, akan pakai 'http://localhost:3000' sebagai cadangan
  static String get baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:3000';
}