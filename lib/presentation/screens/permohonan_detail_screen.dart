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
  int? _expandedTahapanIndex;

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

  Widget _buildTahapanFormSummary(TahapanModel tahapan) {
    final data = tahapan.formData ?? {};
    switch (tahapan.nama) {
      case "Permohonan":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['jenis_permohonan'] != null)
              Text('Jenis Permohonan: ${data['jenis_permohonan']}'),
            if (data['daya'] != null) Text('Daya: ${data['daya']}'),
            if (data['prioritas'] != null)
              Text('Prioritas: ${data['prioritas']}'),
            if (data['catatan'] != null &&
                data['catatan'].toString().isNotEmpty)
              Text('Catatan: ${data['catatan']}'),
          ],
        );
      case "Survey Lokasi":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['tanggal_survey'] != null)
              Text('Tanggal Survey: ${data['tanggal_survey']}'),
            if (data['hasil_survey'] != null)
              Text('Hasil Survey: ${data['hasil_survey']}'),
            if (data['catatan_survey'] != null &&
                data['catatan_survey'].toString().isNotEmpty)
              Text('Catatan: ${data['catatan_survey']}'),
          ],
        );
      case "MOM":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['tanggal_mom'] != null)
              Text('Tanggal MOM: ${data['tanggal_mom']}'),
            if (data['catatan_mom'] != null &&
                data['catatan_mom'].toString().isNotEmpty)
              Text('Catatan: ${data['catatan_mom']}'),
          ],
        );
      case "RAB":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['ukuran_trafo'] != null)
              Text('Ukuran Trafo: ${data['ukuran_trafo']}'),
            if (data['jumlah_tiang'] != null)
              Text('Jumlah Tiang: ${data['jumlah_tiang']}'),
            if (data['catatan_rab'] != null &&
                data['catatan_rab'].toString().isNotEmpty)
              Text('Catatan: ${data['catatan_rab']}'),
          ],
        );
      case "Kontrak Rinci":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['vendor'] != null) Text('Vendor: ${data['vendor']}'),
            if (data['catatan_kontrak'] != null &&
                data['catatan_kontrak'].toString().isNotEmpty)
              Text('Catatan: ${data['catatan_kontrak']}'),
          ],
        );
      case "Pasang APP":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['tanggal_pasang'] != null)
              Text('Tanggal Pasang: ${data['tanggal_pasang']}'),
            if (data['catatan_pasang'] != null &&
                data['catatan_pasang'].toString().isNotEmpty)
              Text('Catatan: ${data['catatan_pasang']}'),
          ],
        );
      default:
        return const Text('Tidak ada data.');
    }
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
              appBar: AppBar(
                title: const Text('Detail Permohonan'),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
                actions: <Widget>[
                  if (canModify)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.black87),
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
              body: Container(
                color: Colors.blue.shade50,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header Card
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          _TahapanProgressCircle(
                            total: permohonan.daftarTahapan.length,
                            done: permohonan.daftarTahapan
                                .where((t) => t.status == StatusTahapan.selesai)
                                .length,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  permohonan.namaPelanggan,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // HAPUS BARIS INI:
                                // Text(
                                //   'ID: {permohonan.id}',
                                //   style: const TextStyle(color: Colors.white70),
                                // ),
                                const SizedBox(height: 2),
                                Text(
                                  'Diajukan: ${DateFormat('dd MMM yyyy').format(permohonan.tanggalPengajuan)}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(
                              permohonan.statusKeseluruhan ==
                                      StatusPermohonan.proses
                                  ? (() {
                                      final aktif = permohonan.daftarTahapan
                                          .where((t) => t.isAktif)
                                          .toList();
                                      return aktif.isNotEmpty
                                          ? aktif.first.nama
                                          : 'Proses';
                                    })()
                                  : permohonan.statusKeseluruhan.name
                                        .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor:
                                permohonan.statusKeseluruhan ==
                                    StatusPermohonan.selesai
                                ? Colors.green
                                : permohonan.statusKeseluruhan ==
                                      StatusPermohonan.dibatalkan
                                ? Colors.red
                                : Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Info Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade400,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Info Permohonan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          if (permohonan.jenisPermohonan != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'Jenis: ${permohonan.jenisPermohonan == JenisPermohonan.pasangBaru ? "Pasang Baru" : "Perubahan Daya"}',
                              ),
                            ),
                          if (permohonan.daya != null &&
                              permohonan.daya!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('Daya: ${permohonan.daya}'),
                            ),
                          if (permohonan.prioritas != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'Prioritas: ${permohonan.prioritas.toString().split(".").last.toUpperCase()}',
                              ),
                            ),
                          if (permohonan.catatanPermohonan != null &&
                              permohonan.catatanPermohonan!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'Catatan: ${permohonan.catatanPermohonan}',
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Progres Tahapan
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timeline, color: Colors.blue.shade400),
                              const SizedBox(width: 8),
                              const Text(
                                'Progres Tahapan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: permohonan.daftarTahapan.length,
                            itemBuilder: (context, index) {
                              final tahapan = permohonan.daftarTahapan[index];
                              final isExpandable = !tahapan.isMenunggu;
                              final isExpanded = _expandedTahapanIndex == index;
                              // Timeline color logic
                              Color dotColor;
                              if (tahapan.status == StatusTahapan.selesai) {
                                dotColor = Colors.green;
                              } else if (tahapan.isAktif) {
                                dotColor = Colors.orangeAccent.shade700;
                              } else if (tahapan.status ==
                                  StatusTahapan.menunggu) {
                                dotColor = Colors.grey.shade400;
                              } else {
                                dotColor = Colors.blue.shade400;
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Timeline
                                  SizedBox(
                                    width: 32,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Garis atas (jika bukan tahapan pertama)
                                        if (index != 0)
                                          Container(
                                            width: 2,
                                            height: 24,
                                            color: Colors.grey.shade300,
                                          ),
                                        // Dot status
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: dotColor,
                                              width: 4,
                                            ),
                                          ),
                                        ),
                                        // Garis bawah (jika bukan tahapan terakhir)
                                        if (index !=
                                            permohonan.daftarTahapan.length - 1)
                                          Container(
                                            width: 2,
                                            height: 24,
                                            color: Colors.grey.shade300,
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Card tahapan
                                  Expanded(
                                    child: Card(
                                      elevation: isExpanded ? 8 : 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: BorderSide(
                                          color: isExpanded
                                              ? Colors.blue.shade400
                                              : Colors.grey.shade300,
                                          width: isExpanded ? 2.2 : 1.0,
                                        ),
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        children: [
                                          GestureDetector(
                                            onTap: isExpandable
                                                ? () {
                                                    setState(() {
                                                      _expandedTahapanIndex =
                                                          isExpanded
                                                          ? null
                                                          : index;
                                                    });
                                                  }
                                                : null,
                                            child: TahapanListItem(
                                              tahapan: tahapan,
                                              index: index,
                                              totalTahapan: permohonan
                                                  .daftarTahapan
                                                  .length,
                                            ),
                                          ),
                                          if (isExpanded && isExpandable)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                left: 16,
                                                right: 16,
                                                bottom: 16,
                                                top: 4,
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.08),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child:
                                                  tahapan.isAktif && canModify
                                                  ? _buildCurrentStageForm(
                                                      permohonan,
                                                      tahapan,
                                                    )
                                                  : _buildTahapanFormSummary(
                                                      tahapan,
                                                    ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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

// Tambahkan widget _TahapanProgressCircle di bawah file ini

class _TahapanProgressCircle extends StatelessWidget {
  final int total;
  final int done;
  const _TahapanProgressCircle({required this.total, required this.done});

  @override
  Widget build(BuildContext context) {
    final double percent = total == 0 ? 0 : done / total;
    final Color mainColor = Colors.orangeAccent.shade200;
    final Color bgColor = Colors.white.withOpacity(0.18);
    final int percentValue = (percent * 100).round();
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background shadow circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          // Background circle (track)
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(bgColor),
            ),
          ),
          // Foreground progress
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(mainColor),
              backgroundColor: Colors.transparent,
            ),
          ),
          // Centered percent text
          Text(
            '$percentValue%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
