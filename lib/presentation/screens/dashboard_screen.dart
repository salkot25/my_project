import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_drawer.dart';
import '../../logic/permohonan_cubit/permohonan_cubit.dart';
import '../../data/models/permohonan_model.dart';
import 'package:my_project/data/models/tahapan_model.dart';
import 'package:my_project/presentation/widgets/vendor_laporan_jaringan_history_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
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
                                '/vendor-laporan-jaringan',
                              );
                            },
                            child: const Text('Lihat Semua'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      VendorLaporanJaringanHistoryList(maxItems: 3),
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
