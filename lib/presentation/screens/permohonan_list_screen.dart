import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/permohonan_cubit/permohonan_cubit.dart';
import '../widgets/permohonan_list_tile.dart';
import '../widgets/app_drawer.dart';
import '../../app.dart';
import './permohonan_detail_screen.dart';
import '../../data/models/permohonan_model.dart';
import '../widgets/forms/form_permohonan_widget.dart';

class PermohonanListScreen extends StatefulWidget {
  const PermohonanListScreen({super.key});

  static const String routeName = '/';

  @override
  State<PermohonanListScreen> createState() => _PermohonanListScreenState();
}

class _PermohonanListScreenState extends State<PermohonanListScreen>
    with RouteAware {
  String selectedFilter = 'Semua';
  String searchQuery = '';
  final List<String> filterOptions = [
    'Semua',
    'Proses',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          context.read<PermohonanCubit>().state is PermohonanInitial) {
        context.read<PermohonanCubit>().loadPermohonanList();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route as PageRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // print("PermohonanListScreen: didPopNext - Memuat ulang daftar permohonan");
    context.read<PermohonanCubit>().loadPermohonanList();
  }

  void _showAddPermohonanDialog(BuildContext context) {
    final PermohonanModel dummyPermohonan = PermohonanModel(
      id: '',
      namaPelanggan: '',
      tanggalPengajuan: DateTime.now(),
      statusKeseluruhan: StatusPermohonan.proses,
      daftarTahapan: const [],
    );
    final TextEditingController namaController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.13),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFF2563EB),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tambah Permohonan Baru',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey.shade800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Isikan semua data permohonan baru dengan lengkap.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(thickness: 1, color: Color(0xFFF1F5F9)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaController,
                  decoration: InputDecoration(
                    labelText: "Nama Pelanggan",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Colors.blue.shade400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 18),
                FormPermohonanWidget(
                  permohonan: dummyPermohonan,
                  onSubmit: (formData) {
                    if (namaController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nama pelanggan wajib diisi.'),
                        ),
                      );
                      return;
                    }
                    // Kirim seluruh data form ke Cubit
                    context.read<PermohonanCubit>().tambahPermohonanBaru(
                      namaController.text,
                      prioritas: formData['prioritas'],
                      jenisPermohonan: formData['jenis_permohonan'],
                      daya: formData['daya'],
                      catatanPermohonan: formData['catatan'],
                      alamat: formData['alamat'],
                      waPelanggan: formData['wa_pelanggan'],
                    );
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PermohonanModel> _filterPermohonan(List<PermohonanModel> list) {
    List<PermohonanModel> filtered = list;
    if (selectedFilter != 'Semua') {
      StatusPermohonan? status;
      switch (selectedFilter) {
        case 'Proses':
          status = StatusPermohonan.proses;
          break;
        case 'Selesai':
          status = StatusPermohonan.selesai;
          break;
        case 'Dibatalkan':
          status = StatusPermohonan.dibatalkan;
          break;
      }
      filtered = filtered.where((p) => p.statusKeseluruhan == status).toList();
    }
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.namaPelanggan.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                (p.alamat != null &&
                    p.alamat!.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    )),
          )
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Permohonan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<PermohonanCubit>().loadPermohonanList();
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocBuilder<PermohonanCubit, PermohonanState>(
          builder: (context, state) {
            if (state is PermohonanListLoaded) {
              final allList = state.permohonanList;
              final filteredList = _filterPermohonan(allList);

              final total = allList.length;
              final selesai = allList
                  .where((p) => p.statusKeseluruhan == StatusPermohonan.selesai)
                  .length;
              final proses = allList
                  .where((p) => p.statusKeseluruhan == StatusPermohonan.proses)
                  .length;

              if (total == 0) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inbox_rounded,
                          size: 80,
                          color: Colors.blue.shade300,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Belum ada permohonan',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tekan tombol + untuk menambah permohonan baru',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<PermohonanCubit>().loadPermohonanList();
                },
                child: ListView(
                  children: [
                    // Statistics Cards
                    Row(
                      children: [
                        _StatCard(
                          icon: Icons.folder,
                          value: total.toString(),
                          label: 'Total',
                          color: Colors.lightBlue,
                          gradientColors: [
                            Colors.lightBlue.shade300,
                            Colors.lightBlue.shade600,
                          ],
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.access_time,
                          value: proses.toString(),
                          label: 'Proses',
                          color: Colors.orange,
                          gradientColors: [
                            Colors.orange.shade300,
                            Colors.orange.shade600,
                          ],
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.check_circle,
                          value: selesai.toString(),
                          label: 'Selesai',
                          color: Colors.green,
                          gradientColors: [
                            Colors.green.shade300,
                            Colors.green.shade600,
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Filter/Search Section
                    Container(
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
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Filter Status Dropdown
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: selectedFilter,
                                  items: filterOptions
                                      .map(
                                        (option) => DropdownMenuItem(
                                          value: option,
                                          child: Text(option),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => selectedFilter = value);
                                    }
                                  },
                                  underline: Container(),
                                  icon: Icon(
                                    Icons.filter_list,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // List Items
                    if (filteredList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
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
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada permohonan dengan filter "$selectedFilter"',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ...filteredList.map(
                        (permohonan) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PermohonanListTile(
                            permohonan: permohonan,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                PermohonanDetailScreen.routeName,
                                arguments: permohonan.id,
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              );
            } else if (state is PermohonanError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 60,
                        color: Colors.red.shade300,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Terjadi Kesalahan',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<PermohonanCubit>().loadPermohonanList();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPermohonanDialog(context),
        backgroundColor: Colors.blue.shade400,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final List<Color> gradientColors;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.gradientColors,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                margin: const EdgeInsets.only(right: 0),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      top: -10,
                      right: -10,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.value,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
