import 'package:flutter/material.dart';

class MotorItem {
  final String id;
  String name;
  String plate; // tidak dipakai di tabel motors, dipertahankan agar layar lain tidak error
  int type; // kolom "type" di tabel motors

  MotorItem({
    required this.id,
    required this.name,
    this.plate = '',
    this.type = 0,
  });
}

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

class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instance = AppState._();

  String currentRole = 'Mekanik';
  String currentName = 'Achdan';
  String currentUsername = 'mechanic';

  // Diisi dari server (lihat MotorService.fetchMotors)
  final List<MotorItem> motors = [];

  final List<SessionRecord> sessions = [];

  // Diisi dari server (lihat AccountService.fetchAccounts)
  final List<MechanicAccount> accounts = [];

  TelemetrySample get telemetry {
    return TelemetrySample(
      rpm: 4250,
      speed: 72,
      tps: 35,
      afr: 13.2,
      battery: 13.8,
      iat: 32,
      ect: 82,
      ignition: 18,
      baseMap: 'Map 1',
    );
  }

  void login({
    required String role,
    required String name,
    required String username,
  }) {
    currentRole = role;
    currentName = name;
    currentUsername = username;
    notifyListeners();
  }

  void updateProfile(String username) {
    currentUsername = username;
    notifyListeners();
  }

  void addMotor(MotorItem motor) {
    motors.add(motor);
    notifyListeners();
  }

  void updateMotor(MotorItem motor) {
    notifyListeners();
  }

  void deleteMotor(String id) {
    motors.removeWhere((motor) => motor.id == id);
    notifyListeners();
  }

  void addSession(SessionRecord session) {
    sessions.insert(0, session);
    notifyListeners();
  }

  void deleteSession(String id) {
    sessions.removeWhere((session) => session.id == id);
    notifyListeners();
  }

  void markSessionSynced(String id) {
    final index = sessions.indexWhere((session) => session.id == id);

    if (index != -1) {
      sessions[index].synced = true;
      notifyListeners();
    }
  }

  void addAccount(MechanicAccount account) {
    accounts.add(account);
    notifyListeners();
  }

  void toggleAccount(String id) {
    final index = accounts.indexWhere((account) => account.id == id);

    if (index != -1) {
      accounts[index].active = !accounts[index].active;
      notifyListeners();
    }
  }

  void resetAccountPassword(String id, String password) {
    final index = accounts.indexWhere((account) => account.id == id);

    if (index != -1) {
      accounts[index].password = password;
      notifyListeners();
    }
  }
}
