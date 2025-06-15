import 'package:flutter/material.dart';
import 'package:my_project/presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/permohonan_list_screen.dart';
import '../presentation/screens/permohonan_detail_screen.dart';
import '../presentation/screens/auth/auth_gate.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/profile_screen.dart';
import '../presentation/screens/auth/change_password_screen.dart';
import '../presentation/screens/dashboard_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/my_task_screen.dart';
import '../presentation/screens/vendor_laporan_jaringan_screen.dart';
import '../presentation/screens/permohonan_map_screen.dart';
import '../presentation/screens/vendor_laporan_jaringan_list_screen.dart';

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
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case MyTaskScreen.routeName:
        return MaterialPageRoute(builder: (_) => const MyTaskScreen());
      case '/vendor-laporan-jaringan':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('permohonanId')) {
          return MaterialPageRoute(
            builder: (_) => VendorLaporanJaringanScreen(
              permohonanId: args['permohonanId'] as String,
              namaPelanggan: args['namaPelanggan'] as String?,
            ),
          );
        }
        return _errorRoute(
          "Argumen untuk VendorLaporanJaringanScreen tidak valid.",
        );
      case '/vendor-laporan-jaringan-list':
        return MaterialPageRoute(
          builder: (_) => const VendorLaporanJaringanListScreen(),
        );
      case PermohonanMapScreen.routeName:
        return MaterialPageRoute(builder: (_) => const PermohonanMapScreen());
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
