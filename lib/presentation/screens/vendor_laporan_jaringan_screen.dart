import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/vendor_laporan_jaringan_card.dart';
import 'package:intl/intl.dart';

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
  DateTime? selectedDate;
  CalendarFormat calendarFormat = CalendarFormat.week;
  String searchQuery = '';
  late Future<List<Map<String, dynamic>>> _laporanFuture;
  Future<Map<String, Map<String, dynamic>>>? _permohonanMapFuture;
  String? _currentUserId;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _refreshLaporan();
  }

  Future<void> _loadCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
      });

      final profile = await Supabase.instance.client
          .from('profile')
          .select('username')
          .eq('user_id', user.id)
          .single();

      setState(() {
        _currentUsername = profile['username'];
      });
    }
  }

  void _refreshLaporan() {
    var query = Supabase.instance.client
        .from('vendor_laporan_jaringan')
        .select()
        .eq('permohonan_id', widget.permohonanId);

    // Filter berdasarkan tanggal
    if (selectedDate != null) {
      if (calendarFormat == CalendarFormat.month) {
        final start = DateTime(selectedDate!.year, selectedDate!.month, 1);
        final end = DateTime(selectedDate!.year, selectedDate!.month + 1, 1);
        query = query
            .gte('tanggal', start.toIso8601String())
            .lt('tanggal', end.toIso8601String());
      } else {
        final start = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
        );
        final end = start.add(const Duration(days: 1));
        query = query
            .gte('tanggal', start.toIso8601String())
            .lt('tanggal', end.toIso8601String());
      }
    }

    _laporanFuture = query.order('tanggal', ascending: false).then((data) {
      var list = List<Map<String, dynamic>>.from(data);
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
      return list;
    });

    // Ambil data permohonan
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Laporan Jaringan'),
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
                  if (jenisPekerjaanController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Jenis pekerjaan harus diisi'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user == null) {
                      throw Exception('User tidak ditemukan');
                    }

                    await Supabase.instance.client
                        .from('vendor_laporan_jaringan')
                        .insert({
                          'permohonan_id': widget.permohonanId,
                          'user_id': user.id,
                          'jenis_pekerjaan': jenisPekerjaanController.text,
                          'status': siapPasangApp ? 'selesai' : 'proses',
                          'catatan': catatanController.text,
                          'siap_pasang_app': siapPasangApp,
                          'tanggal': selectedDateTime.toIso8601String(),
                        });

                    if (mounted) {
                      Navigator.pop(context);
                      _refreshLaporan();
                      if (widget.onLaporanAdded != null) {
                        widget.onLaporanAdded!();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Laporan berhasil ditambahkan'),
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari laporan...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.blueGrey.shade400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: Icon(
                        calendarFormat == CalendarFormat.month
                            ? Icons.calendar_today
                            : Icons.calendar_today,
                        color: Colors.blue.shade700,
                      ),
                      label: Text(
                        calendarFormat == CalendarFormat.week
                            ? 'Mingguan'
                            : 'Bulanan',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          calendarFormat =
                              calendarFormat == CalendarFormat.month
                              ? CalendarFormat.week
                              : CalendarFormat.month;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TableCalendar(
                  firstDay: DateTime(2000),
                  lastDay: DateTime(2100),
                  focusedDay: selectedDate ?? DateTime.now(),
                  selectedDayPredicate: (day) =>
                      selectedDate != null &&
                      day.year == selectedDate!.year &&
                      day.month == selectedDate!.month &&
                      day.day == selectedDate!.day,
                  onDaySelected: (selected, focused) {
                    setState(() {
                      selectedDate = selected;
                      _refreshLaporan();
                    });
                  },
                  calendarFormat: calendarFormat,
                  onFormatChanged: (format) {
                    setState(() {
                      calendarFormat = format;
                    });
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ],
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

                            return VendorLaporanJaringanCard(
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
