import 'package:flutter/material.dart';

import '../data/app_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final app = AppState.instance;

  String selectedMotor = 'Semua';
  String selectedMechanic = 'Semua';
  DateTime? selectedDate;

  bool get isOwner =>
      app.currentRole == 'Owner';

  List<SessionRecord> get filteredSessions {
    return app.sessions.where((session) {
      if (!isOwner &&
          session.mechanic != app.currentName) {
        return false;
      }

      if (selectedMotor != 'Semua' &&
          session.motorName != selectedMotor) {
        return false;
      }

      if (isOwner &&
          selectedMechanic != 'Semua' &&
          session.mechanic != selectedMechanic) {
        return false;
      }

      if (selectedDate != null &&
          (session.date.year != selectedDate!.year ||
              session.date.month != selectedDate!.month ||
              session.date.day != selectedDate!.day)) {
        return false;
      }

      return true;
    }).toList();
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    return '$minutes menit $remaining detik';
  }

  Future<void> deleteSession(
    SessionRecord session,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Riwayat?'),
          content: const Text(
            'Riwayat sesi akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      app.deleteSession(session.id);
    }
  }

  void showDetail(SessionRecord session) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detail Sesi'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _detail('Motor', session.motorName),
                _detail(
                  'Plat',
                  session.plate.isEmpty
                      ? '-'
                      : session.plate,
                ),
                _detail(
                  'Mekanik',
                  session.mechanic,
                ),
                _detail(
                  'Tanggal',
                  formatDate(session.date),
                ),
                _detail(
                  'Durasi',
                  formatDuration(
                    session.durationSeconds,
                  ),
                ),
                _detail(
                  'RPM Maksimum',
                  '${session.maxRpm} RPM',
                ),
                _detail(
                  'RPM Rata-rata',
                  session.avgRpm
                      .toStringAsFixed(0),
                ),
                _detail(
                  'Speed Maksimum',
                  '${session.maxSpeed} km/h',
                ),
                _detail(
                  'AFR Rata-rata',
                  session.avgAfr
                      .toStringAsFixed(1),
                ),
                _detail(
                  'ECT Maksimum',
                  '${session.maxEct} °C',
                ),
                _detail(
                  'Aki Minimum',
                  '${session.minBattery} V',
                ),
                _detail(
                  'Sinkronisasi',
                  session.synced
                      ? 'Tersinkron'
                      : 'Belum sinkron',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _detail(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final sessions = filteredSessions;

        final motorNames = app.sessions
            .map((e) => e.motorName)
            .toSet()
            .toList();

        final mechanicNames = app.sessions
            .map((e) => e.mechanic)
            .toSet()
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isOwner
                  ? 'Rekapitulasi Sesi'
                  : 'Riwayat Sesi',
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedMotor,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Filter kendaraan',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'Semua',
                          child: Text(
                            'Semua kendaraan',
                          ),
                        ),
                        ...motorNames.map(
                          (name) =>
                              DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedMotor =
                                value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    if (isOwner)
                      DropdownButtonFormField<String>(
                        value: selectedMechanic,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Filter mekanik',
                          border:
                              OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'Semua',
                            child: Text(
                              'Semua mekanik',
                            ),
                          ),
                          ...mechanicNames.map(
                            (name) =>
                                DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedMechanic =
                                  value;
                            });
                          }
                        },
                      ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child:
                              OutlinedButton.icon(
                            onPressed: () async {
                              final date =
                                  await showDatePicker(
                                context: context,
                                initialDate:
                                    DateTime.now(),
                                firstDate:
                                    DateTime(2020),
                                lastDate:
                                    DateTime(2100),
                              );

                              if (date != null) {
                                setState(() {
                                  selectedDate =
                                      date;
                                });
                              }
                            },
                            icon: const Icon(
                              Icons.calendar_month,
                            ),
                            label: Text(
                              selectedDate == null
                                  ? 'Pilih tanggal'
                                  : '${selectedDate!.day}-'
                                      '${selectedDate!.month}-'
                                      '${selectedDate!.year}',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              selectedDate = null;
                              selectedMotor =
                                  'Semua';
                              selectedMechanic =
                                  'Semua';
                            });
                          },
                          icon: const Icon(
                            Icons.clear,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Text(
                'Total sesi: ${sessions.length}',
              ),

              const SizedBox(height: 8),

              Expanded(
                child: sessions.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada riwayat sesi.',
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(12),
                        itemCount:
                            sessions.length,
                        itemBuilder:
                            (context, index) {
                          final session =
                              sessions[index];

                          return Card(
                            child: ListTile(
                              leading:
                                  const CircleAvatar(
                                child: Icon(
                                  Icons.history,
                                ),
                              ),
                              title: Text(
                                session.motorName,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${formatDate(session.date)}\n'
                                'RPM max: ${session.maxRpm} • '
                                'Speed max: ${session.maxSpeed} km/h',
                              ),
                              isThreeLine: true,
                              trailing:
                                  PopupMenuButton(
                                itemBuilder:
                                    (context) =>
                                        const [
                                  PopupMenuItem(
                                    value: 'detail',
                                    child:
                                        Text(
                                      'Detail',
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child:
                                        Text(
                                      'Hapus',
                                    ),
                                  ),
                                ],
                                onSelected:
                                    (value) {
                                  if (value ==
                                      'detail') {
                                    showDetail(
                                      session,
                                    );
                                  } else {
                                    deleteSession(
                                      session,
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}