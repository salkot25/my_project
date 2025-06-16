import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/vendor_laporan_jaringan_card.dart';
import 'vendor_laporan_jaringan_detail_screen.dart';

class VendorLaporanJaringanListScreen extends StatefulWidget {
  const VendorLaporanJaringanListScreen({super.key});

  @override
  State<VendorLaporanJaringanListScreen> createState() =>
      _VendorLaporanJaringanListScreenState();
}

class _VendorLaporanJaringanListScreenState
    extends State<VendorLaporanJaringanListScreen> {
  String searchQuery = '';

  // Filter date range
  DateTime? startDate;
  DateTime? endDate;

  // Sorting options
  bool sortAscending = false;
  String sortField = 'tanggal'; // Default sort by date

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
        .order(sortField, ascending: sortAscending);

    _laporanFuture = query.then((data) {
      var list = List<Map<String, dynamic>>.from(data);

      // Filter berdasarkan pencarian
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

      // Filter berdasarkan rentang tanggal
      if (startDate != null && endDate != null) {
        list = list.where((item) {
          if (item['tanggal'] == null || item['tanggal'].toString().isEmpty) {
            return false;
          }

          try {
            final itemDate = DateTime.parse(item['tanggal']);

            // Check if date is within the range
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

            // Check if the date is within the range (inclusive)
            return !itemDate.isBefore(startCompare) &&
                !itemDate.isAfter(endCompare);
          } catch (_) {
            return false;
          }
        }).toList();
      }

      return list;
    });
  }

  void _showFilterDialog() {
    DateTime? tempStartDate = startDate;
    DateTime? tempEndDate = endDate;
    bool tempSortAscending = sortAscending;
    String tempSortField = sortField;

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
                  color: Colors.blue.shade100.withOpacity(0.18),
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
                            color: Colors.blue.shade50,
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
                              decoration: inputDecoration(
                                'Urutkan',
                                Icons.sort,
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

  String _getActiveFilterText() {
    List<String> filters = []; // Date range filter
    if (startDate != null && endDate != null) {
      filters.add(
        'Periode: ${_formatDate(startDate!)} - ${_formatDate(endDate!)}',
      );
    }

    // Add sort information
    String sortFieldLabel = sortField == 'tanggal'
        ? 'Tanggal'
        : (sortField == 'jenis_pekerjaan' ? 'Jenis Pekerjaan' : 'Status');
    String sortDirection = sortAscending ? '↑' : '↓';
    filters.add('$sortFieldLabel $sortDirection');

    return filters.join(' | ');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Laporan Jaringan'),
            if (startDate != null || endDate != null)
              Text(
                _getActiveFilterText(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.pushNamed(context, '/vendor-laporan-jaringan');
      //   },
      //   backgroundColor: Colors.blue.shade600,
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Filter/Search Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Search Field
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Pencarian',
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
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                            _refreshLaporan();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter Button
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
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _laporanFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Tambahkan fitur refresh
                return RefreshIndicator(
                  onRefresh: () async {
                    _refreshLaporan();
                    setState(() {});
                  },
                  child: Builder(
                    builder: (context) {
                      final laporanList = snapshot.data ?? [];
                      if (laporanList.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.assignment_late_outlined,
                                      size: 80,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      startDate != null || endDate != null
                                          ? 'Tidak ada laporan untuk filter yang dipilih'
                                          : 'Belum ada laporan jaringan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return FutureBuilder<Map<String, Map<String, dynamic>>>(
                        future: Supabase.instance.client
                            .from('permohonan')
                            .select('id, nama_pelanggan, alamat')
                            .then((data) {
                              final list = List<Map<String, dynamic>>.from(
                                data,
                              );
                              return {for (var p in list) p['id']: p};
                            }),
                        builder: (context, permohonanSnap) {
                          if (permohonanSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
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
                                  final list = List<Map<String, dynamic>>.from(
                                    data,
                                  );
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: laporanList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
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

                                  return GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) =>
                                            VendorLaporanJaringanDetailDialog(
                                              id: r['id']?.toString() ?? '-',
                                              judul:
                                                  r['jenis_pekerjaan'] ?? '-',
                                              deskripsi: r['catatan'] ?? '-',
                                              tanggal: tgl,
                                              status: r['status'] ?? '-',
                                              namaPelanggan: namaPelanggan,
                                              alamat: alamat,
                                              permohonanId:
                                                  r['permohonan_id']
                                                      ?.toString() ??
                                                  '-',
                                              siapPasangApp:
                                                  r['siap_pasang_app'] == true,
                                              userId: r['user_id']?.toString(),
                                            ),
                                      );
                                    },
                                    child: VendorLaporanJaringanCard(
                                      jenisPekerjaan:
                                          r['jenis_pekerjaan'] ?? '-',
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
