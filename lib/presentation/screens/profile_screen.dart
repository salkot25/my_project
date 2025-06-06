import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/auth_gate.dart'; // Untuk navigasi setelah logout
import 'auth/change_password_screen.dart'; // Import layar ganti password

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  static const String routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        // Arahkan kembali ke AuthGate, yang akan menangani pengalihan ke LoginScreen
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AuthGate.routeName, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal logout: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Pengguna')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Email: ${_user?.email ?? 'Tidak tersedia'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed(ChangePasswordScreen.routeName);
                },
                child: const Text('Ganti Password'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
