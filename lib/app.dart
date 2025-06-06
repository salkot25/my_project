import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './logic/permohonan_cubit/permohonan_cubit.dart';
import './routes/app_router.dart';
import './presentation/screens/auth/auth_gate.dart'; // Ganti initial screen

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PermohonanCubit()..loadPermohonanList(),
      child: MaterialApp(
        title: 'Pemantau Progres Pekerjaan',
        theme: ThemeData(
          primarySwatch:
              Colors.teal, // Anda bisa mengganti tema sesuai keinginan
        ),
        navigatorObservers: [routeObserver], // Tambahkan observer di sini
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AuthGate.routeName, // Atur AuthGate sebagai initial route
      ),
    );
  }
}
