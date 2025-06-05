import 'package:flutter/material.dart';
import '../presentation/screens/permohonan_list_screen.dart';
import '../presentation/screens/permohonan_detail_screen.dart';

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
        return _errorRoute("ID Permohonan tidak ditemukan");
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
