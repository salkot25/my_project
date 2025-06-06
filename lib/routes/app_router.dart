import 'package:flutter/material.dart';
import 'package:my_project/presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/permohonan_list_screen.dart';
import '../presentation/screens/permohonan_detail_screen.dart';
import '../presentation/screens/auth/auth_gate.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/profile_screen.dart';
import '../presentation/screens/auth/change_password_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case PermohonanListScreen.routeName:
        return MaterialPageRoute(builder: (_) => const PermohonanListScreen());
      case PermohonanDetailScreen.routeName:
        final permohonanId = settings.arguments as String?;
        if (permohonanId != null) {
          return MaterialPageRoute(
            builder: (_) => PermohonanDetailScreen(permohonanId: permohonanId),
          );
        }
        // Return error route if permohonanId is null
        return _errorRoute("Permohonan ID tidak ditemukan.");
      case AuthGate.routeName:
        return MaterialPageRoute(builder: (_) => const AuthGate());
      case LoginScreen.routeName:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RegisterScreen.routeName:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case ForgotPasswordScreen.routeName:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case ProfileScreen.routeName:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case ChangePasswordScreen.routeName:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
      default:
        return _errorRoute("Rute tidak ditemukan: ${settings.name}");
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text(message)),
        );
      },
    );
  }
}
