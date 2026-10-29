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

  late TextEditingController nameController;
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
    nameController = TextEditingController(text: app.currentName);
    usernameController = TextEditingController(text: app.currentUsername);
  }

  // ---------- Simpan profil (nama & username) ----------
  Future<void> saveProfile() async {
    final name = nameController.text.trim();
    final username = usernameController.text.trim();

    if (name.isEmpty) {
      showMessage('Nama wajib diisi.');
      return;
    }
    if (name.length > 45) {
      showMessage('Nama maksimal 45 karakter.');
      return;
    }
    if (username.length < 3) {
      showMessage('Username minimal 3 karakter.');
      return;
    }
    if (!RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(username)) {
      showMessage('Username hanya boleh huruf, angka, titik, dan underscore.');
      return;
    }

    final nameChanged = name != app.currentName;
    final usernameChanged = username != app.currentUsername;

    if (!nameChanged && !usernameChanged) {
      showMessage('Belum ada perubahan.');
      return;
    }

    setState(() => isSavingProfile = true);
    final error = await _authService.updateProfile(
      name: nameChanged ? name : null,
      username: usernameChanged ? username : null,
    );
    if (!mounted) return;
    setState(() => isSavingProfile = false);

    if (error != null) {
      showMessage(error);
      return;
    }

    if (usernameChanged) {
      await _logoutAfterChange(
        'Profil berhasil diperbarui. Silakan login dengan username baru.',
      );
      return;
    }

    // Hanya nama yang berubah: tetap login, perbarui judul di atas avatar
    app.updateProfile(name: name);
    setState(() {});
    showMessage('Nama berhasil diperbarui.');
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
    await _logoutAfterChange(
      'Password berhasil diganti. Silakan login dengan password baru.',
    );
  }

  // ---------- Logout otomatis setelah ganti username / password ----------
  Future<void> _logoutAfterChange(String message) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await _authService.logout(); // hapus token

    if (!mounted) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    messenger.showSnackBar(SnackBar(content: Text(message)));
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
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

@override
void dispose() {
  nameController.dispose();
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
            const CircleAvatar(radius: 45, child: Icon(Icons.person, size: 48)),
            const SizedBox(height: 12),
            Text(
              app.currentName.trim().isEmpty
                  ? app.currentUsername
                  : app.currentName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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

            // ----- Ubah profil -----
            TextField(
              controller: nameController,
              enabled: !isSavingProfile,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              enabled: !isSavingProfile,
              decoration: const InputDecoration(
                labelText: 'Username',
                helperText: 'Mengubah username akan membuat Anda logout otomatis.',
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
