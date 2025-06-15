import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_drawer.dart';
import '../../logic/permohonan_cubit/permohonan_cubit.dart';
import '../../data/models/permohonan_model.dart';
import 'package:my_project/data/models/tahapan_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_project/data/models/user_model.dart';
import 'package:my_project/presentation/screens/my_task_screen.dart';
import 'package:my_project/presentation/widgets/vendor_laporan_jaringan_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<UserProfileModel?> _getUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    final profileMap = await Supabase.instance.client
        .from('profile')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    if (profileMap == null) return null;
    return UserProfileModel.fromMap(profileMap);
  }

  List<String> _getRoleStages(String role) {
    const Map<String, List<String>> roleStages = {
      'PP': ['Permohonan', 'MOM', 'Kontrak Rinci'],
      'Teknik': ['Survey Lokasi', 'RAB', 'Jaringan'],
      'TE': ['Pasang APP'],
      'Vendor': ['Jaringan'],
      'Admin': [], // Semua
      'Manager': [], // Semua
    };
    return roleStages[role] ?? [];
  }

  void _showMyTasks(
    BuildContext context,
    List<PermohonanModel> permohonanList,
    UserProfileModel profile,
  ) {
    final stages = _getRoleStages(profile.role);
    final filteredTasks = permohonanList
        .where((p) => stages.isEmpty || stages.contains(p.tahapanAktif))
        .toList();

    // Group tasks by stage
    final Map<String, List<PermohonanModel>> groupedTasks = {};
    for (var task in filteredTasks) {
      if (!groupedTasks.containsKey(task.tahapanAktif)) {
        groupedTasks[task.tahapanAktif] = [];
      }
      groupedTasks[task.tahapanAktif]!.add(task);
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.task_alt, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'My Tasks',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: groupedTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No tasks available',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: groupedTasks.length,
                          itemBuilder: (context, index) {
                            final stage = groupedTasks.keys.elementAt(index);
                            final tasks = groupedTasks[stage]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getStageIcon(stage),
                                        size: 20,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        stage,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          tasks.length.toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8),
                                ...tasks.map(
                                  (task) => Card(
                                    margin: EdgeInsets.only(bottom: 8),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.pushNamed(
                                          context,
                                          MyTaskScreen.routeName,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person_outline,
                                                  size: 20,
                                                  color: Colors.grey[600],
                                                ),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    task.namaPelanggan,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_outlined,
                                                  size: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    task.alamat ?? 'No address',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Created: ${_formatDate(task.tanggalPengajuan)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                              ],
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStageIcon(String stage) {
    switch (stage) {
      case 'Permohonan':
        return Icons.description_outlined;
      case 'Survey Lokasi':
        return Icons.location_on_outlined;
      case 'MOM':
        return Icons.assignment_outlined;
      case 'RAB':
        return Icons.attach_money;
      case 'Kontrak Rinci':
        return Icons.gavel_outlined;
      case 'Jaringan':
        return Icons.router_outlined;
      case 'Pasang APP':
        return Icons.power_outlined;
      default:
        return Icons.work_outline;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          BlocBuilder<PermohonanCubit, PermohonanState>(
            builder: (context, state) {
              if (state is PermohonanListLoaded) {
                return FutureBuilder<UserProfileModel?>(
                  future: _getUserProfile(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final profile = snapshot.data!;
                      final stages = _getRoleStages(profile.role);
                      final taskCount = state.permohonanList
                          .where(
                            (p) =>
                                stages.isEmpty ||
                                stages.contains(p.tahapanAktif),
                          )
                          .length;

                      return Stack(
                        children: [
                          IconButton(
                            icon: Icon(Icons.notifications),
                            onPressed: () => _showMyTasks(
                              context,
                              state.permohonanList,
                              profile,
                            ),
                          ),
                          if (taskCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  taskCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    }
                    return SizedBox.shrink();
                  },
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocBuilder<PermohonanCubit, PermohonanState>(
          builder: (context, state) {
            if (state is PermohonanListLoaded) {
              final list = state.permohonanList;
              final total = list.length;
              final selesai = list
                  .where((p) => p.statusKeseluruhan == StatusPermohonan.selesai)
                  .length;
              final proses = list
                  .where((p) => p.statusKeseluruhan == StatusPermohonan.proses)
                  .length;
              // Tahapan
              final tahapNames = [
                'Permohonan',
                'Survey',
                'MOM',
                'RAB & KR',
                'Jaringan',
                'Pasang APP',
                'Selesai',
              ];
              final tahapColors = [
                Colors.lightBlue,
                Colors.cyan,
                Colors.orangeAccent,
                Colors.amber,
                Colors.deepOrange,
                Colors.purple,
                Colors.green,
              ];
              // Hitung jumlah proyek di tiap tahap
              Map<String, int> tahapCount = {for (var t in tahapNames) t: 0};
              for (var p in list) {
                final aktif = p.tahapanAktif;
                if (tahapCount.containsKey(aktif)) {
                  tahapCount[aktif] = tahapCount[aktif]! + 1;
                }
              }
              // Ambil vendor dari tahapan 'Kontrak Rinci' pada setiap permohonan
              Set<String> vendorList = {'Semua Vendor'};
              final vendorMap = <String, int>{};
              for (var p in list) {
                final kontrakTahap = getKontrakTahap(p.daftarTahapan);
                String vendor = 'Lainnya';
                final vendorValue = kontrakTahap?.formData?['vendor'];
                if (vendorValue != null &&
                    vendorValue.toString().trim().isNotEmpty) {
                  vendor = vendorValue.toString().trim();
                }
                vendorList.add(vendor);
                vendorMap[vendor] = (vendorMap[vendor] ?? 0) + 1;
              }
              String selectedVendor = 'Semua Vendor';
              return StatefulBuilder(
                builder: (context, setStateBuilder) {
                  // Filter list berdasarkan vendor jika dipilih
                  final filteredList = selectedVendor == 'Semua Vendor'
                      ? list
                      : list.where((p) {
                          final kontrakTahap = getKontrakTahap(p.daftarTahapan);
                          String vendor = 'Lainnya';
                          final vendorValue = kontrakTahap?.formData?['vendor'];
                          if (vendorValue != null &&
                              vendorValue.toString().trim().isNotEmpty) {
                            vendor = vendorValue.toString().trim();
                          }
                          return vendor == selectedVendor;
                        }).toList();
                  // Hitung ulang statistik berdasarkan filteredList
                  final filteredTotal = filteredList.length;
                  final filteredProses = filteredList
                      .where(
                        (p) => p.statusKeseluruhan == StatusPermohonan.proses,
                      )
                      .length;
                  Map<String, int> filteredTahapCount = {
                    for (var t in tahapNames) t: 0,
                  };
                  for (var p in filteredList) {
                    final aktif = p.tahapanAktif;
                    if (filteredTahapCount.containsKey(aktif)) {
                      filteredTahapCount[aktif] =
                          filteredTahapCount[aktif]! + 1;
                    }
                  }
                  final filteredVendorMap = <String, int>{};
                  for (var p in filteredList) {
                    final kontrakTahap = getKontrakTahap(p.daftarTahapan);
                    String vendor = 'Lainnya';
                    final vendorValue = kontrakTahap?.formData?['vendor'];
                    if (vendorValue != null &&
                        vendorValue.toString().trim().isNotEmpty) {
                      vendor = vendorValue.toString().trim();
                    }
                    filteredVendorMap[vendor] =
                        (filteredVendorMap[vendor] ?? 0) + 1;
                  }
                  final myTaskCount = _getMyTaskCount(list);
                  return ListView(
                    children: [
                      Row(
                        children: [
                          _DashboardCard(
                            icon: Icons.folder,
                            value: filteredTotal.toString(),
                            label: 'Total Project',
                            color: Colors.lightBlue,
                            gradientColors: [
                              Colors.lightBlue.shade300,
                              Colors.lightBlue.shade600,
                            ],
                          ),
                          const SizedBox(width: 16),
                          _DashboardCard(
                            icon: Icons.check_circle,
                            value: myTaskCount.toString(),
                            label: 'My Task',
                            color: Colors.green,
                            gradientColors: [
                              Colors.green.shade300,
                              Colors.green.shade600,
                            ],
                          ),
                          const SizedBox(width: 16),
                          _DashboardCard(
                            icon: Icons.access_time,
                            value: filteredProses.toString(),
                            label: 'Proses',
                            color: Colors.deepOrange,
                            gradientColors: [
                              Colors.deepOrange.shade300,
                              Colors.deepOrange.shade600,
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Statistik Tahap Proyek',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                DropdownButton<String>(
                                  value: selectedVendor,
                                  items: vendorList
                                      .map(
                                        (v) => DropdownMenuItem(
                                          value: v,
                                          child: Text(v),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setStateBuilder(() => selectedVendor = v);
                                    }
                                  },
                                  underline: Container(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(tahapNames.length, (i) {
                              final tahap = tahapNames[i];
                              final color = tahapColors[i];
                              final count = filteredTahapCount[tahap] ?? 0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(width: 90, child: Text(tahap)),
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: filteredTotal == 0
                                            ? 0
                                            : count / filteredTotal,
                                        backgroundColor: color.withOpacity(
                                          0.15,
                                        ),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              color.withOpacity(0.5),
                                            ),
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        '$count Proyek',
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progres Jaringan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/vendor-laporan-jaringan-list',
                              );
                            },
                            child: const Text('Lihat Semua'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: Supabase.instance.client
                            .from('vendor_laporan_jaringan')
                            .select()
                            .order('tanggal', ascending: false)
                            .limit(3),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final laporanList = snapshot.data ?? [];
                          if (laporanList.isEmpty) {
                            return const Center(
                              child: Text('Belum ada laporan jaringan'),
                            );
                          }

                          return FutureBuilder<
                            Map<String, Map<String, dynamic>>
                          >(
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
                                      final list =
                                          List<Map<String, dynamic>>.from(data);
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

                                  return Column(
                                    children: laporanList.map((r) {
                                      final permohonan =
                                          permohonanMap[r['permohonan_id']];
                                      final namaPelanggan = permohonan != null
                                          ? (permohonan['nama_pelanggan'] ??
                                                '-')
                                          : '-';
                                      final alamat = permohonan != null
                                          ? (permohonan['alamat'] ?? '-')
                                          : '-';

                                      String tgl = '-';
                                      if (r['tanggal'] != null &&
                                          r['tanggal'].toString().isNotEmpty) {
                                        try {
                                          final dt = DateTime.parse(
                                            r['tanggal'],
                                          );
                                          tgl =
                                              '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
                                        } catch (_) {
                                          tgl = r['tanggal'].toString();
                                        }
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: VendorLaporanJaringanCard(
                                          jenisPekerjaan:
                                              r['jenis_pekerjaan'] ?? '-',
                                          status: r['status'] ?? '-',
                                          namaPelanggan: namaPelanggan,
                                          alamat: alamat,
                                          tanggal: tgl,
                                          username:
                                              userMap[r['user_id']] ?? '-',
                                          catatan: r['catatan'],
                                          onEdit: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/vendor-laporan-jaringan',
                                              arguments: {
                                                'permohonanId':
                                                    r['permohonan_id'],
                                                'namaPelanggan': namaPelanggan,
                                              },
                                            );
                                          },
                                          onDelete: () {
                                            // Tidak perlu implementasi karena ini hanya preview di dashboard
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            } else if (state is PermohonanLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is PermohonanError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

// Helper to get the 'Kontrak Rinci' stage or null
TahapanModel? getKontrakTahap(List<TahapanModel> tahapanList) {
  for (final t in tahapanList) {
    if (t.nama.toLowerCase().contains('kontrak')) {
      return t;
    }
  }
  return null;
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final List<Color> gradientColors;

  const _DashboardCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        margin: const EdgeInsets.only(right: 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tambahkan fungsi helper di bawah class DashboardScreen
int _getMyTaskCount(List<PermohonanModel> list) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return 0;
  // Asumsi: permohonan yang tahap aktifnya 'Jaringan' dan ada di My Task user (vendor)
  return list.where((p) {
    final jaringanTahap = p.daftarTahapan.firstWhere(
      (t) => t.nama == 'Jaringan',
      orElse: () => const TahapanModel(nama: '', formData: {}),
    );
    final userId = jaringanTahap.formData?['user_id'];
    return p.tahapanAktif == 'Jaringan' && userId == user.id;
  }).length;
}
