import 'dart:async';

import 'package:flutter/material.dart';
import 'package:telemetri_juken5/models/model.dart';

import '../state/app_state.dart';

class TelemetryScreen extends StatefulWidget {
  final bool showAppBar;

  const TelemetryScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<TelemetryScreen> createState() =>
      _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  final app = AppState.instance;

  String? selectedMotorId;
  bool isRecording = false;

  int elapsedSeconds = 0;
  int sampleCount = 0;

  Timer? recordingTimer;

  final List<TelemetrySample> samples = [];

  @override
  void initState() {
    super.initState();

    if (app.motors.isNotEmpty) {
      selectedMotorId = app.motors.first.id;
    }
  }

  MotorItem? get selectedMotor {
    for (final motor in app.motors) {
      if (motor.id == selectedMotorId) {
        return motor;
      }
    }

    return null;
  }

  String get durationText {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void startRecording() {
    if (selectedMotor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih motor terlebih dahulu.'),
        ),
      );
      return;
    }

    setState(() {
      isRecording = true;
      elapsedSeconds = 0;
      sampleCount = 0;
      samples.clear();
    });

    recordingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        final sample = app.telemetry;

        setState(() {
          elapsedSeconds++;
          sampleCount++;
          samples.add(sample);
        });
      },
    );
  }

  void stopRecording() {
    recordingTimer?.cancel();
    recordingTimer = null;

    if (samples.isEmpty || selectedMotor == null) {
      setState(() {
        isRecording = false;
      });

      return;
    }

    final rpmValues = samples.map((e) => e.rpm).toList();
    final speedValues = samples.map((e) => e.speed).toList();
    final afrValues = samples.map((e) => e.afr).toList();
    final ectValues = samples.map((e) => e.ect).toList();
    final batteryValues =
        samples.map((e) => e.battery).toList();

    final motor = selectedMotor!;

    app.addSession(
      SessionRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        motorName: motor.name,
        plate: motor.plate,
        mechanic: app.currentName,
        date: DateTime.now(),
        durationSeconds: elapsedSeconds,
        maxRpm: rpmValues.reduce(
          (a, b) => a > b ? a : b,
        ),
        avgRpm:
            rpmValues.reduce((a, b) => a + b) /
            rpmValues.length,
        maxSpeed: speedValues.reduce(
          (a, b) => a > b ? a : b,
        ),
        avgAfr:
            afrValues.reduce((a, b) => a + b) /
            afrValues.length,
        maxEct: ectValues.reduce(
          (a, b) => a > b ? a : b,
        ),
        minBattery: batteryValues.reduce(
          (a, b) => a < b ? a : b,
        ),
      ),
    );

    setState(() {
      isRecording = false;
    });

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sesi Tersimpan'),
        content: Text(
          'Durasi: $durationText\n'
          'Jumlah sampel: $sampleCount\n\n'
          'Riwayat sesi berhasil dibuat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = app.telemetry;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monitoring Telemetri',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Data telemetri ECU Juken 5',
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 18),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Motor',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (app.motors.isEmpty)
                    const Text('Belum ada motor.')
                  else
                    DropdownButtonFormField<String>(
                      value: selectedMotorId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: app.motors.map((motor) {
                        return DropdownMenuItem(
                          value: motor.id,
                          child: Text(
                            motor.plate.isEmpty
                                ? motor.name
                                : '${motor.name} • ${motor.plate}',
                          ),
                        );
                      }).toList(),
                      onChanged: isRecording
                          ? null
                          : (value) {
                              setState(() {
                                selectedMotorId = value;
                              });
                            },
                    ),
                ],
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: Icon(
                Icons.fiber_manual_record,
                color:
                    isRecording ? Colors.red : Colors.grey,
              ),
              title: Text(
                isRecording
                    ? 'REC • Sedang merekam'
                    : 'Tidak merekam',
              ),
              subtitle: Text(
                'Durasi: $durationText',
              ),
              trailing: Text(
                '$sampleCount sampel',
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Data Telemetri',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _TelemetryCard(
                'RPM',
                '${telemetry.rpm}',
                'RPM',
              ),
              _TelemetryCard(
                'Kecepatan',
                '${telemetry.speed}',
                'km/h',
              ),
              _TelemetryCard(
                'TPS',
                '${telemetry.tps}',
                '%',
              ),
              _TelemetryCard(
                'AFR',
                '${telemetry.afr}',
                '',
              ),
              _TelemetryCard(
                'Tegangan Aki',
                '${telemetry.battery}',
                'V',
              ),
              _TelemetryCard(
                'IAT',
                '${telemetry.iat}',
                '°C',
              ),
              _TelemetryCard(
                'ECT',
                '${telemetry.ect}',
                '°C',
              ),
              _TelemetryCard(
                'Ignition Angle',
                '${telemetry.ignition}',
                '°',
              ),
              _TelemetryCard(
                'Base Map',
                telemetry.baseMap,
                '',
              ),
            ],
          ),

          const SizedBox(height: 16),

          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.memory),
                  title: Text('ESP32'),
                  trailing: Text('Simulasi'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.wifi),
                  title: Text('MQTT'),
                  trailing: Text('Simulasi'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.cloud),
                  title: Text('Cloud'),
                  trailing: Text('Belum tersinkron'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  isRecording
                      ? stopRecording
                      : startRecording,
              icon: Icon(
                isRecording
                    ? Icons.stop
                    : Icons.fiber_manual_record,
              ),
              label: Text(
                isRecording
                    ? 'Stop dan Simpan Sesi'
                    : 'Mulai Rekam',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isRecording ? Colors.red : null,
                foregroundColor:
                    isRecording ? Colors.white : null,
                padding: const EdgeInsets.all(14),
              ),
            ),
          ),
        ],
      ),
    );

    if (!widget.showAppBar) {
      return SafeArea(child: content);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Telemetri'),
      ),
      body: content,
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;

  const _TelemetryCard(
    this.title,
    this.value,
    this.unit,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$value $unit'.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}