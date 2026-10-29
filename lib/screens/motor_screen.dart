import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_state.dart';
import 'motor_service.dart';

class MotorScreen extends StatefulWidget {
  const MotorScreen({super.key});

  @override
  State<MotorScreen> createState() => _MotorScreenState();
}

class _MotorScreenState extends State<MotorScreen> {
  final _service = MotorService();

  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    loadMotors();
  }

  Future<void> loadMotors() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    final error = await _service.fetchMotors();
    if (!mounted) return;

    setState(() {
      isLoading = false;
      loadError = error;
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Gaya field yang seragam (border selalu terlihat, label tidak terpotong)
  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    final scheme = Theme.of(context).colorScheme;

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: border(scheme.outline),
      enabledBorder: border(scheme.outline),
      disabledBorder: border(scheme.outlineVariant),
      focusedBorder: border(scheme.primary, 2),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 2),
    );
  }

  void showMotorForm({MotorItem? motor}) {
    final nameController = TextEditingController(text: motor?.name ?? '');
    final typeController = TextEditingController(
      text: motor == null ? '' : motor.type.toString(),
    );

    bool saving = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              final name = nameController.text.trim();
              final type = int.tryParse(typeController.text.trim());

              if (name.isEmpty) {
                setDialogState(() => errorText = 'Nama motor wajib diisi');
                return;
              }
              if (type == null || type < 0) {
                setDialogState(
                  () => errorText = 'Tipe motor harus berupa angka',
                );
                return;
              }
              if (type > 65535) {
                setDialogState(
                  () => errorText = 'Tipe motor maksimal 65535',
                );
                return;
              }

              setDialogState(() {
                saving = true;
                errorText = null;
              });

              final error = motor == null
                  ? await _service.addMotor(name: name, type: type)
                  : await _service.updateMotor(
                      motor,
                      name: name,
                      type: type,
                    );

              if (!dialogContext.mounted) return;

              if (error != null) {
                setDialogState(() {
                  saving = false;
                  errorText = error;
                });
                return;
              }

              Navigator.pop(dialogContext);
            }

            return AlertDialog(
              title: Text(motor == null ? 'Tambah Motor' : 'Ubah Motor'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      enabled: !saving,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration(
                        label: 'Nama motor',
                        icon: Icons.motorcycle,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: typeController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (_) {
                        if (!saving) save();
                      },
                      decoration: _fieldDecoration(
                        label: 'Tipe motor',
                        icon: Icons.tag,
                        hint: 'Contoh: 150',
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void deleteMotor(MotorItem motor) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Motor?'),
          content: Text(
            'Motor ${motor.name} akan dihapus. '
            'Riwayat sesi tetap ada.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final error = await _service.deleteMotor(motor);

                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (error != null && mounted) showMessage(error);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(List<MotorItem> motors) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: loadMotors,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (motors.isEmpty) {
      return const Center(child: Text('Belum ada data motor.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: motors.length,
      itemBuilder: (context, index) {
        final motor = motors[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.motorcycle)),
            title: Text(motor.name),
            subtitle: Text('Tipe: ${motor.type}'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Ubah')),
                PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  showMotorForm(motor: motor);
                } else {
                  deleteMotor(motor);
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final motors = AppState.instance.motors;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Data Motor'),
            actions: [
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: isLoading ? null : loadMotors,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showMotorForm(),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Motor'),
          ),
          body: _buildBody(motors),
        );
      },
    );
  }
}