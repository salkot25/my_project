import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/permohonan_cubit/permohonan_cubit.dart';
import '../../data/models/permohonan_model.dart';
import '../../data/models/tahapan_model.dart';
import '../widgets/forms/form_permohonan_widget.dart'; // Import form
import '../widgets/forms/form_survey_widget.dart'; // Import form
import '../widgets/forms/form_mom_widget.dart'; // Import form
import '../widgets/forms/form_rab_widget.dart'; // Import form
import '../widgets/forms/form_kontrak_rinci_widget.dart'; // Import form
import '../widgets/forms/form_pasang_app_widget.dart'; // Import form
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class PermohonanDetailScreen extends StatefulWidget {
  const PermohonanDetailScreen({super.key, required this.permohonanId});

  static const String routeName = '/permohonan-detail';
  final String permohonanId;

  @override
  State<PermohonanDetailScreen> createState() => _PermohonanDetailScreenState();
}

class _PermohonanDetailScreenState extends State<PermohonanDetailScreen> {
  int? _expandedTahapanIndex;
  int? _expandedEditIndex; // index tahapan yang sedang diedit manual

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
      // Jika sedang edit manual (bukan tahapan aktif), keluar dari mode edit setelah submit
      if (_expandedEditIndex != null) {
        setState(() {
          _expandedEditIndex = null;
        });
      }
    }

    switch (tahapanAktif.nama) {
      case "Permohonan":
        // Saat edit manual, pastikan FormPermohonanWidget menerima data dari tahapan.formData jika ada
        return FormPermohonanWidget(
          permohonan: PermohonanModel(
            id: permohonan.id,
            namaPelanggan:
                tahapanAktif.formData != null &&
                    tahapanAktif.formData!["nama_pelanggan"] != null
                ? tahapanAktif.formData!["nama_pelanggan"]
                : permohonan.namaPelanggan,
            tanggalPengajuan: permohonan.tanggalPengajuan,
            daftarTahapan: permohonan.daftarTahapan,
            statusKeseluruhan: permohonan.statusKeseluruhan,
            prioritas:
                tahapanAktif.formData != null &&
                    tahapanAktif.formData!["prioritas"] != null
                ? Prioritas.values.firstWhereOrNull(
                    (e) => e.name == tahapanAktif.formData!["prioritas"],
                  )
                : permohonan.prioritas,
            catatanPermohonan:
                tahapanAktif.formData != null &&
                    tahapanAktif.formData!["catatan"] != null
                ? tahapanAktif.formData!["catatan"]
                : permohonan.catatanPermohonan,
            jenisPermohonan:
                tahapanAktif.formData != null &&
                    tahapanAktif.formData!["jenis_permohonan"] != null
                ? JenisPermohonan.values.firstWhereOrNull(
                    (e) => e.name == tahapanAktif.formData!["jenis_permohonan"],
                  )
                : permohonan.jenisPermohonan,
            daya:
                tahapanAktif.formData != null &&
                    tahapanAktif.formData!["daya"] != null
                ? tahapanAktif.formData!["daya"]
                : permohonan.daya,
            namaTahapanAktifCache: permohonan.namaTahapanAktifCache,
            alamat:
                tahapanAktif.formData != null &&
                    tahapanAktif.formData!["alamat"] != null
                ? tahapanAktif.formData!["alamat"]
                : permohonan.alamat,
            waPelanggan:
                tahapanAktif.formData != null &&
                    tahapanAktif.formData!["wa_pelanggan"] != null
                ? tahapanAktif.formData!["wa_pelanggan"]
                : permohonan.waPelanggan,
          ),
          onSubmit: handleFormSubmit,
        );
      case "Survey Lokasi":
        // Saat edit manual, pastikan FormSurveyWidget menerima initialData dari tahapan.formData jika ada
        return FormSurveyWidget(
          onSubmit: handleFormSubmit,
          initialData:
              tahapanAktif.formData != null && tahapanAktif.formData!.isNotEmpty
              ? Map<String, dynamic>.from(tahapanAktif.formData!)
              : tahapanAktif.formData,
        );
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
      default:
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
    final TextEditingController alamatController = TextEditingController(
      text: permohonan.alamat,
    );
    final TextEditingController waController = TextEditingController(
      text: permohonan.waPelanggan,
    );
    Prioritas? selectedPrioritas = permohonan.prioritas;
    JenisPermohonan? selectedJenisPermohonan = permohonan.jenisPermohonan;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
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
                            child: Text(value.label),
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
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: dayaController,
                        decoration: const InputDecoration(
                          labelText: "Daya (Contoh: 1300 VA)",
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Prioritas>(
                        value: selectedPrioritas,
                        hint: const Text('Pilih Prioritas'),
                        items: Prioritas.values.map((Prioritas value) {
                          return DropdownMenuItem<Prioritas>(
                            value: value,
                            child: Text(value.label),
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
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: catatanController,
                        decoration: const InputDecoration(
                          labelText: "Catatan Permohonan",
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: alamatController,
                        decoration: const InputDecoration(labelText: "Alamat"),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Alamat tidak boleh kosong'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: waController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "No. WhatsApp Pelanggan",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'No. WhatsApp harus diisi';
                          }
                          if (!RegExp(
                            r'^(\+62|62|08)[0-9]{8,15} ',
                          ).hasMatch(value)) {
                            return 'Format WA tidak valid';
                          }
                          return null;
                        },
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
                            alamat: alamatController.text,
                            waPelanggan: waController.text,
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
    Map<String, dynamic> fields;
    Map<String, IconData> icons;
    Map<String, String> labels;
    switch (tahapan.nama) {
      case "Permohonan":
        fields = {
          if (data['nama_pelanggan'] != null &&
              data['nama_pelanggan'].toString().isNotEmpty)
            'nama_pelanggan': data['nama_pelanggan'],
          if (data['alamat'] != null && data['alamat'].toString().isNotEmpty)
            'alamat': data['alamat'],
          if (data['wa_pelanggan'] != null &&
              data['wa_pelanggan'].toString().isNotEmpty)
            'wa_pelanggan': data['wa_pelanggan'],
          if (data['jenis_permohonan'] != null)
            'jenis_permohonan': data['jenis_permohonan'],
          if (data['daya'] != null) 'daya': data['daya'],
          if (data['prioritas'] != null) 'prioritas': data['prioritas'],
          if (data['catatan'] != null && data['catatan'].toString().isNotEmpty)
            'catatan': data['catatan'],
        };
        icons = {
          'nama_pelanggan': Icons.person,
          'alamat': Icons.location_on,
          'wa_pelanggan': Icons.phone,
          'jenis_permohonan': Icons.assignment,
          'daya': Icons.flash_on,
          'prioritas': Icons.flag,
          'catatan': Icons.sticky_note_2,
        };
        labels = {
          'nama_pelanggan': 'Nama Pelanggan',
          'alamat': 'Alamat',
          'wa_pelanggan': 'No. WhatsApp',
          'jenis_permohonan': 'Jenis Permohonan',
          'daya': 'Daya',
          'prioritas': 'Prioritas',
          'catatan': 'Catatan',
        };
        break;
      case "Survey Lokasi":
        fields = {
          if (data['tanggal_survey'] != null)
            'tanggal_survey': data['tanggal_survey'],
          if (data['tag_lokasi'] != null &&
              data['tag_lokasi'].toString().isNotEmpty)
            'tag_lokasi': data['tag_lokasi'],
          if (data['hasil_survey'] != null)
            'hasil_survey': data['hasil_survey'],
          if (data['catatan_survey'] != null &&
              data['catatan_survey'].toString().isNotEmpty)
            'catatan_survey': data['catatan_survey'],
        };
        icons = {
          'tanggal_survey': Icons.event,
          'tag_lokasi': Icons.location_on,
          'hasil_survey': Icons.checklist,
          'catatan_survey': Icons.sticky_note_2,
        };
        labels = {
          'tanggal_survey': 'Tanggal Survey',
          'tag_lokasi': 'Tag Lokasi',
          'hasil_survey': 'Hasil Survey',
          'catatan_survey': 'Catatan',
        };
        break;
      case "MOM":
        fields = {
          if (data['tanggal_mom'] != null) 'tanggal_mom': data['tanggal_mom'],
          if (data['catatan_mom'] != null &&
              data['catatan_mom'].toString().isNotEmpty)
            'catatan_mom': data['catatan_mom'],
        };
        icons = {
          'tanggal_mom': Icons.event_note,
          'catatan_mom': Icons.sticky_note_2,
        };
        labels = {'tanggal_mom': 'Tanggal MOM', 'catatan_mom': 'Catatan'};
        break;
      case "RAB":
        fields = {
          if (data['ukuran_trafo'] != null)
            'ukuran_trafo': data['ukuran_trafo'],
          if (data['jumlah_tiang'] != null)
            'jumlah_tiang': data['jumlah_tiang'],
          if (data['catatan_rab'] != null &&
              data['catatan_rab'].toString().isNotEmpty)
            'catatan_rab': data['catatan_rab'],
        };
        icons = {
          'ukuran_trafo': Icons.electrical_services,
          'jumlah_tiang': Icons.account_tree,
          'catatan_rab': Icons.sticky_note_2,
        };
        labels = {
          'ukuran_trafo': 'Ukuran Trafo',
          'jumlah_tiang': 'Jumlah Tiang',
          'catatan_rab': 'Catatan',
        };
        break;
      case "Kontrak Rinci":
        fields = {
          if (data['vendor'] != null) 'vendor': data['vendor'],
          if (data['catatan_kontrak'] != null &&
              data['catatan_kontrak'].toString().isNotEmpty)
            'catatan_kontrak': data['catatan_kontrak'],
        };
        icons = {
          'vendor': Icons.business,
          'catatan_kontrak': Icons.sticky_note_2,
        };
        labels = {'vendor': 'Vendor', 'catatan_kontrak': 'Catatan'};
        break;
      case "Pasang APP":
        fields = {
          if (data['tanggal_pasang'] != null)
            'tanggal_pasang': data['tanggal_pasang'],
          if (data['catatan_pasang'] != null &&
              data['catatan_pasang'].toString().isNotEmpty)
            'catatan_pasang': data['catatan_pasang'],
        };
        icons = {
          'tanggal_pasang': Icons.event_available,
          'catatan_pasang': Icons.sticky_note_2,
        };
        labels = {
          'tanggal_pasang': 'Tanggal Pasang',
          'catatan_pasang': 'Catatan',
        };
        break;
      default:
        fields = {};
        icons = {};
        labels = {};
    }
    if (fields.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade100, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade200, size: 38),
            const SizedBox(height: 10),
            Text(
              'Belum ada data untuk tahap ini',
              style: TextStyle(
                color: Colors.blue.shade400,
                fontWeight: FontWeight.w600,
                fontSize: 15.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              'Silakan lengkapi form pada tahap ini.',
              style: TextStyle(
                color: Colors.blueGrey.shade300,
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Column(
      children: fields.entries.map((entry) {
        final key = entry.key;
        var value = entry.value;
        if (key == 'tanggal_survey' ||
            key == 'tanggal_mom' ||
            key == 'tanggal_pasang') {
          try {
            final dt = DateTime.tryParse(value.toString());
            if (dt != null) {
              value = DateFormat('dd MMMM yyyy', 'id_ID').format(dt);
            }
          } catch (_) {}
        }
        if (key == 'jenis_permohonan') {
          value =
              JenisPermohonan.values
                  .firstWhereOrNull((e) => e.name == value)
                  ?.label ??
              value;
        }
        if (key == 'prioritas') {
          value =
              Prioritas.values
                  .firstWhereOrNull((e) => e.name == value)
                  ?.label ??
              value;
        }
        if (key == 'hasil_survey') {
          value =
              HasilSurvey.values
                  .firstWhereOrNull((e) => e.name == value)
                  ?.label ??
              value;
        }
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 7),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blueGrey.shade100, width: 1.1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(7),
                child: Icon(
                  icons[key] ?? Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labels[key] ?? key,
                      style: TextStyle(
                        color: Colors.blueGrey.shade400,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value.toString(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          if (state is PermohonanLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PermohonanDetailLoaded) {
            final permohonan = state.permohonan;
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
                                Text(
                                  'Diajukan: ${DateFormat('dd MMM yyyy').format(permohonan.tanggalPengajuan)}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.02),
                            blurRadius: 1.5,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Info Permohonan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      permohonan.statusKeseluruhan ==
                                          StatusPermohonan.selesai
                                      ? const Color(0xFF22C55E)
                                      : permohonan.statusKeseluruhan ==
                                            StatusPermohonan.dibatalkan
                                      ? const Color(0xFFF43F5E)
                                      : const Color(0xFFF59E42),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (permohonan.statusKeseluruhan ==
                                        StatusPermohonan.selesai)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                        color: Colors.white.withOpacity(0.92),
                                      ),
                                    if (permohonan.statusKeseluruhan ==
                                        StatusPermohonan.dibatalkan)
                                      Icon(
                                        Icons.cancel_rounded,
                                        size: 16,
                                        color: Colors.white.withOpacity(0.92),
                                      ),
                                    if (permohonan.statusKeseluruhan ==
                                        StatusPermohonan.proses)
                                      Icon(
                                        Icons.timelapse_rounded,
                                        size: 16,
                                        color: Colors.white.withOpacity(0.92),
                                      ),
                                    const SizedBox(width: 5),
                                    Text(
                                      permohonan.statusKeseluruhan ==
                                              StatusPermohonan.proses
                                          ? (() {
                                              final aktif = permohonan
                                                  .daftarTahapan
                                                  .where((t) => t.isAktif)
                                                  .toList();
                                              return aktif.isNotEmpty
                                                  ? aktif.first.nama
                                                  : 'Proses';
                                            })()
                                          : permohonan.statusKeseluruhan ==
                                                StatusPermohonan.selesai
                                          ? 'SELESAI'
                                          : permohonan.statusKeseluruhan ==
                                                StatusPermohonan.dibatalkan
                                          ? 'DIBATALKAN'
                                          : permohonan.statusKeseluruhan.name
                                                .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(
                            color: Colors.grey.shade100,
                            thickness: 1,
                            height: 1,
                          ),
                          const SizedBox(height: 14),
                          if (permohonan.jenisPermohonan != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: Row(
                                children: [
                                  Text(
                                    'Jenis',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      permohonan.jenisPermohonan!.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                        color: Colors.black87,
                                        letterSpacing: 0.1,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (permohonan.daya != null &&
                              permohonan.daya!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: Row(
                                children: [
                                  Text(
                                    'Daya',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      permohonan.daya!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                        color: Colors.black87,
                                        letterSpacing: 0.1,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (permohonan.prioritas != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: Row(
                                children: [
                                  Text(
                                    'Prioritas',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      permohonan.prioritas!.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                        color: Colors.black87,
                                        letterSpacing: 0.1,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (permohonan.catatanPermohonan != null &&
                              permohonan.catatanPermohonan!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Catatan',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      permohonan.catatanPermohonan!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13.5,
                                        color: Colors.black87,
                                        letterSpacing: 0.05,
                                      ),
                                      textAlign: TextAlign.right,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.timeline,
                                color: Colors.blue.shade400,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Progres Tahapan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.5,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Divider(
                            color: Colors.grey.shade100,
                            thickness: 1,
                            height: 1,
                          ),
                          const SizedBox(height: 2),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: permohonan.daftarTahapan.length,
                            itemBuilder: (context, index) {
                              final tahapan = permohonan.daftarTahapan[index];
                              final isExpandable = !tahapan.isMenunggu;
                              final isExpanded =
                                  tahapan.isAktif &&
                                      (tahapan.formData == null ||
                                          tahapan.formData!.isEmpty)
                                  ? true
                                  : _expandedTahapanIndex == index;
                              final isEditMode = _expandedEditIndex == index;
                              Color dotColor;
                              if (tahapan.status == StatusTahapan.selesai) {
                                dotColor = const Color(0xFF22C55E);
                              } else if (tahapan.isAktif) {
                                dotColor = const Color(0xFFF59E42);
                              } else if (tahapan.status ==
                                  StatusTahapan.menunggu) {
                                dotColor = Colors.grey.shade300;
                              } else {
                                dotColor = Colors.blue.shade300;
                              }

                              return TimelineTile(
                                axis: TimelineAxis.vertical,
                                alignment: TimelineAlign.manual,
                                lineXY: 0.1,
                                isFirst: index == 0,
                                isLast:
                                    index ==
                                    permohonan.daftarTahapan.length - 1,
                                indicatorStyle: IndicatorStyle(
                                  width: 28,
                                  height: 14,
                                  indicatorXY: 0.5,
                                  indicator: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: dotColor,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.only(
                                    top: 18,
                                    bottom: 18,
                                  ),
                                ),
                                beforeLineStyle: LineStyle(
                                  color: Colors.grey.shade300,
                                  thickness: 2,
                                ),
                                afterLineStyle: LineStyle(
                                  color: Colors.grey.shade300,
                                  thickness: 2,
                                ),
                                endChild: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(
                                    left: 12,
                                    right: 0,
                                    top: 6,
                                    bottom: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isExpanded
                                        ? Colors.blue.shade50
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(
                                      color: isExpanded
                                          ? Colors.blue.shade300
                                          : Colors.grey.shade200,
                                      width: isExpanded ? 1.7 : 1.0,
                                    ),
                                    boxShadow: [
                                      if (isExpanded)
                                        BoxShadow(
                                          color: Colors.blue.shade100
                                              .withOpacity(0.13),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(13),
                                        onTap: isExpandable
                                            ? () {
                                                setState(() {
                                                  _expandedTahapanIndex =
                                                      isExpanded ? null : index;
                                                });
                                              }
                                            : null,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 13,
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                tahapan.nama,
                                                style: TextStyle(
                                                  fontWeight: tahapan.isAktif
                                                      ? FontWeight.w700
                                                      : FontWeight.w600,
                                                  fontSize: 14.5,
                                                  color: tahapan.isAktif
                                                      ? Colors.blue.shade700
                                                      : tahapan.status ==
                                                            StatusTahapan
                                                                .selesai
                                                      ? const Color(0xFF22C55E)
                                                      : Colors.grey.shade700,
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 2,
                                                      horizontal: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      tahapan.status ==
                                                          StatusTahapan.selesai
                                                      ? const Color(0xFF22C55E)
                                                      : tahapan.isAktif
                                                      ? const Color(0xFFF59E42)
                                                      : tahapan.status ==
                                                            StatusTahapan
                                                                .menunggu
                                                      ? Colors.grey.shade300
                                                      : Colors.blue.shade300,
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                ),
                                                child: Text(
                                                  tahapan.status ==
                                                          StatusTahapan.selesai
                                                      ? 'Selesai'
                                                      : tahapan.isAktif
                                                      ? 'Aktif'
                                                      : tahapan.status ==
                                                            StatusTahapan
                                                                .menunggu
                                                      ? 'Menunggu'
                                                      : 'Proses',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12.5,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ),
                                              if (isExpandable)
                                                Icon(
                                                  isExpanded
                                                      ? Icons.expand_less
                                                      : Icons.expand_more,
                                                  color: Colors.blue.shade300,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (isExpanded && isExpandable)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                            right: 8,
                                            bottom: 12,
                                            top: 0,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 18,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue.shade100,
                                              width: 1.2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.blue.shade100
                                                    .withOpacity(0.08),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              if (!tahapan.isAktif && canModify)
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            tahapan.formData?['user_update'] ??
                                                                '-',
                                                            style: TextStyle(
                                                              fontSize: 13.5,
                                                              color: Colors
                                                                  .blueGrey
                                                                  .shade700,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            () {
                                                              final raw = tahapan
                                                                  .formData?['tanggal_update'];
                                                              if (raw == null ||
                                                                  raw
                                                                      .toString()
                                                                      .isEmpty) {
                                                                return '-';
                                                              }
                                                              try {
                                                                final dt =
                                                                    DateTime.tryParse(
                                                                      raw.toString(),
                                                                    );
                                                                if (dt !=
                                                                    null) {
                                                                  return DateFormat(
                                                                    'dd MMM yyyy, HH:mm',
                                                                    'id_ID',
                                                                  ).format(dt);
                                                                }
                                                              } catch (_) {}
                                                              return raw
                                                                  .toString();
                                                            }(),
                                                            style: TextStyle(
                                                              fontSize: 12.5,
                                                              color: Colors
                                                                  .blueGrey
                                                                  .shade600,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 8,
                                                            top: 0,
                                                          ),
                                                      child: IconButton(
                                                        icon: const Icon(
                                                          Icons.edit,
                                                          size: 20,
                                                        ),
                                                        color: Colors
                                                            .blue
                                                            .shade700,
                                                        tooltip: 'Edit',
                                                        constraints:
                                                            const BoxConstraints(),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        onPressed: () {
                                                          setState(() {
                                                            _expandedEditIndex =
                                                                index;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (tahapan.isAktif &&
                                                  (tahapan.formData == null ||
                                                      tahapan
                                                          .formData!
                                                          .isEmpty))
                                                _buildCurrentStageForm(
                                                  permohonan,
                                                  tahapan,
                                                )
                                              else if (isEditMode &&
                                                  !tahapan.isAktif)
                                                _buildCurrentStageForm(
                                                  permohonan,
                                                  tahapan.copyWith(
                                                    formData:
                                                        tahapan.formData !=
                                                                null &&
                                                            tahapan
                                                                .formData!
                                                                .isNotEmpty
                                                        ? Map<
                                                            String,
                                                            dynamic
                                                          >.from(
                                                            tahapan.formData!,
                                                          )
                                                        : {},
                                                  ),
                                                )
                                              else
                                                _buildTahapanFormSummary(
                                                  tahapan,
                                                ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
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
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(bgColor),
            ),
          ),
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
