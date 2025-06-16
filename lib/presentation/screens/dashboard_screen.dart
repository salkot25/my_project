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
import 'package:my_project/core/constants/app_stages.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

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
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade600, Colors.blue.shade500],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_ind_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Tasks',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${filteredTasks.length} tasks available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: groupedTasks.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.task_alt,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'All Caught Up!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No pending tasks at the moment',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: groupedTasks.length,
                        itemBuilder: (context, index) {
                          final stage = groupedTasks.keys.elementAt(index);
                          final tasks = groupedTasks[stage]!;
                          return _ModernTaskGroup(
                            stage: stage,
                            tasks: tasks,
                            stageIcon: _getStageIcon(stage),
                            onTaskTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(
                                context,
                                MyTaskScreen.routeName,
                              );
                            },
                          );
                        },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
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
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data
          context.read<PermohonanCubit>().loadPermohonanList();
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Welcome Header Section - Clean Minimalist Design
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: FutureBuilder<UserProfileModel?>(
                  future: _getUserProfile(),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Clean circular avatar
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.account_circle_outlined,
                                color: Colors.grey.shade500,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // User info with clean typography
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello, ${profile?.username ?? 'User'}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Welcome back to your dashboard',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Role and date info in clean cards
                        Row(
                          children: [
                            if (profile?.role != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade100,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  profile!.role,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_outlined,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_getCurrentDate()} • ${_getCurrentTime()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Dashboard Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: BlocBuilder<PermohonanCubit, PermohonanState>(
                  builder: (context, state) {
                    if (state is PermohonanListLoaded) {
                      final list = state.permohonanList;
                      // Tahapan
                      final tahapNames = List<String>.from(alurTahapanDefault);
                      final tahapColors = [
                        Colors.lightBlue,
                        Colors.cyan,
                        Colors.amber,
                        Colors.orangeAccent,
                        Colors.teal,
                        Colors.amber,
                        Colors.deepOrange,
                        Colors.purple,
                        Colors.green,
                      ];
                      // Hitung jumlah proyek di tiap tahap (mapping sesuai tahapNames)
                      Map<String, int> tahapCount = {
                        for (var t in tahapNames) t: 0,
                      };
                      for (var p in list) {
                        if (p.statusKeseluruhan == StatusPermohonan.selesai) {
                          tahapCount['Selesai'] = tahapCount['Selesai']! + 1;
                        } else if (tahapCount.containsKey(p.tahapanAktif)) {
                          tahapCount[p.tahapanAktif] =
                              tahapCount[p.tahapanAktif]! + 1;
                        }
                      }
                      // Tetapkan vendor yang valid di sistem: KAG dan Armarin
                      final validVendors = {'KAG', 'Armarin'};
                      // Tambahkan opsi "Lainnya" ke dropdown filter vendor
                      Set<String> vendorList = {
                        'Semua Vendor',
                        ...validVendors,
                        'Lainnya',
                      };

                      // Menghitung proyek per vendor
                      final vendorMap = <String, int>{};
                      // Inisialisasi map dengan semua nilai vendor yang valid termasuk "Lainnya"
                      for (String v in validVendors) {
                        vendorMap[v] = 0;
                      }
                      vendorMap['Lainnya'] = 0;

                      // Hitung jumlah proyek per vendor
                      for (var p in list) {
                        final kontrakTahap = getKontrakTahap(p.daftarTahapan);
                        String vendor = 'Lainnya'; // Default vendor

                        if (kontrakTahap != null) {
                          final vendorValue = kontrakTahap.formData?['vendor'];
                          if (vendorValue != null &&
                              vendorValue.toString().trim().isNotEmpty) {
                            String normalizedVendor = vendorValue
                                .toString()
                                .trim();

                            // Pastikan hanya vendor yang valid yang digunakan
                            if (validVendors.contains(normalizedVendor)) {
                              vendor = normalizedVendor;
                            } else {
                              vendor = 'Lainnya';
                            }
                          }
                        }

                        // Tambahkan ke vendor yang sesuai
                        vendorMap[vendor] = (vendorMap[vendor] ?? 0) + 1;
                      }
                      String selectedVendor = 'Semua Vendor';
                      return StatefulBuilder(
                        builder: (context, setStateBuilder) {
                          // Filter list berdasarkan vendor jika dipilih
                          final filteredList = selectedVendor == 'Semua Vendor'
                              ? list
                              : list.where((p) {
                                  final kontrakTahap = getKontrakTahap(
                                    p.daftarTahapan,
                                  );
                                  if (kontrakTahap == null) {
                                    return false; // Skip jika tidak ada data Kontrak Rinci
                                  }

                                  final vendorValue =
                                      kontrakTahap.formData?['vendor'];
                                  if (vendorValue == null) {
                                    return false; // Skip jika tidak ada data vendor
                                  }

                                  final vendor = vendorValue.toString().trim();

                                  // Normalize vendor name to ensure consistency
                                  String normalizedVendor = vendor;
                                  if (validVendors.contains(vendor)) {
                                    normalizedVendor = vendor;
                                  } else {
                                    normalizedVendor = 'Lainnya';
                                  }

                                  // Debug: print normalized vendor value untuk memastikan
                                  print(
                                    'DEBUG: Project ID ${p.id}, Original Vendor: $vendor, Normalized: $normalizedVendor, Selected: $selectedVendor, Match: ${normalizedVendor == selectedVendor}',
                                  );

                                  return normalizedVendor == selectedVendor;
                                }).toList();
                          // Hitung ulang statistik berdasarkan filteredList
                          final filteredTahapCount = <String, int>{};
                          for (var t in tahapNames) {
                            filteredTahapCount[t] = 0;
                          }
                          for (var p in filteredList) {
                            if (p.statusKeseluruhan ==
                                StatusPermohonan.selesai) {
                              filteredTahapCount['Selesai'] =
                                  filteredTahapCount['Selesai']! + 1;
                            } else if (filteredTahapCount.containsKey(
                              p.tahapanAktif,
                            )) {
                              filteredTahapCount[p.tahapanAktif] =
                                  filteredTahapCount[p.tahapanAktif]! + 1;
                            }
                          }
                          // Inisialisasi ulang filteredVendorMap
                          final filteredVendorMap = <String, int>{};
                          for (String v in vendorList) {
                            filteredVendorMap[v] = 0;
                          }

                          // Hitung jumlah proyek per vendor berdasarkan list yang sudah difilter
                          for (var p in filteredList) {
                            final kontrakTahap = getKontrakTahap(
                              p.daftarTahapan,
                            );
                            String vendor = 'Lainnya';

                            if (kontrakTahap != null) {
                              final vendorValue =
                                  kontrakTahap.formData?['vendor'];
                              if (vendorValue != null &&
                                  vendorValue.toString().trim().isNotEmpty) {
                                String v = vendorValue.toString().trim();
                                // Pastikan hanya vendor yang valid
                                if (validVendors.contains(v)) {
                                  vendor = v;
                                } else {
                                  vendor = 'Lainnya';
                                }
                              }
                            }

                            // Tambahkan hanya jika kunci valid dalam map
                            if (filteredVendorMap.containsKey(vendor)) {
                              filteredVendorMap[vendor] =
                                  (filteredVendorMap[vendor] ?? 0) + 1;
                            }
                          }
                          return Column(
                            children: [
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
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.bar_chart,
                                            color: Colors.blue.shade600,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Statistik Tahap Proyek',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Animated Horizontal Bar Chart
                                    ...List.generate(tahapNames.length, (i) {
                                      final tahap = tahapNames[i];
                                      final color = tahapColors[i];
                                      final count = tahapCount[tahap] ?? 0;
                                      final percentage = list.isEmpty
                                          ? 0.0
                                          : (count / list.length);

                                      return _AnimatedHorizontalBar(
                                        label: tahap,
                                        count: count,
                                        percentage: percentage,
                                        color: color,
                                        icon: _getStageIcon(tahap),
                                        delay: Duration(milliseconds: i * 150),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Quick Actions Section
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.flash_on,
                                            color: Colors.green.shade600,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Aksi Cepat',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _QuickActionCard(
                                            icon: Icons.add_circle_outline,
                                            title: 'Tambah Permohonan',
                                            subtitle: 'Buat permohonan baru',
                                            color: Colors.blue,
                                            onTap: () {
                                              Navigator.pushNamed(context, '/');
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _QuickActionCard(
                                            icon: Icons.list_alt,
                                            title: 'Lihat Semua',
                                            subtitle: 'Daftar permohonan',
                                            color: Colors.orange,
                                            onTap: () {
                                              Navigator.pushNamed(context, '/');
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _QuickActionCard(
                                            icon: Icons.assignment,
                                            title: 'My Tasks',
                                            subtitle: 'Tugas saya',
                                            color: Colors.green,
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/my-task',
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _QuickActionCard(
                                            icon: Icons.cable,
                                            title: 'Laporan Jaringan',
                                            subtitle: 'Vendor reports',
                                            color: Colors.purple,
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/vendor-laporan-jaringan-list',
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                          final list =
                                              List<Map<String, dynamic>>.from(
                                                data,
                                              );
                                          return {
                                            for (var p in list) p['id']: p,
                                          };
                                        }),
                                    builder: (context, permohonanSnap) {
                                      if (permohonanSnap.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      final permohonanMap =
                                          permohonanSnap.data ?? {};
                                      final userIds = laporanList
                                          .map(
                                            (r) =>
                                                r['user_id']?.toString() ?? '',
                                          )
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
                                                  List<
                                                    Map<String, dynamic>
                                                  >.from(data);
                                              return {
                                                for (var u in list)
                                                  u['user_id']:
                                                      u['username'] ?? '-',
                                              };
                                            }),
                                        builder: (context, userSnap) {
                                          if (userSnap.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }

                                          final userMap = userSnap.data ?? {};

                                          return Column(
                                            children: laporanList.map((r) {
                                              final permohonan =
                                                  permohonanMap[r['permohonan_id']];
                                              final namaPelanggan =
                                                  permohonan != null
                                                  ? (permohonan['nama_pelanggan'] ??
                                                        '-')
                                                  : '-';
                                              final alamat = permohonan != null
                                                  ? (permohonan['alamat'] ??
                                                        '-')
                                                  : '-';

                                              String tgl = '-';
                                              if (r['tanggal'] != null &&
                                                  r['tanggal']
                                                      .toString()
                                                      .isNotEmpty) {
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
                                                      r['jenis_pekerjaan'] ??
                                                      '-',
                                                  status: r['status'] ?? '-',
                                                  namaPelanggan: namaPelanggan,
                                                  alamat: alamat,
                                                  tanggal: tgl,
                                                  username:
                                                      userMap[r['user_id']] ??
                                                      '-',
                                                  catatan: r['catatan'],
                                                  onEdit: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/vendor-laporan-jaringan',
                                                      arguments: {
                                                        'permohonanId':
                                                            r['permohonan_id'],
                                                        'namaPelanggan':
                                                            namaPelanggan,
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
                              const SizedBox(
                                height: 32,
                              ), // Bottom padding for better spacing
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
            ],
          ),
        ),
      ),
    );
  }
}

// Helper to get the 'Kontrak Rinci' stage or null
TahapanModel? getKontrakTahap(List<TahapanModel> tahapanList) {
  // Cari tahapan yang memiliki nama "Kontrak Rinci" yang eksak
  for (final t in tahapanList) {
    if (t.nama == 'Kontrak Rinci') {
      return t;
    }
  }

  // Fallback ke pencarian yang lebih longgar jika tidak ditemukan
  for (final t in tahapanList) {
    if (t.nama.toLowerCase().contains('kontrak')) {
      return t;
    }
  }
  return null;
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedHorizontalBar extends StatefulWidget {
  final String label;
  final int count;
  final double percentage;
  final Color color;
  final IconData icon;
  final Duration delay;

  const _AnimatedHorizontalBar({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
    required this.icon,
    required this.delay,
  });

  @override
  State<_AnimatedHorizontalBar> createState() => _AnimatedHorizontalBarState();
}

class _AnimatedHorizontalBarState extends State<_AnimatedHorizontalBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: widget.percentage)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Start animation with delay
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.color.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 16),
                ),
                const SizedBox(width: 12),
                // Label
                SizedBox(
                  width: 80,
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Progress bar
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.color,
                              widget.color.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Count and percentage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.count}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                      ),
                    ),
                    Text(
                      '${(_progressAnimation.value * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModernTaskGroup extends StatelessWidget {
  final String stage;
  final List<PermohonanModel> tasks;
  final IconData stageIcon;
  final VoidCallback onTaskTap;

  const _ModernTaskGroup({
    required this.stage,
    required this.tasks,
    required this.stageIcon,
    required this.onTaskTap,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stage Header with Modern Design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade50.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(stageIcon, size: 18, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stage,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Task Cards
          ...tasks.map(
            (task) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTaskTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Name with Icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                task.namaPelanggan,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Address
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.alamat ?? 'No address provided',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Date
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Created: ${_formatDate(task.tanggalPengajuan)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
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
          ),
        ],
      ),
    );
  }
}
