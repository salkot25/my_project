import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(currentRoute: '/settings'),
      body: const Center(
        child: Text(
          'Pengaturan aplikasi akan tersedia di sini.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
