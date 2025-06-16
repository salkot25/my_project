import 'package:flutter/material.dart';
import 'package:my_project/core/data/update_vendor_laporan_jaringan.dart';

class VendorLaporanJaringanDetailDialog extends StatefulWidget {
  final String id; // UUID laporan jaringan
  final String judul;
  final String deskripsi;
  final String tanggal;
  final String status;
  final String namaPelanggan;
  final String alamat;
  final String permohonanId;
  final String? userId;
  final bool siapPasangApp;
  final void Function({
    required String judul,
    required String deskripsi,
    required String tanggal,
    required String status,
    required bool siapPasangApp,
  })?
  onSave;

  const VendorLaporanJaringanDetailDialog({
    super.key,
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.tanggal,
    required this.status,
    required this.namaPelanggan,
    required this.alamat,
    required this.permohonanId,
    required this.siapPasangApp,
    this.userId,
    this.onSave,
  });

  @override
  State<VendorLaporanJaringanDetailDialog> createState() =>
      _VendorLaporanJaringanDetailDialogState();
}

class _VendorLaporanJaringanDetailDialogState
    extends State<VendorLaporanJaringanDetailDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late bool isEdit;
  late TextEditingController judulController;
  late TextEditingController deskripsiController;
  late TextEditingController tanggalController;
  late TextEditingController statusController;
  bool siapPasangApp = false;

  @override
  void initState() {
    super.initState();
    isEdit = false;
    judulController = TextEditingController(text: widget.judul);
    deskripsiController = TextEditingController(text: widget.deskripsi);
    tanggalController = TextEditingController(text: widget.tanggal);
    statusController = TextEditingController(text: widget.status);
    siapPasangApp = widget.siapPasangApp;
  }

  void resetFields() {
    judulController.text = widget.judul;
    deskripsiController.text = widget.deskripsi;
    tanggalController.text = widget.tanggal;
    statusController.text = widget.status;
    siapPasangApp = widget.siapPasangApp;
  }

  void updateFieldsFromEdit() {
    // Sinkronkan checkbox dengan statusController
    siapPasangApp = statusController.text.toLowerCase() == 'selesai';
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'proses':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final statusValue = isEdit ? statusController.text : widget.status;
    return Dialog(
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
                        Icons.assignment_turned_in_rounded,
                        size: 38,
                        color: Colors.blue.shade400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Detail Laporan Jaringan',
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
                    // Badge status dan tombol edit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(
                              statusValue,
                            ).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: getStatusColor(statusValue),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusValue.toUpperCase(),
                                style: TextStyle(
                                  color: getStatusColor(statusValue),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isEdit)
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blueAccent,
                            ),
                            tooltip: 'Edit',
                            onPressed: () {
                              setState(() {
                                isEdit = true;
                                updateFieldsFromEdit();
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Nama pelanggan
                    TextFormField(
                      initialValue: widget.namaPelanggan,
                      readOnly: true,
                      decoration: inputDecoration(
                        'Nama Pelanggan',
                        Icons.person,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Alamat
                    TextFormField(
                      initialValue: widget.alamat,
                      readOnly: true,
                      maxLines: 2,
                      decoration: inputDecoration('Alamat', Icons.location_on),
                    ),
                    const SizedBox(height: 14),
                    // Tanggal
                    TextFormField(
                      controller: tanggalController,
                      readOnly: true,
                      decoration: inputDecoration(
                        'Tanggal',
                        Icons.calendar_today,
                      ),
                      onTap: isEdit
                          ? () async {
                              final initialDate =
                                  tanggalController.text.isNotEmpty
                                  ? DateTime.tryParse(tanggalController.text) ??
                                        DateTime.now()
                                  : DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: initialDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  tanggalController.text =
                                      '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                });
                              }
                            }
                          : null,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Tanggal wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    // Jenis pekerjaan
                    DropdownButtonFormField<String>(
                      value: judulController.text.isNotEmpty
                          ? judulController.text
                          : null,
                      items: const [
                        DropdownMenuItem(
                          value: 'Pemasangan Tiang',
                          child: Text('Pemasangan Tiang'),
                        ),
                        DropdownMenuItem(
                          value: 'Pemasangan Trafo',
                          child: Text('Pemasangan Trafo'),
                        ),
                        DropdownMenuItem(
                          value: 'Perluasan JTR',
                          child: Text('Perluasan JTR'),
                        ),
                        DropdownMenuItem(
                          value: 'Perluasan JTM',
                          child: Text('Perluasan JTM'),
                        ),
                        DropdownMenuItem(
                          value: 'Penjumperan',
                          child: Text('Penjumperan'),
                        ),
                      ],
                      onChanged: isEdit
                          ? (val) {
                              setState(() {
                                judulController.text = val ?? '';
                              });
                            }
                          : null,
                      decoration: inputDecoration(
                        'Jenis Pekerjaan',
                        Icons.work_outline,
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Jenis pekerjaan wajib dipilih'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    // Catatan
                    TextFormField(
                      controller: deskripsiController,
                      readOnly: !isEdit,
                      maxLines: 3,
                      decoration: inputDecoration(
                        'Catatan',
                        Icons.sticky_note_2,
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Catatan wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    // Status
                    if (isEdit) ...[
                      Row(
                        children: [
                          Checkbox(
                            value: siapPasangApp,
                            onChanged: (value) {
                              setState(() {
                                siapPasangApp = value ?? false;
                                statusController.text = siapPasangApp
                                    ? 'selesai'
                                    : 'proses';
                              });
                            },
                          ),
                          const Text('Siap dipasang APP'),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Checkbox(
                            value:
                                statusController.text.toLowerCase() ==
                                'selesai',
                            onChanged: null,
                          ),
                          const Text('Siap dipasang APP'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (isEdit)
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
                              setState(() {
                                isEdit = false;
                                resetFields();
                              });
                            },
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
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
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      try {
                                        // Konversi tanggal ke ISO8601 yyyy-MM-dd jika perlu
                                        String tanggalIso;
                                        final t = tanggalController.text.trim();
                                        if (RegExp(
                                          r'^\d{2}-\d{2}-\d{4}\$',
                                        ).hasMatch(t)) {
                                          // Format dd-MM-yyyy
                                          final parts = t.split('-');
                                          tanggalIso =
                                              '${parts[2]}-${parts[1]}-${parts[0]}';
                                        } else {
                                          tanggalIso = t;
                                        }
                                        await updateVendorLaporanJaringan(
                                          id: widget.id,
                                          judul: judulController.text,
                                          deskripsi: deskripsiController.text,
                                          tanggal: tanggalIso,
                                          status: statusController.text,
                                          siapPasangApp: siapPasangApp,
                                          permohonanId: widget.permohonanId,
                                          userId: widget.userId,
                                        );
                                        if (widget.onSave != null) {
                                          widget.onSave!(
                                            judul: judulController.text,
                                            deskripsi: deskripsiController.text,
                                            tanggal: tanggalController.text,
                                            status: statusController.text,
                                            siapPasangApp: siapPasangApp,
                                          );
                                        }
                                        setState(() {
                                          isEdit = false;
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Berhasil disimpan!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Gagal menyimpan: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      } finally {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    }
                                  },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Tombol close di bawah
              if (!isEdit)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Tutup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cara memanggil popup ini dari mana saja:
/// showDialog(
///   context: context,
///   builder: (_) => VendorLaporanJaringanDetailDialog(
///     judul: 'Judul',
///     deskripsi: 'Deskripsi laporan ...',
///     tanggal: '16-06-2025',
///     status: 'proses',
///     namaPelanggan: 'Nama',
///     alamat: 'Alamat',
///     permohonanId: '123',
///   ),
/// );
