import 'package:flutter/material.dart';

import '../data/app_state.dart';
import 'auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final app = AppState.instance;
  final _authService = AuthService();

  late TextEditingController usernameController;

  final oldPasswordController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool obscureOld = true;
  bool obscureNew = true;
  bool obscureConfirm = true;
  bool isChangingPassword = false;
  bool isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: app.currentUsername);
  }

  // ---------- Simpan username ----------
  Future<void> saveProfile() async {
    final username = usernameController.text.trim();

    if (username.length < 3) {
      showMessage('Username minimal 3 karakter.');
      return;
    }
    if (!RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(username)) {
      showMessage('Username hanya boleh huruf, angka, titik, dan underscore.');
      return;
    }

    setState(() => isSavingProfile = true);
    final error = await _authService.updateProfile(username: username);
    if (!mounted) return;
    setState(() => isSavingProfile = false);

    if (error != null) {
      showMessage(error);
      return;
    }

    // perbarui tampilan lokal (header ikut berubah)
    setState(() => app.updateProfile(username));
    showMessage('Username berhasil diperbarui.');
  }

  // ---------- Ganti password (wajib password lama) ----------
  Future<void> changePassword() async {
    final oldPassword = oldPasswordController.text;
    final password = passwordController.text;
    final confirm = confirmController.text;

    if (oldPassword.isEmpty) {
      showMessage('Password lama wajib diisi.');
      return;
    }
    if (password.isEmpty) {
      showMessage('Password baru wajib diisi.');
      return;
    }
    if (password.length < 6) {
      showMessage('Password baru minimal 6 karakter.');
      return;
    }
    if (password != confirm) {
      showMessage('Konfirmasi password tidak sama.');
      return;
    }
    if (password == oldPassword) {
      showMessage('Password baru harus berbeda dari password lama.');
      return;
    }

    setState(() => isChangingPassword = true);
    final error = await _authService.changePassword(
      oldPassword: oldPassword,
      newPassword: password,
    );
    if (!mounted) return;
    setState(() => isChangingPassword = false);

    if (error != null) {
      showMessage(error);
      return;
    }

    oldPasswordController.clear();
    passwordController.clear();
    confirmController.clear();
    showMessage('Password berhasil diganti.');
  }

  // ---------- Logout ----------
  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _authService.logout(); // hapus token

    if (!mounted) return;

    // Kembali ke halaman login dan hapus semua halaman sebelumnya
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    oldPasswordController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      enabled: !isChangingPassword,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ----- Header -----
            const CircleAvatar(
              radius: 45,
              child: Icon(Icons.person, size: 48),
            ),
            const SizedBox(height: 12),
            Text(
              '@${app.currentUsername}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                app.currentRole,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ----- Ubah username -----
            TextField(
              controller: usernameController,
              enabled: !isSavingProfile,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.alternate_email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSavingProfile ? null : saveProfile,
                icon: isSavingProfile
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Simpan Perubahan'),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // ----- Ganti password -----
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ganti Password',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Masukkan password lama untuk membuat password baru.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            _passwordField(
              controller: oldPasswordController,
              label: 'Password lama',
              icon: Icons.lock_open,
              obscure: obscureOld,
              onToggle: () => setState(() => obscureOld = !obscureOld),
            ),
            const SizedBox(height: 16),
            _passwordField(
              controller: passwordController,
              label: 'Password baru',
              icon: Icons.lock,
              obscure: obscureNew,
              onToggle: () => setState(() => obscureNew = !obscureNew),
            ),
            const SizedBox(height: 16),
            _passwordField(
              controller: confirmController,
              label: 'Konfirmasi password baru',
              icon: Icons.lock_reset,
              obscure: obscureConfirm,
              onToggle: () => setState(() => obscureConfirm = !obscureConfirm),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isChangingPassword ? null : changePassword,
                icon: isChangingPassword
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.key),
                label: const Text('Ganti Password'),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // ----- Logout -----
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}