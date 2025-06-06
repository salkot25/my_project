import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/permohonan_cubit/permohonan_cubit.dart';
import '../widgets/permohonan_list_tile.dart';
import '../widgets/app_drawer.dart'; // Import drawer
import '../../app.dart'; // Import untuk mengakses routeObserver
import './permohonan_detail_screen.dart';

class PermohonanListScreen extends StatefulWidget {
  const PermohonanListScreen({super.key});

  static const String routeName = '/';

  @override
  State<PermohonanListScreen> createState() => _PermohonanListScreenState();
}

class _PermohonanListScreenState extends State<PermohonanListScreen>
    with RouteAware {
  @override
  void initState() {
    super.initState();
    // Pemuatan awal utama ditangani oleh pembuatan PermohonanCubit di app.dart.
    // initState ini bisa berfungsi sebagai fallback jika state cubit masih PermohonanInitial
    // saat layar ini dibangun untuk pertama kalinya.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          context.read<PermohonanCubit>().state is PermohonanInitial) {
        context.read<PermohonanCubit>().loadPermohonanList();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route != null) {
      // Subscribe ke routeObserver untuk event navigasi
      routeObserver.subscribe(this, route as PageRoute);
    }
  }

  void _showAddPermohonanDialog(BuildContext context) {
    final TextEditingController namaController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Permohonan Baru'),
          content: TextField(
            controller: namaController,
            decoration: const InputDecoration(hintText: "Nama Pelanggan"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Tambah'),
              onPressed: () {
                if (namaController.text.isNotEmpty) {
                  context.read<PermohonanCubit>().tambahPermohonanBaru(
                    namaController.text,
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this); // Jangan lupa unsubscribe
    super.dispose();
  }

  @override
  void didPopNext() {
    // Dipanggil ketika rute teratas di-pop dan rute ini (PermohonanListScreen)
    // menjadi rute saat ini/aktif kembali.
    // Ini adalah tempat yang baik untuk memuat ulang atau me-refresh data daftar.
    print("PermohonanListScreen: didPopNext - Memuat ulang daftar permohonan");
    context.read<PermohonanCubit>().loadPermohonanList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Permohonan')),
      drawer: const AppDrawer(), // Tambahkan drawer di sini
      body: BlocBuilder<PermohonanCubit, PermohonanState>(
        builder: (context, state) {
          if (state is PermohonanListLoaded) {
            if (state.permohonanList.isEmpty) {
              return const Center(child: Text('Belum ada permohonan.'));
            }
            return ListView.builder(
              itemCount: state.permohonanList.length,
              itemBuilder: (context, index) {
                final permohonan = state.permohonanList[index];
                return PermohonanListTile(
                  permohonan: permohonan,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      PermohonanDetailScreen.routeName,
                      arguments: permohonan.id,
                    );
                  },
                );
              },
            );
          } else if (state is PermohonanError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          // Untuk state lainnya (PermohonanInitial, PermohonanLoading, PermohonanOperationSuccess, dll.),
          // tampilkan indikator loading.
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPermohonanDialog(context),
        tooltip: 'Tambah Permohonan',
        child: const Icon(Icons.add),
      ),
    );
  }
}
