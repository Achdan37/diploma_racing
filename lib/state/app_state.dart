import 'package:flutter/material.dart';
import '../models/model.dart';

class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instance = AppState._();

  String currentRole = 'Mekanik';
  String currentName = 'Achdan';
  String currentUsername = 'mechanic';

  final List<MotorItem> motors = [
    MotorItem(
      id: 'motor-1',
      name: 'Honda CBR 150R',
      plate: 'AE 1234 XX',
    ),
    MotorItem(
      id: 'motor-2',
      name: 'Yamaha R15',
      plate: 'AE 5678 YY',
    ),
  ];

  final List<SessionRecord> sessions = [];

  final List<MechanicAccount> accounts = [
    MechanicAccount(
      id: 'account-1',
      name: 'Mechanic 1',
      username: 'mechanic1',
      password: '123456',
    ),
    MechanicAccount(
      id: 'account-2',
      name: 'Mechanic 2',
      username: 'mechanic2',
      password: '123456',
    ),
  ];

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

  void updateProfile(String name) {
    currentName = name;
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
    final index = sessions.indexWhere(
      (session) => session.id == id,
    );

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
    final index = accounts.indexWhere(
      (account) => account.id == id,
    );

    if (index != -1) {
      accounts[index].active = !accounts[index].active;
      notifyListeners();
    }
  }

  void resetAccountPassword(
    String id,
    String password,
  ) {
    final index = accounts.indexWhere(
      (account) => account.id == id,
    );

    if (index != -1) {
      accounts[index].password = password;
      notifyListeners();
    }
  }
}