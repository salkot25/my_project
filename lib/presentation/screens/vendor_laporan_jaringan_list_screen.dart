import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/vendor_laporan_jaringan_card.dart';
import 'package:intl/intl.dart';

class VendorLaporanJaringanListScreen extends StatefulWidget {
  const VendorLaporanJaringanListScreen({super.key});

  @override
  State<VendorLaporanJaringanListScreen> createState() =>
      _VendorLaporanJaringanListScreenState();
}

class _VendorLaporanJaringanListScreenState
    extends State<VendorLaporanJaringanListScreen> {
  DateTime? selectedDate;
  CalendarFormat calendarFormat = CalendarFormat.week;
  String searchQuery = '';
  late Future<List<Map<String, dynamic>>> _laporanFuture;

  @override
  void initState() {
    super.initState();
    _refreshLaporan();
  }

  void _refreshLaporan() {
    var query = Supabase.instance.client
        .from('vendor_laporan_jaringan')
        .select()
        .order('tanggal', ascending: false);

    // Filter berdasarkan tanggal
    if (selectedDate != null) {
      final start = calendarFormat == CalendarFormat.month
          ? DateTime(selectedDate!.year, selectedDate!.month, 1)
          : DateTime(
              selectedDate!.year,
              selectedDate!.month,
              selectedDate!.day,
            );
      final end = calendarFormat == CalendarFormat.month
          ? DateTime(selectedDate!.year, selectedDate!.month + 1, 1)
          : start.add(const Duration(days: 1));

      query = query.select().order('tanggal', ascending: false);
    }

    _laporanFuture = query.then((data) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Jaringan'),
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
                  future: Supabase.instance.client
                      .from('permohonan')
                      .select('id, nama_pelanggan, alamat')
                      .then((data) {
                        final list = List<Map<String, dynamic>>.from(data);
                        return {for (var p in list) p['id']: p};
                      }),
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
                      future: Supabase.instance.client
                          .from('profile')
                          .select('user_id, username')
                          .inFilter('user_id', userIds)
                          .then((data) {
                            final list = List<Map<String, dynamic>>.from(data);
                            return {
                              for (var u in list)
                                u['user_id']: u['username'] ?? '-',
                            };
                          }),
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
                                : '-';
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
                                Navigator.pushNamed(
                                  context,
                                  '/vendor-laporan-jaringan',
                                  arguments: {
                                    'permohonanId': r['permohonan_id'],
                                    'namaPelanggan': namaPelanggan,
                                  },
                                );
                              },
                              onDelete: () {
                                // Implementasi delete jika diperlukan
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
    );
  }
}
