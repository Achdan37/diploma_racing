import 'package:flutter/material.dart';

import '../state/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final app = AppState.instance;

  late TextEditingController nameController;

  final passwordController =
      TextEditingController();

  final confirmController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(
      text: app.currentName,
    );
  }

  void saveProfile() {
    final name =
        nameController.text.trim();

    final password =
        passwordController.text;

    final confirm =
        confirmController.text;

    if (name.isEmpty) {
      showMessage(
        'Nama tidak boleh kosong.',
      );
      return;
    }

    if (password.isNotEmpty &&
        password.length < 6) {
      showMessage(
        'Password minimal 6 karakter.',
      );
      return;
    }

    if (password.isNotEmpty &&
        password != confirm) {
      showMessage(
        'Konfirmasi password tidak sama.',
      );
      return;
    }

    app.updateProfile(name);

    passwordController.clear();
    confirmController.clear();

    showMessage(
      'Profil berhasil diperbarui.',
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    confirmController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 45,
              child: Icon(
                Icons.person,
                size: 48,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              app.currentRole,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              '@${app.currentUsername}',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 28),

            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(
                labelText: 'Nama',
                prefixIcon:
                    Icon(Icons.person),
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
                  passwordController,
              obscureText: true,
              decoration:
                  const InputDecoration(
                labelText:
                    'Password baru',
                prefixIcon:
                    Icon(Icons.lock),
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: confirmController,
              obscureText: true,
              decoration:
                  const InputDecoration(
                labelText:
                    'Konfirmasi password',
                prefixIcon:
                    Icon(Icons.lock_reset),
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saveProfile,
                icon:
                    const Icon(Icons.save),
                label: const Text(
                  'Simpan Perubahan',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}