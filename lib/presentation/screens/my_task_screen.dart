import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../data/models/permohonan_model.dart';
import '../../core/constants/app_stages.dart';
import '../widgets/app_drawer.dart';
import '../widgets/vendor_laporan_jaringan_history.dart';

class MyTaskScreen extends StatefulWidget {
  const MyTaskScreen({super.key});
  static const String routeName = '/my-task';

  @override
  State<MyTaskScreen> createState() => _MyTaskScreenState();
}

class _MyTaskScreenState extends State<MyTaskScreen>
    with WidgetsBindingObserver {
  UserProfileModel? _profile;
  String? _selectedStage;
  List<PermohonanModel> _permohonanList = [];
  bool _loading = true;

  // Tambahkan variabel untuk laporan vendor
  List<Map<String, dynamic>> _vendorReports = [];
  bool _loadingReports = false;

  // Untuk menyimpan snapshot ID permohonan terakhir
  Set<String> _lastPermohonanIds = {};

  // Tahapan yang relevan untuk setiap role
  static const Map<String, List<String>> roleStages = {
    'PP': ['Permohonan', 'MOM', 'Kontrak Rinci'],
    'Teknik': ['Survey Lokasi', 'RAB', 'Jaringan'],
    'TE': ['Pasang APP'],
    'Vendor': ['Jaringan'],
    'Admin': [], // Semua
    'Manager': [], // Semua
  };

  StreamSubscription? _reportsSubscription;

  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _loadProfileAndTasks();
    // _loadVendorReports(); // Removed: will be called after permohonan list is loaded
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _profile?.role == 'Vendor') {
      _loadVendorReports();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _reportsSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _profile?.role == 'Vendor') {
      // Reload vendor reports when app comes back to foreground
      _loadVendorReports();
    }
  }

  Future<void> _loadProfileAndTasks() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final profileMap = await Supabase.instance.client
        .from('profile')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    if (profileMap == null) return;
    final profile = UserProfileModel.fromMap(profileMap);
    setState(() {
      _profile = profile;
    });
    await _loadPermohonanList(profile);
  }

  Future<void> _loadPermohonanList(UserProfileModel profile) async {
    setState(() => _loading = true);
    final data = await Supabase.instance.client.from('permohonan').select();
    final permohonanList = (data as List)
        .map((map) => PermohonanModel.fromMap(map, []))
        .toList();
    // Deteksi tugas/data baru
    final newIds = permohonanList.map((p) => p.id).toSet();
    final addedIds = newIds.difference(_lastPermohonanIds);
    setState(() {
      _permohonanList = permohonanList;
      _loading = false;
      _lastPermohonanIds = newIds;
    });
    // Notifikasi jika ada tugas/data baru
    if (_lastPermohonanIds.isNotEmpty && addedIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ada tugas/data baru di My Task!'),
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
    // Load vendor reports after permohonan list is loaded
    await _loadVendorReports();
  }

  // Method untuk memuat laporan vendor dengan real-time subscription
  Future<void> _loadVendorReports() async {
    if (_profile?.role != 'Vendor') return;
    setState(() => _loadingReports = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _vendorReports = [];
        _loadingReports = false;
      });
      return;
    }
    // Get all permohonan IDs that are in Jaringan stage
    final jaringanPermohonanIds = _permohonanList
        .where((p) => p.tahapanAktif == 'Jaringan')
        .map((p) => p.id)
        .toList();
    if (jaringanPermohonanIds.isEmpty) {
      setState(() {
        _vendorReports = [];
        _loadingReports = false;
      });
      return;
    }
    // Load reports only for permohonan in Jaringan stage
    final reports = await Supabase.instance.client
        .from('vendor_laporan_jaringan')
        .select()
        .eq('user_id', user.id)
        .inFilter('permohonan_id', jaringanPermohonanIds)
        .order('tanggal', ascending: false);
    setState(() {
      _vendorReports = List<Map<String, dynamic>>.from(reports);
      _loadingReports = false;
    });
  }

  List<String> getAvailableStages() {
    if (_profile == null) return [];
    final role = _profile!.role;
    if (role == 'Admin' || role == 'Manager') {
      return alurTahapanDefault;
    }
    return roleStages[role] ?? [];
  }

  List<PermohonanModel> getFilteredPermohonan() {
    if (_profile == null) return [];
    final stages = getAvailableStages();
    if (_selectedStage == null || _selectedStage == 'Semua') {
      // Semua permohonan yang tahap aktifnya ada di stages
      return _permohonanList
          .where((p) => stages.contains(p.tahapanAktif))
          .toList();
    }
    // Filter spesifik tahap
    return _permohonanList
        .where((p) => p.tahapanAktif == _selectedStage)
        .toList();
  }

  // Fungsi untuk mengambil laporan vendor berdasarkan permohonan_id
  Future<List<Map<String, dynamic>>> _fetchLaporanByPermohonan(
    String permohonanId,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    final reports = await Supabase.instance.client
        .from('vendor_laporan_jaringan')
        .select()
        .eq('user_id', user.id)
        .eq('permohonan_id', permohonanId)
        .order('tanggal', ascending: false);
    return List<Map<String, dynamic>>.from(reports);
  }

  // Dialog untuk menampilkan daftar laporan vendor per permohonan
  void _showLaporanListDialog(
    BuildContext parentContext,
    PermohonanModel permohonan,
  ) async {
    showDialog(
      context: parentContext,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: VendorLaporanJaringanHistory(
              permohonanId: permohonan.id,
              namaPelanggan: permohonan.namaPelanggan,
              onLaporanAdded: () async {
                // Refresh laporan dan UI setelah menambah/mengubah laporan
                await _loadVendorReports();
                if (mounted) {
                  setState(() {}); // Memastikan UI diperbarui
                }
                // print(
                //   'DEBUG: Refreshed vendor reports after adding/updating report',
                // );
              },
            ),
          ),
        );
      },
    ).then((_) async {
      // Refresh lagi setelah dialog ditutup untuk memastikan data terbaru
      await _loadVendorReports();
      if (mounted) {
        setState(() {}); // Memastikan UI diperbarui
      }
      // print('DEBUG: Refreshed vendor reports after dialog closed');
    });
  }

  Widget buildVendorTaskLaporan(
    List<PermohonanModel> list, {
    bool hanyaSelesai = false,
  }) {
    final jaringanTasks = list
        .where((p) => p.tahapanAktif == 'Jaringan')
        .where((p) => !hanyaSelesai || (p.statusKeseluruhan.name == 'selesai'))
        .toList();
    if (jaringanTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              hanyaSelesai
                  ? 'Tidak ada pekerjaan jaringan yang sudah selesai.'
                  : 'Tidak ada pekerjaan jaringan yang perlu dilaporkan.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: jaringanTasks.length,
      separatorBuilder: (context, idx) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final p = jaringanTasks[idx];

        // Debug logging untuk troubleshooting
        // Removed debug prints for cleaner output

        // Cari laporan vendor jaringan terbaru untuk permohonan ini
        // Removed debug prints for cleaner output
        final laporanList = _vendorReports.where((r) {
          final reportId = r['permohonan_id'];
          final String pIdCleaned = p.id.toString().trim();
          final String reportIdCleaned = reportId.toString().trim();
          final bool idsMatch = reportIdCleaned == pIdCleaned;
          return idsMatch;
        }).toList();

        Map<String, dynamic>? latestReport;
        if (laporanList.isNotEmpty) {
          // Ambil laporan dengan tanggal terbaru
          laporanList.sort((a, b) {
            final tglA =
                DateTime.tryParse(a['tanggal'] ?? '') ?? DateTime(1970);
            final tglB =
                DateTime.tryParse(b['tanggal'] ?? '') ?? DateTime(1970);
            return tglB.compareTo(tglA);
          });
          latestReport = laporanList.first;
        } else {
          latestReport = null;
        }

        String status = 'Belum Laporan';
        if (latestReport != null && latestReport['status'] != null) {
          status = latestReport['status'];
        }
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
        return Container(
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade50,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade50,
              child: Icon(Icons.cable, color: Colors.green.shade400),
            ),
            title: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                p.namaPelanggan,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timeline,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tahap: Jaringan',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Klik untuk melihat/mengisi laporan pekerjaan jaringan.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toString().toUpperCase(),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () {
              _showLaporanListDialog(context, p);
            },
          ),
        );
      },
    );
  }

  // Widget untuk menampilkan daftar laporan vendor
  Widget buildVendorReportsList() {
    if (_loadingReports) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_vendorReports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Belum ada laporan pekerjaan jaringan yang dikirim.'),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _vendorReports.length,
      separatorBuilder: (c, i) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final r = _vendorReports[idx];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            leading: Icon(Icons.receipt_long, color: Colors.green.shade400),
            title: Text(r['jenis_pekerjaan'] ?? '-'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Perbaikan: Menghilangkan karakter aneh " 9"
                Text('Tanggal: ${r['tanggal'] ?? '-'}'),
                if (r['catatan'] != null && r['catatan'].toString().isNotEmpty)
                  Text('Catatan: ${r['catatan']}'),
                Text(
                  'Siap dipasang APP: '
                  '${(r['siap_pasang_app'] == true) ? 'Ya' : 'Tidak'}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVendor = _profile?.role == 'Vendor';
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Task'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedStage ?? 'Semua',
                items: [
                  const DropdownMenuItem(value: 'Semua', child: Text('Semua')),
                  ...getAvailableStages().map(
                    (t) => DropdownMenuItem(value: t, child: Text(t)),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedStage = val;
                  });
                },
                underline: Container(),
                icon: Icon(Icons.filter_list, color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: MyTaskScreen.routeName),
      body: Focus(
        focusNode: _focusNode,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: isVendor
                          ? buildVendorTaskLaporan(
                              getFilteredPermohonan(),
                              hanyaSelesai: false,
                            )
                          : getFilteredPermohonan().isEmpty
                          ? (_selectedStage == null ||
                                    _selectedStage == 'Semua')
                                ? Center(
                                    child: FractionallySizedBox(
                                      widthFactor: 0.8,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 400,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(32),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.search_off,
                                                size: 64,
                                                color: Colors.grey.shade300,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Tidak ada tugas yang menunggu dikerjakan.',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey.shade600,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(32),
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
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Tidak ada task untuk filter "${_selectedStage ?? ''}"',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                          : ListView.separated(
                              itemCount: getFilteredPermohonan().length,
                              separatorBuilder: (context, idx) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, idx) {
                                final p = getFilteredPermohonan()[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.shade50,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.shade50,
                                      child: Icon(
                                        Icons.assignment_turned_in,
                                        color: Colors.blue.shade400,
                                      ),
                                    ),
                                    title: Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        p.namaPelanggan,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.timeline,
                                            size: 16,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Tahap: ${p.tahapanAktif}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            p.statusKeseluruhan.name ==
                                                'selesai'
                                            ? Colors.green.shade50
                                            : (p.statusKeseluruhan.name ==
                                                      'proses'
                                                  ? Colors.orange.shade50
                                                  : Colors.red.shade50),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        p.statusKeseluruhan.name.toUpperCase(),
                                        style: TextStyle(
                                          color:
                                              p.statusKeseluruhan.name ==
                                                  'selesai'
                                              ? Colors.green
                                              : (p.statusKeseluruhan.name ==
                                                        'proses'
                                                    ? Colors.orange
                                                    : Colors.red),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/permohonan-detail',
                                        arguments: p.id,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
        ),
      ),
    );
  }
}
