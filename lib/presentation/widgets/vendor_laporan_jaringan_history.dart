import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vendor_laporan_jaringan_form.dart';

class VendorLaporanJaringanHistory extends StatefulWidget {
  final String permohonanId;
  final String namaPelanggan;
  final VoidCallback? onLaporanAdded;
  const VendorLaporanJaringanHistory({
    super.key,
    required this.permohonanId,
    required this.namaPelanggan,
    this.onLaporanAdded,
  });

  @override
  State<VendorLaporanJaringanHistory> createState() =>
      _VendorLaporanJaringanHistoryState();
}

class _VendorLaporanJaringanHistoryState
    extends State<VendorLaporanJaringanHistory> {
  late Future<List<Map<String, dynamic>>> _laporanFuture;

  @override
  void initState() {
    super.initState();
    _refreshLaporan();
  }

  void _refreshLaporan() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _laporanFuture = Future.value([]);
    } else {
      _laporanFuture = Supabase.instance.client
          .from('vendor_laporan_jaringan')
          .select()
          .eq('user_id', user.id)
          .eq('permohonan_id', widget.permohonanId)
          .order('tanggal', ascending: false)
          .then((data) => List<Map<String, dynamic>>.from(data));
    }
  }

  void _showTambahLaporanDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (formContext) => AlertDialog(
        title: const Text('Tambah Laporan Jaringan'),
        content: VendorLaporanJaringanForm(
          onSubmit: (data) async {
            Navigator.pop(formContext);
            try {
              final dataToSend = Map<String, dynamic>.from(data);
              if (dataToSend['tanggal'] is DateTime) {
                dataToSend['tanggal'] = (dataToSend['tanggal'] as DateTime)
                    .toIso8601String()
                    .substring(0, 10);
              }
              dataToSend['permohonan_id'] = widget.permohonanId;
              // Set status_selesai jika siap_pasang_app == true
              if (dataToSend['siap_pasang_app'] == true) {
                dataToSend['status'] = 'selesai';
              } else {
                dataToSend['status'] = 'proses';
              }
              await Supabase.instance.client
                  .from('vendor_laporan_jaringan')
                  .insert(dataToSend);
              if (mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('Laporan berhasil dikirim!')),
                );
                setState(() {
                  _refreshLaporan(); // assign future baru agar FutureBuilder rebuild
                });
                widget.onLaporanAdded?.call();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text('Gagal mengirim laporan: $e')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _showEditLaporanDialog(
    BuildContext parentContext,
    Map<String, dynamic> laporan,
  ) {
    showDialog(
      context: parentContext,
      builder: (formContext) => AlertDialog(
        title: const Text('Edit Laporan Jaringan'),
        content: VendorLaporanJaringanForm(
          onSubmit: (data) async {
            Navigator.pop(formContext);
            try {
              final dataToSend = Map<String, dynamic>.from(data);
              if (dataToSend['tanggal'] is DateTime) {
                dataToSend['tanggal'] = (dataToSend['tanggal'] as DateTime)
                    .toIso8601String();
              }
              dataToSend['permohonan_id'] = widget.permohonanId;
              if (dataToSend['siap_pasang_app'] == true) {
                dataToSend['status'] = 'selesai';
              } else {
                dataToSend['status'] = 'proses';
              }
              await Supabase.instance.client
                  .from('vendor_laporan_jaringan')
                  .update(dataToSend)
                  .eq('id', laporan['id']);
              if (mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('Laporan berhasil diupdate!')),
                );
                setState(() {
                  _refreshLaporan();
                });
                widget.onLaporanAdded?.call();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text('Gagal update laporan: $e')),
                );
              }
            }
          },
          key: ValueKey('edit-${laporan['id']}'),
          initialValues: laporan,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header mirip form tambah permohonan
        Container(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade100.withOpacity(0.13),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.receipt_long,
                        color: Color(0xFF22C55E),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laporan Pekerjaan Jaringan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey.shade800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.namaPelanggan,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(fontSize: 14),
                      elevation: 0,
                      backgroundColor: Colors.green.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _showTambahLaporanDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(thickness: 1, color: Color(0xFFF1F5F9)),
            ],
          ),
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _laporanFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final laporanList = snapshot.data ?? [];
            if (laporanList.isEmpty) {
              return const Text('Belum ada laporan untuk pekerjaan ini.');
            }
            return Expanded(
              child: ListView.separated(
                itemCount: laporanList.length,
                separatorBuilder: (c, i) => const SizedBox(height: 8),
                itemBuilder: (c, idx) {
                  final r = laporanList[idx];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 1,
                    child: ListTile(
                      leading: Icon(
                        Icons.receipt_long,
                        color: Colors.green.shade400,
                      ),
                      title: Text(r['jenis_pekerjaan'] ?? '-'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tanggal dan waktu
                          Builder(
                            builder: (context) {
                              String tgl = '-';
                              String jam = '';
                              if (r['tanggal'] != null &&
                                  r['tanggal'].toString().isNotEmpty) {
                                try {
                                  final dt = DateTime.parse(r['tanggal']);
                                  tgl =
                                      '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
                                  // Tampilkan jam hanya jika tidak 00:00
                                  if (dt.hour != 0 || dt.minute != 0) {
                                    jam =
                                        ' ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                  } else {
                                    jam = '';
                                  }
                                } catch (_) {
                                  tgl = r['tanggal'].toString();
                                }
                              }
                              return Text('Tanggal: $tgl$jam');
                            },
                          ),
                          if (r['catatan'] != null &&
                              r['catatan'].toString().isNotEmpty)
                            Text('Catatan: ${r['catatan']}'),
                          Text(
                            'Siap dipasang APP: '
                            '${(r['siap_pasang_app'] == true) ? 'Ya' : 'Tidak'}',
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (r['status'] == 'selesai')
                                  ? Colors.green.shade50
                                  : (r['status'] == 'proses')
                                  ? Colors.orange.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (r['status'] ?? '-').toString().toUpperCase(),
                              style: TextStyle(
                                color: (r['status'] == 'selesai')
                                    ? Colors.green
                                    : (r['status'] == 'proses')
                                    ? Colors.orange
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blue,
                              size: 20,
                            ),
                            tooltip: 'Edit Laporan',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (formContext) => AlertDialog(
                                  title: const Text('Edit Laporan Jaringan'),
                                  content: VendorLaporanJaringanForm(
                                    initialValues: {
                                      'tanggal': r['tanggal'],
                                      'jenis_pekerjaan': r['jenis_pekerjaan'],
                                      'catatan': r['catatan'],
                                      'siap_pasang_app': r['siap_pasang_app'],
                                    },
                                    onSubmit: (data) async {
                                      Navigator.pop(formContext);
                                      try {
                                        final dataToSend =
                                            Map<String, dynamic>.from(data);
                                        if (dataToSend['tanggal'] is DateTime) {
                                          dataToSend['tanggal'] =
                                              (dataToSend['tanggal']
                                                      as DateTime)
                                                  .toIso8601String();
                                        }
                                        // Set status_selesai jika siap_pasang_app == true
                                        if (dataToSend['siap_pasang_app'] ==
                                            true) {
                                          dataToSend['status'] = 'selesai';
                                        } else {
                                          dataToSend['status'] = 'proses';
                                        }
                                        await Supabase.instance.client
                                            .from('vendor_laporan_jaringan')
                                            .update(dataToSend)
                                            .eq('id', r['id']);
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Laporan berhasil diupdate!',
                                              ),
                                            ),
                                          );
                                          setState(() {
                                            _refreshLaporan();
                                          });
                                          widget.onLaporanAdded?.call();
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Gagal update laporan: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
