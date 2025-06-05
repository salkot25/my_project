import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './logic/permohonan_cubit/permohonan_cubit.dart';
import './routes/app_router.dart';
import './presentation/screens/permohonan_list_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PermohonanCubit(),
      child: MaterialApp(
        title: 'Pemantau Progres Pekerjaan',
        theme: ThemeData(
          primarySwatch:
              Colors.teal, // Anda bisa mengganti tema sesuai keinginan
        ),
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: PermohonanListScreen.routeName,
      ),
    );
  }
}
