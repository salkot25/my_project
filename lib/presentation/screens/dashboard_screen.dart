import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';
import '../widgets/info_card.dart';
import '../../logic/permohonan_cubit/permohonan_cubit.dart';
import '../../data/models/permohonan_model.dart';

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
              // Dummy vendor (bisa diganti dengan data asli jika ada field vendor)
              final vendorMap = <String, int>{};
              for (var p in list) {
                // Ganti dengan field vendor jika ada, contoh: p.vendor ?? 'Lainnya'
                vendorMap['KAG'] = (vendorMap['KAG'] ?? 0) + 1;
              }
              // Kumpulkan daftar vendor unik (dummy: 'KAG', ganti dengan field vendor jika ada)
              final vendorList = <String>{'Semua Vendor'};
              for (var p in list) {
                // Ganti dengan field vendor jika ada, contoh: p.vendor ?? 'Lainnya'
                vendorList.add('KAG');
              }
              String selectedVendor = 'Semua Vendor';
              return StatefulBuilder(
                builder: (context, setState) {
                  // Filter list berdasarkan vendor jika dipilih
                  final filteredList = selectedVendor == 'Semua Vendor'
                      ? list
                      : list.where((p) => 'KAG' == selectedVendor).toList();
                  // Hitung ulang statistik berdasarkan filteredList
                  final filteredTotal = filteredList.length;
                  final filteredSelesai = filteredList
                      .where(
                        (p) => p.statusKeseluruhan == StatusPermohonan.selesai,
                      )
                      .length;
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
                    filteredVendorMap['KAG'] =
                        (filteredVendorMap['KAG'] ?? 0) + 1;
                  }
                  return ListView(
                    children: [
                      Row(
                        children: [
                          _DashboardCard(
                            icon: Icons.folder,
                            value: filteredTotal.toString(),
                            label: 'Total Proyek',
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 16),
                          _DashboardCard(
                            icon: Icons.check_circle,
                            value: filteredSelesai.toString(),
                            label: 'Selesai',
                            color: Colors.green,
                          ),
                          const SizedBox(width: 16),
                          _DashboardCard(
                            icon: Icons.access_time,
                            value: filteredProses.toString(),
                            label: 'Proses',
                            color: Colors.orange,
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
                                    if (v != null)
                                      setState(() => selectedVendor = v);
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
                      const Text(
                        'Proyek per Vendor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: filteredVendorMap.entries
                            .map(
                              (e) => Chip(
                                avatar: const Icon(
                                  Icons.apartment,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                label: Text('${e.key}: ${e.value}'),
                                backgroundColor: Colors.blue[50],
                              ),
                            )
                            .toList(),
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

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _DashboardCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.only(right: 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
