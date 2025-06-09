import 'package:flutter/material.dart';
import 'package:my_project/presentation/screens/dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  static const String routeName = '/auth-gate';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final session = snapshot.data?.session;
          if (session != null) {
            return const DashboardScreen(); // Pengguna sudah login
          }
        }
        return const LoginScreen(); // Pengguna belum login
      },
    );
  }
}
