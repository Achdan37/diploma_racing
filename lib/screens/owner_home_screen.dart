import 'package:flutter/material.dart';

import '../data/app_state.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() =>
      _OwnerHomeScreenState();
}

class _OwnerHomeScreenState
    extends State<OwnerHomeScreen> {
  int selectedIndex = 0;

  final pages = const [
    HistoryScreen(),
    ManageAccountScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: selectedIndex,
        type:
            BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Rekap',
          ),
          BottomNavigationBarItem(
            icon:
                Icon(Icons.manage_accounts),
            label: 'Akun',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class ManageAccountScreen
    extends StatelessWidget {
  const ManageAccountScreen({
    super.key,
  });

  void showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void addAccount(
    BuildContext context,
  ) {
    final nameController =
        TextEditingController();

    final usernameController =
        TextEditingController();

    final passwordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Tambah Akun Mekanik',
          ),
          content:
              SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                TextField(
                  controller:
                      nameController,
                  decoration:
                      const InputDecoration(
                    labelText: 'Nama',
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller:
                      usernameController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Username',
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller:
                      passwordController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Password',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
              ),
              child:
                  const Text('Batal'),
            ),

            ElevatedButton(
              onPressed: () {
                final name =
                    nameController.text
                        .trim();

                final username =
                    usernameController
                        .text
                        .trim();

                final password =
                    passwordController
                        .text;

                if (name.isEmpty ||
                    username.isEmpty ||
                    password.length <
                        6) {
                  showMessage(
                    context,
                    'Isi data dengan benar. Password minimal 6 karakter.',
                  );
                  return;
                }

                final exists =
                    AppState.instance
                        .accounts
                        .any(
                  (account) =>
                      account.username ==
                      username,
                );

                if (exists) {
                  showMessage(
                    context,
                    'Username sudah digunakan.',
                  );
                  return;
                }

                AppState.instance
                    .addAccount(
                  MechanicAccount(
                    id: DateTime.now()
                        .microsecondsSinceEpoch
                        .toString(),
                    name: name,
                    username: username,
                    password: password,
                  ),
                );

                Navigator.pop(
                  dialogContext,
                );

                showMessage(
                  context,
                  'Akun berhasil ditambahkan.',
                );
              },
              child:
                  const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void resetPassword(
    BuildContext context,
    MechanicAccount account,
  ) {
    final controller =
        TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Reset Password',
          ),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration:
                const InputDecoration(
              labelText:
                  'Password baru',
              border:
                  OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
              ),
              child:
                  const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller
                        .text.length <
                    6) {
                  showMessage(
                    context,
                    'Password minimal 6 karakter.',
                  );
                  return;
                }

                AppState.instance
                    .resetAccountPassword(
                  account.id,
                  controller.text,
                );

                Navigator.pop(
                  dialogContext,
                );

                showMessage(
                  context,
                  'Password berhasil direset.',
                );
              },
              child:
                  const Text('Reset'),
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
        final accounts =
            AppState.instance.accounts;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Kelola Akun Mekanik',
            ),
          ),

          floatingActionButton:
              FloatingActionButton.extended(
            onPressed: () =>
                addAccount(context),
            icon: const Icon(
              Icons.person_add,
            ),
            label: const Text(
              'Tambah Akun',
            ),
          ),

          body: ListView.builder(
            padding:
                const EdgeInsets.only(
              bottom: 90,
            ),
            itemCount: accounts.length,
            itemBuilder:
                (context, index) {
              final account =
                  accounts[index];

              return Card(
                margin:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          CircleAvatar(
                        child: Icon(
                          account.active
                              ? Icons.person
                              : Icons.person_off,
                        ),
                      ),
                      title: Text(
                        account.name,
                      ),
                      subtitle: Text(
                        '@${account.username}\n'
                        '${account.active ? 'Aktif' : 'Nonaktif'}',
                      ),
                      isThreeLine: true,
                    ),

                    SwitchListTile(
                      title: const Text(
                        'Status Akun',
                      ),
                      value:
                          account.active,
                      onChanged: (_) {
                        AppState
                            .instance
                            .toggleAccount(
                          account.id,
                        );
                      },
                    ),

                    Align(
                      alignment:
                          Alignment.centerRight,
                      child:
                          TextButton.icon(
                        onPressed: () =>
                            resetPassword(
                          context,
                          account,
                        ),
                        icon: const Icon(
                          Icons.lock_reset,
                        ),
                        label: const Text(
                          'Reset Password',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}