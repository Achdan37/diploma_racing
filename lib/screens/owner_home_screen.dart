import 'package:flutter/material.dart';

import '../data/app_state.dart';
import 'account_service.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  int selectedIndex = 0;

  final pages = const [HistoryScreen(), ManageAccountScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: 'Akun',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class ManageAccountScreen extends StatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  final _service = AccountService();

  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    final error = await _service.fetchAccounts();
    if (!mounted) return;

    setState(() {
      isLoading = false;
      loadError = error;
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Gaya field yang seragam (border selalu terlihat)
  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
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
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
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

  Widget _errorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _savingIndicator() {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  // ---------- Tambah akun ----------
  void showAccountForm() {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    bool saving = false;
    bool obscure = true;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              final name = nameController.text.trim();
              final username = usernameController.text.trim();
              final password = passwordController.text;

              if (name.isEmpty || username.isEmpty) {
                setDialogState(
                  () => errorText = 'Nama dan username wajib diisi.',
                );
                return;
              }
              if (name.length > 45) {
                setDialogState(() => errorText = 'Nama maksimal 45 karakter.');
                return;
              }
              if (username.length > 50) {
                setDialogState(
                  () => errorText = 'Username maksimal 50 karakter.',
                );
                return;
              }
              if (password.length < 6) {
                setDialogState(
                  () => errorText = 'Password minimal 6 karakter.',
                );
                return;
              }

              setDialogState(() {
                saving = true;
                errorText = null;
              });

              final error = await _service.addAccount(
                name: name,
                username: username,
                password: password,
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
              if (mounted) {
                showMessage('Akun berhasil ditambahkan.');
              }
            }

            return AlertDialog(
              title: const Text('Tambah Akun Mekanik'),
              content: SizedBox(
                width: 360,
                child: SingleChildScrollView(
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
                          label: 'Nama',
                          icon: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: usernameController,
                        enabled: !saving,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(
                          label: 'Username',
                          icon: Icons.alternate_email,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        enabled: !saving,
                        obscureText: obscure,
                        decoration: _fieldDecoration(
                          label: 'Password',
                          icon: Icons.lock,
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setDialogState(() => obscure = !obscure),
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      if (errorText != null) _errorText(errorText!),
                    ],
                  ),
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
                  child: saving ? _savingIndicator() : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- Hapus ----------
  void deleteAccount(MechanicAccount account) {
    bool deleting = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> confirmDelete() async {
              setDialogState(() {
                deleting = true;
                errorText = null;
              });

              final error = await _service.deleteAccount(account);

              if (!dialogContext.mounted) return;

              if (error != null) {
                setDialogState(() {
                  deleting = false;
                  errorText = error;
                });
                return;
              }

              Navigator.pop(dialogContext);
              if (mounted) showMessage('Akun berhasil dihapus.');
            }

            return AlertDialog(
              title: const Text('Hapus Akun?'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akun ${_displayName(account)} (@${account.username}) '
                      'akan dihapus permanen beserta seluruh riwayat sesinya. '
                      'Motor yang ditambahkan akun ini tetap ada. '
                      'Tindakan ini tidak bisa dibatalkan.\n\n'
                      'Kalau hanya ingin mencabut akses sementara, '
                      'gunakan saklar Status Akun untuk menonaktifkan.',
                    ),
                    if (errorText != null) _errorText(errorText!),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: deleting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: deleting ? null : confirmDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: deleting ? _savingIndicator() : const Text('Hapus'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> toggleAccount(MechanicAccount account) async {
    final error = await _service.toggleAccount(account);
    if (error != null && mounted) showMessage(error);
  }

  // Kalau nama kosong di database, tampilkan username
  String _displayName(MechanicAccount account) {
    return account.name.trim().isEmpty ? account.username : account.name;
  }

  Widget _buildBody(List<MechanicAccount> accounts) {
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
                onPressed: loadAccounts,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (accounts.isEmpty) {
      return const Center(child: Text('Belum ada akun mekanik.'));
    }

    final errorColor = Theme.of(context).colorScheme.error;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    account.active ? Icons.person : Icons.person_off,
                  ),
                ),
                title: Text(_displayName(account)),
                subtitle: Text(
                  '@${account.username}\n'
                  '${account.active ? 'Aktif' : 'Nonaktif'}',
                ),
                isThreeLine: true,
              ),
              SwitchListTile(
                title: const Text('Status Akun'),
                value: account.active,
                onChanged: (_) => toggleAccount(account),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => deleteAccount(account),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus Akun'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: errorColor,
                      side: BorderSide(color: errorColor),
                    ),
                  ),
                ),
              ),
            ],
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
        final accounts = AppState.instance.accounts;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Kelola Akun Mekanik'),
            actions: [
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: isLoading ? null : loadAccounts,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showAccountForm(),
            icon: const Icon(Icons.person_add),
            label: const Text('Tambah Akun'),
          ),
          body: _buildBody(accounts),
        );
      },
    );
  }
}