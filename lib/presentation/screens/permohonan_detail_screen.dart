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
        final surveyTahap = permohonan.daftarTahapan.firstWhere(
          (t) => t.nama == "Survey Lokasi",
          orElse: () => const TahapanModel(nama: 'Survey Lokasi', formData: {}),
        );
        return FormRabWidget(
          onSubmit: handleFormSubmit,
          initialData: tahapanAktif.formData,
          surveyData: surveyTahap.formData,
        );
      case "Kontrak Rinci":
        final rabTahap = permohonan.daftarTahapan.firstWhere(
          (t) => t.nama == "RAB",
          orElse: () => const TahapanModel(nama: 'RAB', formData: {}),
        );
        return FormKontrakRinciWidget(
          onSubmit: handleFormSubmit,
          initialData: tahapanAktif.formData,
          rabData: rabTahap.formData,
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

  void _showEditPermohonanDialog(
    BuildContext context,
    PermohonanModel permohonan,
  ) {
    final formKey = GlobalKey<FormState>();
    final TextEditingController namaController = TextEditingController(
      text: permohonan.namaPelanggan,
    );
    final TextEditingController catatanController = TextEditingController(
      text: permohonan.catatanPermohonan,
    );
    final TextEditingController dayaController = TextEditingController(
      text: permohonan.daya,
    );
    Prioritas? selectedPrioritas = permohonan.prioritas;
    JenisPermohonan? selectedJenisPermohonan = permohonan.jenisPermohonan;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          // Untuk update state di dalam dialog (prioritas dropdown)
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Detail Permohonan'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: namaController,
                        decoration: const InputDecoration(
                          labelText: "Nama Pelanggan",
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Nama pelanggan tidak boleh kosong'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<JenisPermohonan>(
                        value: selectedJenisPermohonan,
                        hint: const Text('Pilih Jenis Permohonan'),
                        items: JenisPermohonan.values.map((
                          JenisPermohonan value,
                        ) {
                          return DropdownMenuItem<JenisPermohonan>(
                            value: value,
                            child: Text(
                              value == JenisPermohonan.pasangBaru
                                  ? 'Pasang Baru'
                                  : 'Perubahan Daya',
                            ),
                          );
                        }).toList(),
                        onChanged: (JenisPermohonan? newValue) {
                          setDialogState(() {
                            selectedJenisPermohonan = newValue;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Jenis Permohonan',
                        ),
                        // validator: (value) => value == null ? 'Jenis Permohonan harus dipilih' : null, // Bisa opsional jika boleh kosong
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: dayaController,
                        decoration: const InputDecoration(
                          labelText: "Daya (Contoh: 1300 VA)",
                        ),
                        // validator: (value) => value == null || value.isEmpty ? 'Daya tidak boleh kosong' : null, // Bisa opsional
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Prioritas>(
                        value: selectedPrioritas,
                        hint: const Text('Pilih Prioritas'),
                        items: Prioritas.values.map((Prioritas value) {
                          return DropdownMenuItem<Prioritas>(
                            value: value,
                            child: Text(
                              value.toString().split('.').last.toUpperCase(),
                            ),
                          );
                        }).toList(),
                        onChanged: (Prioritas? newValue) {
                          setDialogState(() {
                            selectedPrioritas = newValue;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Prioritas',
                        ),
                        // validator: (value) => value == null ? 'Prioritas harus dipilih' : null, // Prioritas bisa opsional
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: catatanController,
                        decoration: const InputDecoration(
                          labelText: "Catatan Permohonan",
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                TextButton(
                  child: const Text('Simpan'),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      context
                          .read<PermohonanCubit>()
                          .updatePermohonanDetailData(
                            permohonan.id,
                            namaPelanggan: namaController.text,
                            prioritas: selectedPrioritas,
                            jenisPermohonan: selectedJenisPermohonan,
                            daya: dayaController.text,
                            catatanPermohonan: catatanController.text,
                          );
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmBatalkanPermohonan(
    BuildContext context,
    PermohonanModel permohonan,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Pembatalan'),
          content: const Text(
            'Apakah Anda yakin ingin membatalkan permohonan ini? Tindakan ini tidak dapat diurungkan.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tidak'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                context.read<PermohonanCubit>().batalkanPermohonan(
                  permohonan.id,
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Ya, Batalkan'),
            ),
          ],
        );
      },
    );
  }

  void _confirmHapusPermohonan(
    BuildContext context,
    PermohonanModel permohonan,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Penghapusan'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus permohonan ini? Tindakan ini tidak dapat diurungkan dan akan menghapus semua data terkait.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tidak'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                context.read<PermohonanCubit>().hapusPermohonan(permohonan.id);
                Navigator.of(dialogContext).pop();
                // Navigasi kembali ke list screen setelah dialog ditutup dan cubit memproses
              },
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<PermohonanCubit, PermohonanState>(
        listener: (context, state) {
          if (state is PermohonanError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
          } else if (state is PermohonanOperationSuccess &&
              state.message.contains("dihapus")) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            Navigator.of(context).pop(); // Kembali ke layar sebelumnya (list)
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

            final bool canModify =
                permohonan.statusKeseluruhan == StatusPermohonan.proses;

            return Scaffold(
              // Nested Scaffold untuk AppBar dengan context yang benar
              appBar: AppBar(
                title: const Text('Detail Permohonan'),
                actions: <Widget>[
                  if (canModify) // Hanya tampilkan jika status masih proses
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditPermohonanDialog(context, permohonan);
                        } else if (value == 'batalkan') {
                          _confirmBatalkanPermohonan(context, permohonan);
                        } else if (value == 'hapus') {
                          _confirmHapusPermohonan(context, permohonan);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Edit Detail'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'batalkan',
                              child: Text('Batalkan Permohonan'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'hapus',
                              child: Text(
                                'Hapus Permohonan',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                    ),
                ],
              ),
              body: SingleChildScrollView(
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
                    if (permohonan.jenisPermohonan != null)
                      Text(
                        'Jenis: ${permohonan.jenisPermohonan == JenisPermohonan.pasangBaru ? "Pasang Baru" : "Perubahan Daya"}',
                      ),
                    if (permohonan.daya != null && permohonan.daya!.isNotEmpty)
                      Text('Daya: ${permohonan.daya}'),
                    if (permohonan.prioritas != null)
                      Text(
                        'Prioritas: ${permohonan.prioritas.toString().split(".").last.toUpperCase()}',
                      ),
                    if (permohonan.catatanPermohonan != null &&
                        permohonan.catatanPermohonan!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('Catatan: ${permohonan.catatanPermohonan}'),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Status Keseluruhan: ${permohonan.statusKeseluruhan.name.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            permohonan.statusKeseluruhan ==
                                StatusPermohonan.dibatalkan
                            ? Colors.red
                            : Theme.of(context).primaryColor,
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
                    if (tahapanAktif.isAktif && canModify)
                      _buildCurrentStageForm(permohonan, tahapanAktif),
                  ],
                ),
              ),
            );
          }
          return const Center(child: Text('Gagal memuat detail permohonan.'));
        },
      ),
    );
  }
}
