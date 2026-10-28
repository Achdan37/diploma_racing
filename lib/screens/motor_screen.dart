import 'package:flutter/material.dart';
import 'package:telemetri_juken5/models/model.dart';

import '../state/app_state.dart';

class MotorScreen extends StatelessWidget {
  const MotorScreen({super.key});

  void showMotorForm(
    BuildContext context, {
    MotorItem? motor,
  }) {
    final nameController =
        TextEditingController(
      text: motor?.name ?? '',
    );

    final plateController =
        TextEditingController(
      text: motor?.plate ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            motor == null
                ? 'Tambah Motor'
                : 'Ubah Motor',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(
                  labelText: 'Nama motor',
                  border:
                      OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: plateController,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Plat nomor (opsional)',
                  border:
                      OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final name =
                    nameController.text.trim();

                if (name.isEmpty) return;

                if (motor == null) {
                  AppState.instance.addMotor(
                    MotorItem(
                      id: DateTime.now()
                          .microsecondsSinceEpoch
                          .toString(),
                      name: name,
                      plate: plateController
                          .text
                          .trim(),
                    ),
                  );
                } else {
                  motor.name = name;
                  motor.plate =
                      plateController.text.trim();

                  AppState.instance
                      .updateMotor(motor);
                }

                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void deleteMotor(
    BuildContext context,
    MotorItem motor,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Hapus Motor?',
          ),
          content: Text(
            'Motor ${motor.name} akan dihapus. '
            'Riwayat sesi tetap ada.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                AppState.instance
                    .deleteMotor(motor.id);

                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final motors =
            AppState.instance.motors;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Data Motor',
            ),
          ),
          floatingActionButton:
              FloatingActionButton.extended(
            onPressed: () =>
                showMotorForm(context),
            icon: const Icon(Icons.add),
            label: const Text(
              'Tambah Motor',
            ),
          ),
          body: motors.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada data motor.',
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.only(
                    bottom: 90,
                  ),
                  itemCount: motors.length,
                  itemBuilder:
                      (context, index) {
                    final motor =
                        motors[index];

                    return Card(
                      margin:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons.motorcycle,
                          ),
                        ),
                        title: Text(
                          motor.name,
                        ),
                        subtitle: Text(
                          motor.plate.isEmpty
                              ? 'Plat belum diisi'
                              : motor.plate,
                        ),
                        trailing:
                            PopupMenuButton(
                          itemBuilder:
                              (context) =>
                                  const [
                            PopupMenuItem(
                              value: 'edit',
                              child:
                                  Text(
                                'Ubah',
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
                                'edit') {
                              showMotorForm(
                                context,
                                motor:
                                    motor,
                              );
                            } else {
                              deleteMotor(
                                context,
                                motor,
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}