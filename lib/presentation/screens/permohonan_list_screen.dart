import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/permohonan_cubit/permohonan_cubit.dart';
import '../widgets/permohonan_list_tile.dart';
import './permohonan_detail_screen.dart';

class PermohonanListScreen extends StatefulWidget {
  const PermohonanListScreen({super.key});

  static const String routeName = '/';

  @override
  State<PermohonanListScreen> createState() => _PermohonanListScreenState();
}

class _PermohonanListScreenState extends State<PermohonanListScreen> {
  @override
  void initState() {
    super.initState();
    // Muat daftar permohonan saat layar pertama kali dibuka
    context.read<PermohonanCubit>().loadPermohonanList();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Permohonan')),
      body: BlocBuilder<PermohonanCubit, PermohonanState>(
        builder: (context, state) {
          if (state is PermohonanLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PermohonanListLoaded) {
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
          return const Center(child: Text('Silakan muat data.'));
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
