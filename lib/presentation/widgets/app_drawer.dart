import 'package:flutter/material.dart';
import '../screens/permohonan_list_screen.dart';
import '../screens/profile_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Text(
              'Menu Aplikasi',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Daftar Permohonan'),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              Navigator.pushReplacementNamed(
                context,
                PermohonanListScreen.routeName,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              Navigator.pushNamed(context, ProfileScreen.routeName);
            },
          ),
        ],
      ),
    );
  }
}
