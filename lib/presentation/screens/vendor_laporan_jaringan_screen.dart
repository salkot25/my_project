import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/vendor_laporan_jaringan_card.dart';
import 'package:intl/intl.dart';
import 'vendor_laporan_jaringan_detail_screen.dart';

enum JenisPekerjaanJaringan {
  pemasanganTiang('Pemasangan Tiang'),
  pemasanganTrafo('Pemasangan Trafo'),
  perluasanJTR('Perluasan JTR'),
  perluasanJTM('Perluasan JTM'),
  penjumperan('Penjumperan');

  final String label;
  const JenisPekerjaanJaringan(this.label);
}

class VendorLaporanJaringanScreen extends StatefulWidget {
  final String permohonanId;
  final String? namaPelanggan;
  final VoidCallback? onLaporanAdded;

  const VendorLaporanJaringanScreen({
    super.key,
    required this.permohonanId,
    this.namaPelanggan,
    this.onLaporanAdded,
  });

  @override
  State<VendorLaporanJaringanScreen> createState() =>
      _VendorLaporanJaringanScreenState();
}

class _VendorLaporanJaringanScreenState
    extends State<VendorLaporanJaringanScreen> {
  String searchQuery = '';
  DateTime? startDate;
  DateTime? endDate;
  bool sortAscending = false;
  String sortField = 'tanggal';
  late Future<List<Map<String, dynamic>>> _laporanFuture;
  Future<Map<String, Map<String, dynamic>>>? _permohonanMapFuture;

  @override
  void initState() {
    super.initState();
    _refreshLaporan();
  }

  void _refreshLaporan() {
    var query = Supabase.instance.client
        .from('vendor_laporan_jaringan')
        .select()
        .eq('permohonan_id', widget.permohonanId)
        .order(sortField, ascending: sortAscending);

    _laporanFuture = query.then((data) {
      var list = List<Map<String, dynamic>>.from(data);
      // Filter search
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        list = list.where((item) {
          return (item['jenis_pekerjaan']?.toString().toLowerCase().contains(
                    q,
                  ) ??
                  false) ||
              (item['status']?.toString().toLowerCase().contains(q) ?? false) ||
              (item['catatan']?.toString().toLowerCase().contains(q) ?? false);
        }).toList();
      }
      // Filter date range
      if (startDate != null && endDate != null) {
        list = list.where((item) {
          if (item['tanggal'] == null || item['tanggal'].toString().isEmpty)
            return false;
          try {
            final itemDate = DateTime.parse(item['tanggal']);
            final startCompare = DateTime(
              startDate!.year,
              startDate!.month,
              startDate!.day,
            );
            final endCompare = DateTime(
              endDate!.year,
              endDate!.month,
              endDate!.day,
              23,
              59,
              59,
            );
            return !itemDate.isBefore(startCompare) &&
                !itemDate.isAfter(endCompare);
          } catch (_) {
            return false;
          }
        }).toList();
      }
      return list;
    });
    _permohonanMapFuture = Supabase.instance.client
        .from('permohonan')
        .select('id, nama_pelanggan, alamat')
        .eq('id', widget.permohonanId)
        .then((data) {
          final list = List<Map<String, dynamic>>.from(data);
          return {for (var p in list) p['id']: p};
        });
  }

  Future<Map<String, String>> _getUsernamesByIds(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    final data = await Supabase.instance.client
        .from('profile')
        .select('user_id, username')
        .inFilter('user_id', userIds);
    final list = List<Map<String, dynamic>>.from(data);
    return {for (var u in list) u['user_id']: u['username'] ?? '-'};
  }

  void _showTambahLaporanDialog() {
    final jenisPekerjaanController = TextEditingController();
    final catatanController = TextEditingController();
    bool siapPasangApp = false;
    DateTime selectedDateTime = DateTime.now();
    final _formKey = GlobalKey<FormState>();
    JenisPekerjaanJaringan? selectedJenis;

    InputDecoration inputDecoration(String label, IconData icon) =>
        InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF2563EB),
            letterSpacing: 0.1,
          ),
          prefixIcon: Icon(icon, color: Colors.blue.shade400, size: 22),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue.shade100, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
          ),
          fillColor: Colors.blue.shade50.withOpacity(0.18),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade100.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header dengan icon dan gradient
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade200],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.add_circle_outline,
                          size: 38,
                          color: Colors.blue.shade400,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tambah Laporan Jaringan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tanggal
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: DateFormat(
                            'yyyy-MM-dd',
                          ).format(selectedDateTime),
                        ),
                        decoration: inputDecoration(
                          'Tanggal',
                          Icons.calendar_today,
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDateTime,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            selectedDateTime = picked;
                            (context as Element).markNeedsBuild();
                          }
                        },
                        validator: (v) => v == null || v.isEmpty
                            ? 'Tanggal wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      // Jenis pekerjaan
                      DropdownButtonFormField<JenisPekerjaanJaringan>(
                        decoration: inputDecoration(
                          'Jenis Pekerjaan',
                          Icons.work_outline,
                        ),
                        value: selectedJenis,
                        items: JenisPekerjaanJaringan.values.map((jenis) {
                          return DropdownMenuItem(
                            value: jenis,
                            child: Text(jenis.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedJenis = value;
                          jenisPekerjaanController.text = value?.label ?? '';
                        },
                        validator: (v) => (selectedJenis == null)
                            ? 'Jenis pekerjaan wajib dipilih'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      // Catatan
                      TextFormField(
                        controller: catatanController,
                        maxLines: 3,
                        decoration: inputDecoration(
                          'Catatan',
                          Icons.sticky_note_2,
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Catatan wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      // Status/Checkbox
                      Row(
                        children: [
                          StatefulBuilder(
                            builder: (context, setState) => Checkbox(
                              value: siapPasangApp,
                              onChanged: (value) {
                                setState(() {
                                  siapPasangApp = value ?? false;
                                });
                              },
                            ),
                          ),
                          const Text('Siap dipasang APP'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'Batal',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Simpan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade400,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              if (!(_formKey.currentState?.validate() ?? false))
                                return;
                              try {
                                final user =
                                    Supabase.instance.client.auth.currentUser;
                                if (user == null) {
                                  throw Exception('User tidak ditemukan');
                                }
                                await Supabase.instance.client
                                    .from('vendor_laporan_jaringan')
                                    .insert({
                                      'permohonan_id': widget.permohonanId,
                                      'user_id': user.id,
                                      'jenis_pekerjaan':
                                          jenisPekerjaanController.text,
                                      'status': siapPasangApp
                                          ? 'selesai'
                                          : 'proses',
                                      'catatan': catatanController.text,
                                      'siap_pasang_app': siapPasangApp,
                                      'tanggal': DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(selectedDateTime),
                                    });
                                if (mounted) {
                                  Navigator.pop(context);
                                  _refreshLaporan();
                                  if (widget.onLaporanAdded != null) {
                                    widget.onLaporanAdded!();
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Laporan berhasil ditambahkan',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error:  {e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditLaporanDialog(Map<String, dynamic> laporan) {
    final jenisPekerjaanController = TextEditingController(
      text: laporan['jenis_pekerjaan'],
    );
    final catatanController = TextEditingController(text: laporan['catatan']);
    bool siapPasangApp = laporan['siap_pasang_app'] ?? false;
    DateTime selectedDateTime = DateTime.parse(laporan['tanggal']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Laporan Jaringan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd-MM-yyyy HH:mm').format(selectedDateTime),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<JenisPekerjaanJaringan>(
                decoration: const InputDecoration(
                  labelText: 'Jenis Pekerjaan',
                  border: OutlineInputBorder(),
                ),
                value: JenisPekerjaanJaringan.values.firstWhere(
                  (jenis) => jenis.label == laporan['jenis_pekerjaan'],
                  orElse: () => JenisPekerjaanJaringan.pemasanganTiang,
                ),
                items: JenisPekerjaanJaringan.values.map((jenis) {
                  return DropdownMenuItem(
                    value: jenis,
                    child: Text(jenis.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    jenisPekerjaanController.text = value.label;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: catatanController,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: siapPasangApp,
                    onChanged: (value) {
                      siapPasangApp = value ?? false;
                    },
                  ),
                  const Text('Siap dipasang APP'),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await Supabase.instance.client
                        .from('vendor_laporan_jaringan')
                        .update({
                          'jenis_pekerjaan': jenisPekerjaanController.text,
                          'status': siapPasangApp ? 'selesai' : 'proses',
                          'catatan': catatanController.text,
                          'siap_pasang_app': siapPasangApp,
                          'tanggal': selectedDateTime.toIso8601String(),
                        })
                        .eq('id', laporan['id']);

                    if (mounted) {
                      Navigator.pop(context);
                      _refreshLaporan();
                      if (widget.onLaporanAdded != null) {
                        widget.onLaporanAdded!();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Laporan berhasil diperbarui'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> laporan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Laporan'),
        content: const Text('Apakah Anda yakin ingin menghapus laporan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await Supabase.instance.client
                    .from('vendor_laporan_jaringan')
                    .delete()
                    .eq('id', laporan['id']);

                if (mounted) {
                  Navigator.pop(context);
                  _refreshLaporan();
                  if (widget.onLaporanAdded != null) {
                    widget.onLaporanAdded!();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Laporan berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    DateTime? tempStartDate = startDate;
    DateTime? tempEndDate = endDate;
    bool tempSortAscending = sortAscending;
    String tempSortField = sortField;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.15),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gradient header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade100.withOpacity(0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.filter_list,
                          color: Colors.blue.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Filter & Urutkan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date range
                      const Text(
                        'Rentang Tanggal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTimeRange? picked =
                              await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                initialDateRange:
                                    tempStartDate != null && tempEndDate != null
                                    ? DateTimeRange(
                                        start: tempStartDate!,
                                        end: tempEndDate!,
                                      )
                                    : DateTimeRange(
                                        start: DateTime.now().subtract(
                                          const Duration(days: 7),
                                        ),
                                        end: DateTime.now(),
                                      ),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.blue.shade700,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black87,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                          if (picked != null) {
                            setDialogState(() {
                              tempStartDate = picked.start;
                              tempEndDate = picked.end;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(
                              color: Colors.blue.shade100,
                              width: 1.2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  tempStartDate != null && tempEndDate != null
                                      ? '${_formatDate(tempStartDate!)} - ${_formatDate(tempEndDate!)}'
                                      : 'Pilih rentang tanggal',
                                  style: TextStyle(
                                    color:
                                        tempStartDate != null &&
                                            tempEndDate != null
                                        ? Colors.blue.shade900
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.date_range,
                                size: 20,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (tempStartDate != null || tempEndDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                tempStartDate = null;
                                tempEndDate = null;
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Reset Tanggal'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Sorting options
                      const Text(
                        'Urutkan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: tempSortField,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'tanggal',
                                  child: Text('Tanggal'),
                                ),
                                DropdownMenuItem(
                                  value: 'jenis_pekerjaan',
                                  child: Text('Alfabet'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    tempSortField = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {
                              setDialogState(() {
                                tempSortAscending = !tempSortAscending;
                              });
                            },
                            icon: Icon(
                              tempSortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: Colors.blue.shade700,
                            ),
                            tooltip: tempSortAscending
                                ? 'Ascending'
                                : 'Descending',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blueGrey.shade600,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            startDate = tempStartDate;
                            endDate = tempEndDate;
                            sortAscending = tempSortAscending;
                            sortField = tempSortField;
                            _refreshLaporan();
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('Terapkan'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.namaPelanggan ?? 'Laporan Jaringan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Search Field
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari laporan...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.blue.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          searchQuery = val;
                          _refreshLaporan();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter Button (icon only)
                  Material(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showFilterDialog,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Stack(
                          children: [
                            Icon(
                              Icons.filter_list,
                              color: Colors.grey.shade600,
                            ),
                            if (startDate != null ||
                                endDate != null ||
                                sortField != 'tanggal' ||
                                sortAscending)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade700,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _laporanFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final laporanList = snapshot.data ?? [];
                if (laporanList.isEmpty) {
                  return const Center(
                    child: Text('Belum ada laporan jaringan'),
                  );
                }

                return FutureBuilder<Map<String, Map<String, dynamic>>>(
                  future: _permohonanMapFuture,
                  builder: (context, permohonanSnap) {
                    if (permohonanSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final permohonanMap = permohonanSnap.data ?? {};
                    final userIds = laporanList
                        .map((r) => r['user_id']?.toString() ?? '')
                        .where((id) => id.isNotEmpty)
                        .toSet()
                        .toList();

                    return FutureBuilder<Map<String, String>>(
                      future: _getUsernamesByIds(userIds),
                      builder: (context, userSnap) {
                        if (userSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final userMap = userSnap.data ?? {};

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: laporanList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final r = laporanList[index];
                            final permohonan =
                                permohonanMap[r['permohonan_id']];
                            final namaPelanggan = permohonan != null
                                ? (permohonan['nama_pelanggan'] ?? '-')
                                : widget.namaPelanggan ?? '-';
                            final alamat = permohonan != null
                                ? (permohonan['alamat'] ?? '-')
                                : '-';

                            String tgl = '-';
                            if (r['tanggal'] != null &&
                                r['tanggal'].toString().isNotEmpty) {
                              try {
                                final dt = DateTime.parse(r['tanggal']);
                                tgl =
                                    '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
                              } catch (_) {
                                tgl = r['tanggal'].toString();
                              }
                            }

                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      VendorLaporanJaringanDetailDialog(
                                        id: r['id']?.toString() ?? '-',
                                        judul: r['jenis_pekerjaan'] ?? '-',
                                        deskripsi: r['catatan'] ?? '-',
                                        tanggal: tgl,
                                        status: r['status'] ?? '-',
                                        namaPelanggan: namaPelanggan,
                                        alamat: alamat,
                                        permohonanId:
                                            r['permohonan_id']?.toString() ??
                                            '-',
                                        siapPasangApp:
                                            r['siap_pasang_app'] == true,
                                        userId: r['user_id']?.toString(),
                                      ),
                                );
                              },
                              child: VendorLaporanJaringanCard(
                                jenisPekerjaan: r['jenis_pekerjaan'] ?? '-',
                                status: r['status'] ?? '-',
                                namaPelanggan: namaPelanggan,
                                alamat: alamat,
                                tanggal: tgl,
                                username: userMap[r['user_id']] ?? '-',
                                catatan: r['catatan'],
                                onEdit: () {
                                  _showEditLaporanDialog(r);
                                },
                                onDelete: () {
                                  _showDeleteConfirmationDialog(r);
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTambahLaporanDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
