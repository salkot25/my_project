import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/permohonan_cubit/permohonan_cubit.dart';
import '../../data/models/permohonan_model.dart';
import '../../data/models/tahapan_model.dart';
import '../widgets/tahapan_list_item.dart';
import 'package:intl/intl.dart';

class PermohonanDetailScreen extends StatefulWidget {
  const PermohonanDetailScreen({super.key, required this.permohonanId});

  static const String routeName = '/permohonan-detail';
  final String permohonanId;

  @override
  State<PermohonanDetailScreen> createState() => _PermohonanDetailScreenState();
}

class _PermohonanDetailScreenState extends State<PermohonanDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PermohonanCubit>().loadPermohonanDetail(widget.permohonanId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Permohonan')),
      body: BlocConsumer<PermohonanCubit, PermohonanState>(
        listener: (context, state) {
          if (state is PermohonanError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
          }
        },
        builder: (context, state) {
          if (state is PermohonanLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PermohonanDetailLoaded) {
            final permohonan = state.permohonan;
            final tahapanAktif = permohonan.daftarTahapan.firstWhere(
              (t) => t.isAktif,
              orElse: () => const TahapanModel(
                nama: '',
                status: StatusTahapan.menunggu,
              ), // Fallback
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID: ${permohonan.id}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Pelanggan: ${permohonan.namaPelanggan}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Tanggal Pengajuan: ${DateFormat('dd MMM yyyy').format(permohonan.tanggalPengajuan)}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status Keseluruhan: ${permohonan.statusKeseluruhan == StatusPermohonan.selesai ? "Selesai" : permohonan.tahapanAktif}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Progres Tahapan:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: permohonan.daftarTahapan.length,
                    itemBuilder: (context, index) {
                      final tahapan = permohonan.daftarTahapan[index];
                      return TahapanListItem(
                        tahapan: tahapan,
                        index: index,
                        totalTahapan: permohonan.daftarTahapan.length,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  if (tahapanAktif.isAktif &&
                      permohonan.statusKeseluruhan == StatusPermohonan.proses)
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<PermohonanCubit>().completeCurrentStage(
                            permohonan.id,
                          );
                        },
                        child: Text('Selesaikan Tahap: ${tahapanAktif.nama}'),
                      ),
                    ),
                ],
              ),
            );
          }
          return const Center(child: Text('Gagal memuat detail permohonan.'));
        },
      ),
    );
  }
}
