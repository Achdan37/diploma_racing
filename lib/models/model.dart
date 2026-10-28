// Model User Autentikasi
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

// Model Motor
class MotorItem {
  final String id;
  String name;
  String plate;

  MotorItem({
    required this.id,
    required this.name,
    this.plate = '',
  });
}

// Model Sample Telemetri
class TelemetrySample {
  final int rpm;
  final double speed;
  final double tps;
  final double afr;
  final double battery;
  final double iat;
  final double ect;
  final double ignition;
  final String baseMap;

  TelemetrySample({
    required this.rpm,
    required this.speed,
    required this.tps,
    required this.afr,
    required this.battery,
    required this.iat,
    required this.ect,
    required this.ignition,
    required this.baseMap,
  });
}

// Model Session Record
class SessionRecord {
  final String id;
  final String motorName;
  final String plate;
  final String mechanic;
  final DateTime date;
  final int durationSeconds;
  final int maxRpm;
  final double avgRpm;
  final double maxSpeed;
  final double avgAfr;
  final double maxEct;
  final double minBattery;
  bool synced;

  SessionRecord({
    required this.id,
    required this.motorName,
    required this.plate,
    required this.mechanic,
    required this.date,
    required this.durationSeconds,
    required this.maxRpm,
    required this.avgRpm,
    required this.maxSpeed,
    required this.avgAfr,
    required this.maxEct,
    required this.minBattery,
    this.synced = false,
  });
}

// Model Akun Mekanik
class MechanicAccount {
  final String id;
  String name;
  String username;
  String password;
  bool active;

  MechanicAccount({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    this.active = true,
  });
}