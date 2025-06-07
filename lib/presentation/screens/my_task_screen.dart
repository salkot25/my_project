import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../data/models/permohonan_model.dart';
import '../../core/constants/app_stages.dart';
import '../widgets/app_drawer.dart';

class MyTaskScreen extends StatefulWidget {
  const MyTaskScreen({super.key});
  static const String routeName = '/my-task';

  @override
  State<MyTaskScreen> createState() => _MyTaskScreenState();
}

class _MyTaskScreenState extends State<MyTaskScreen> {
  UserProfileModel? _profile;
  String? _selectedStage;
  List<PermohonanModel> _permohonanList = [];
  bool _loading = true;

  // Tahapan yang relevan untuk setiap role
  static const Map<String, List<String>> roleStages = {
    'PP': ['Permohonan', 'MOM', 'Kontrak Rinci'],
    'Teknik': ['Survey Lokasi', 'RAB', 'Jaringan'],
    'TE': ['Pasang APP'],
    'Vendor': ['Jaringan'],
    'Admin': [], // Semua
    'Manager': [], // Semua
  };

  @override
  void initState() {
    super.initState();
    _loadProfileAndTasks();
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
    setState(() {
      _permohonanList = permohonanList;
      _loading = false;
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

  Widget buildVendorTaskLaporan(List<PermohonanModel> list) {
    final jaringanTasks = list
        .where((p) => p.tahapanAktif == 'Jaringan')
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
              'Tidak ada pekerjaan jaringan yang perlu dilaporkan.',
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
                    'Klik untuk mengisi laporan pekerjaan jaringan.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            trailing: Icon(
              Icons.edit_note,
              color: Colors.green.shade400,
              size: 28,
            ),
            onTap: () {
              // TODO: Navigasi ke form laporan pekerjaan jaringan
              // Navigator.pushNamed(context, '/vendor-laporan', arguments: p.id);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Laporan Pekerjaan Jaringan'),
                  content: const Text(
                    'Form laporan pekerjaan jaringan untuk vendor akan diimplementasikan di sini.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            },
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Hapus statistik tahapan horizontal sementara
                  // Hilangkan SizedBox(height: 24) agar tidak ada jarak ekstra
                  // List Items
                  Expanded(
                    child: isVendor
                        ? buildVendorTaskLaporan(getFilteredPermohonan())
                        : getFilteredPermohonan().isEmpty
                        ? (_selectedStage == null || _selectedStage == 'Semua')
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Tidak ada task untuk filter "${_selectedStage ?? ''}"',
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
                                          p.statusKeseluruhan.name == 'selesai'
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
                ],
              ),
      ),
    );
  }
}
