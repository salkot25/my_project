import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VendorLaporanJaringanHistoryList extends StatefulWidget {
  final int? maxItems;
  final DateTime? selectedDate;
  final bool isMonthly;
  final String searchQuery;
  const VendorLaporanJaringanHistoryList({
    super.key,
    this.maxItems,
    this.selectedDate,
    this.isMonthly = false,
    this.searchQuery = '',
  });

  @override
  State<VendorLaporanJaringanHistoryList> createState() =>
      _VendorLaporanJaringanHistoryListState();
}

class _VendorLaporanJaringanHistoryListState
    extends State<VendorLaporanJaringanHistoryList> {
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
        .select();
    if (widget.selectedDate != null) {
      if (widget.isMonthly) {
        final start = DateTime(
          widget.selectedDate!.year,
          widget.selectedDate!.month,
          1,
        );
        final end = DateTime(
          widget.selectedDate!.year,
          widget.selectedDate!.month + 1,
          1,
        );
        query = query
            .gte('tanggal', start.toIso8601String())
            .lt('tanggal', end.toIso8601String());
      } else {
        final start = DateTime(
          widget.selectedDate!.year,
          widget.selectedDate!.month,
          widget.selectedDate!.day,
        );
        final end = start.add(const Duration(days: 1));
        query = query
            .gte('tanggal', start.toIso8601String())
            .lt('tanggal', end.toIso8601String());
      }
    }
    _laporanFuture = query.order('tanggal', ascending: false).then((data) {
      var list = List<Map<String, dynamic>>.from(data);
      if (widget.searchQuery.isNotEmpty) {
        final q = widget.searchQuery.toLowerCase();
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
    // Ambil semua permohonan (id, nama_pelanggan, alamat)
    _permohonanMapFuture = Supabase.instance.client
        .from('permohonan')
        .select('id, nama_pelanggan, alamat')
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

  @override
  void didUpdateWidget(covariant VendorLaporanJaringanHistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.isMonthly != widget.isMonthly ||
        oldWidget.searchQuery != widget.searchQuery) {
      _refreshLaporan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _laporanFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var laporanList = snapshot.data ?? [];
        if (widget.maxItems != null && laporanList.length > widget.maxItems!) {
          laporanList = laporanList.sublist(0, widget.maxItems!);
        }
        if (laporanList.isEmpty) {
          return const Text('Belum ada laporan jaringan yang dikirim.');
        }
        // Ambil data permohonan
        return FutureBuilder<Map<String, Map<String, dynamic>>>(
          future: _permohonanMapFuture,
          builder: (context, permohonanSnap) {
            if (permohonanSnap.connectionState == ConnectionState.waiting ||
                _permohonanMapFuture == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final permohonanMap = permohonanSnap.data ?? {};
            // Ambil semua user_id unik dari laporan
            final userIds = laporanList
                .map((r) => r['user_id']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toSet()
                .toList();
            return FutureBuilder<Map<String, String>>(
              future: _getUsernamesByIds(userIds),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final userMap = userSnap.data ?? {};
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: laporanList.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final r = laporanList[idx];
                    final permohonan = permohonanMap[r['permohonan_id']];
                    final namaPelanggan = permohonan != null
                        ? (permohonan['nama_pelanggan'] ?? '-')
                        : '-';
                    final alamat = permohonan != null
                        ? (permohonan['alamat'] ?? '-')
                        : '-';
                    // Format tanggal
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
                    // Status
                    String status = (r['status'] ?? '')
                        .toString()
                        .toLowerCase();
                    Color badgeColor;
                    Color textColor;
                    if (status == 'selesai') {
                      badgeColor = Colors.green.shade50;
                      textColor = Colors.green;
                    } else if (status == 'proses') {
                      badgeColor = Colors.orange.shade50;
                      textColor = Colors.orange;
                    } else {
                      badgeColor = Colors.red.shade50;
                      textColor = Colors.red;
                    }
                    final username = userMap[r['user_id']] ?? '-';
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade50,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.blue.shade100,
                          width: 1.1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Container(
                          //   decoration: BoxDecoration(
                          //     color: Colors.blue.shade50,
                          //     borderRadius: BorderRadius.circular(12),
                          //   ),
                          // padding: const EdgeInsets.all(12),
                          // child: Icon(
                          //   Icons.receipt_long,
                          //   color: Colors.blue.shade400,
                          //   size: 28,
                          // ),
                          // ),
                          // const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r['jenis_pekerjaan'] ?? '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF2563EB),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badgeColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status.isNotEmpty
                                            ? status.toUpperCase()
                                            : '-',
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  namaPelanggan,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  alamat,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 15,
                                            color: Colors.blueGrey.shade400,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            tgl,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blueGrey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 15,
                                            color: Colors.blueGrey.shade400,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            username,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blueGrey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (r['catatan'] != null &&
                                        r['catatan'].toString().isNotEmpty) ...[
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.yellow.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.sticky_note_2,
                                                size: 15,
                                                color: Colors.amber.shade700,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  r['catatan'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.amber.shade800,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
