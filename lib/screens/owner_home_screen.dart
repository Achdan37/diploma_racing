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

  void addAccount() {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

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
              final username = usernameController.text.trim();
              final password = passwordController.text;

              if (name.isEmpty || username.isEmpty || password.length < 6) {
                setDialogState(
                  () => errorText =
                      'Isi data dengan benar. Password minimal 6 karakter.',
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
              if (mounted) showMessage('Akun berhasil ditambahkan.');
            }

            return AlertDialog(
              title: const Text('Tambah Akun Mekanik'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usernameController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      enabled: !saving,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
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

  void resetPassword(MechanicAccount account) {
    final controller = TextEditingController();

    bool saving = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> reset() async {
              if (controller.text.length < 6) {
                setDialogState(
                  () => errorText = 'Password minimal 6 karakter.',
                );
                return;
              }

              setDialogState(() {
                saving = true;
                errorText = null;
              });

              final error = await _service.resetPassword(
                account,
                newPassword: controller.text,
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
              if (mounted) showMessage('Password berhasil direset.');
            }

            return AlertDialog(
              title: Text('Reset Password ${account.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    enabled: !saving,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password baru',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : reset,
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reset'),
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
                title: Text(account.name),
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => resetPassword(account),
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Reset Password'),
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
            onPressed: addAccount,
            icon: const Icon(Icons.person_add),
            label: const Text('Tambah Akun'),
          ),
          body: _buildBody(accounts),
        );
      },
    );
  }
}