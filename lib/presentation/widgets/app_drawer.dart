import 'package:flutter/material.dart';
import '../screens/permohonan_list_screen.dart';
import '../screens/profile_screen.dart';

class AppDrawer extends StatelessWidget {
  final String? currentRoute;
  const AppDrawer({super.key, this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header biru dengan avatar dan nama
          Container(
            width: double.infinity,
            color: Colors.blue.shade600,
            padding: const EdgeInsets.only(
              top: 36,
              left: 24,
              right: 24,
              bottom: 18,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.blue.shade400,
                  child: Icon(Icons.apps, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Menu utama
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerSectionLabel('NAVIGASI UTAMA'),
                _DrawerCardMenu(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  isSelected: currentRoute == '/dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  },
                ),
                _DrawerCardMenu(
                  icon: Icons.list_alt,
                  title: 'Daftar Permohonan',
                  isSelected: currentRoute == PermohonanListScreen.routeName,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(
                      context,
                      PermohonanListScreen.routeName,
                    );
                  },
                ),
                const SizedBox(height: 18),
                _DrawerSectionLabel('AKUN & PENGATURAN'),
                _DrawerCardMenu(
                  icon: Icons.person,
                  title: 'Profil',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, ProfileScreen.routeName);
                  },
                ),
                _DrawerCardMenu(
                  icon: Icons.settings,
                  title: 'Settings',
                  isSelected: currentRoute == '/settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/settings');
                  },
                ),
                const SizedBox(height: 18),
                Divider(
                  thickness: 1,
                  color: Colors.grey.shade200,
                  indent: 24,
                  endIndent: 24,
                ),
                // Logout
                _DrawerCardMenu(
                  icon: Icons.logout,
                  title: 'Logout',
                  isSelected: false,
                  iconColor: Colors.red.shade400,
                  textColor: Colors.red.shade400,
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: const Text(
                            'Konfirmasi Logout',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: const Text(
                            'Apakah Anda yakin ingin keluar dari aplikasi?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Batal',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          // Footer info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Aplikasi Manajemen Proyek',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String text;
  const _DrawerSectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 18, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _DrawerCardMenu extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  const _DrawerCardMenu({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Colors.blue.shade50,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
              ],
              border: isSelected
                  ? Border.all(color: Colors.blue.shade200, width: 2)
                  : Border.all(color: Colors.white, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      iconColor ??
                      (isSelected ? Colors.blue : Colors.blue.shade400),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color:
                          textColor ??
                          (isSelected ? Colors.blue.shade700 : Colors.black87),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
