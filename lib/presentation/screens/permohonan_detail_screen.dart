import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/permohonan_cubit/permohonan_cubit.dart';
import '../../data/models/permohonan_model.dart';
import '../../data/models/tahapan_model.dart';
import '../widgets/tahapan_list_item.dart';
import '../widgets/forms/form_permohonan_widget.dart'; // Import form
import '../widgets/forms/form_survey_widget.dart'; // Import form
import '../widgets/forms/form_mom_widget.dart'; // Import form
import '../widgets/forms/form_rab_widget.dart'; // Import form
import '../widgets/forms/form_kontrak_rinci_widget.dart'; // Import form
import '../widgets/forms/form_pasang_app_widget.dart'; // Import form
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

  Widget _buildCurrentStageForm(
    PermohonanModel permohonan,
    TahapanModel tahapanAktif,
  ) {
    // Fungsi untuk menangani submit form
    void handleFormSubmit(Map<String, dynamic> formData) {
      context.read<PermohonanCubit>().saveStageFormDataAndComplete(
        permohonan.id,
        tahapanAktif.nama,
        formData,
      );
    }

    switch (tahapanAktif.nama) {
      case "Permohonan":
        return FormPermohonanWidget(
          permohonan: permohonan,
          onSubmit: handleFormSubmit,
        );
      case "Survey Lokasi":
        return FormSurveyWidget(
          onSubmit: handleFormSubmit,
          initialData: tahapanAktif.formData,
        );
      // case "MOM":
      case "MOM":
        return FormMomWidget(
          onSubmit: handleFormSubmit,
          initialData: tahapanAktif.formData,
        );
      case "RAB":
        // Anda mungkin perlu mengambil data survey dari tahap sebelumnya jika diperlukan di form RAB
        // final surveyTahap = permohonan.daftarTahapan.firstWhere((t) => t.nama == "Survey Lokasi", orElse: () => const TahapanModel(nama: ''));
        // final surveyData = surveyTahap.formData;
        return FormRabWidget(
          onSubmit: handleFormSubmit,
          initialData: tahapanAktif.formData,
        );
      case "Kontrak Rinci":
        // Anda mungkin perlu mengambil data RAB dari tahap sebelumnya
        // final rabTahap = permohonan.daftarTahapan.firstWhere((t) => t.nama == "RAB", orElse: () => const TahapanModel(nama: ''));
        // final rabData = rabTahap.formData;
        return FormKontrakRinciWidget(
          onSubmit: handleFormSubmit,
          initialData: tahapanAktif.formData,
        );
      case "Pasang APP":
        return FormPasangAppWidget(
          onSubmit: handleFormSubmit,
          initialData: tahapanAktif.formData,
        );
      //   return FormMomWidget(onSubmit: handleFormSubmit, initialData: tahapanAktif.formData);
      // ... tambahkan case untuk form lainnya
      default:
        // Jika tidak ada form khusus, tampilkan tombol default untuk menyelesaikan tahap
        return Center(
          child: ElevatedButton(
            onPressed: () => context.read<PermohonanCubit>().advanceToNextStage(
              permohonan.id,
              tahapanAktif.nama,
            ),
            child: Text('Selesaikan Tahap: ${tahapanAktif.nama}'),
          ),
        );
    }
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
                    _buildCurrentStageForm(permohonan, tahapanAktif),
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
