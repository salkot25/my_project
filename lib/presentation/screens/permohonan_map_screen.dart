import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_drawer.dart'; // Asumsi AppDrawer ada di sini
import 'package:latlong2/latlong.dart'; // Untuk koordinat
import '../../logic/permohonan_cubit/permohonan_cubit.dart';
import '../../data/models/permohonan_model.dart';
import '../../data/models/tahapan_model.dart';
// import '../../core/constants/app_stages.dart'; // Jika Anda memiliki konstanta untuk nama tahapan

class PermohonanMapScreen extends StatefulWidget {
  const PermohonanMapScreen({super.key});

  static const String routeName = '/permohonan-map';

  @override
  State<PermohonanMapScreen> createState() => _PermohonanMapScreenState();
}

class _PermohonanMapScreenState extends State<PermohonanMapScreen> {
  @override
  void initState() {
    super.initState();
    // Pastikan PermohonanCubit sudah dimuat dengan data.
    // Jika belum, Anda mungkin perlu memanggil fetch di sini atau memastikan
    // cubit sudah di-load oleh screen sebelumnya atau secara global.
    // Contoh: context.read<PermohonanCubit>().fetchAllPermohonan();
    // Untuk contoh ini, kita asumsikan data sudah ada di cubit.
  }

  List<Marker> _buildMarkers(List<PermohonanModel> permohonanList) {
    final List<Marker> markers = [];
    // Ganti 'Survey Lokasi' dengan konstanta jika ada, misal: AppStages.tahapSurveyLokasi
    const String namaTahapSurvey = 'Survey Lokasi';

    for (final permohonan in permohonanList) {
      try {
        final surveyTahap = permohonan.daftarTahapan.firstWhere(
          (t) => t.nama == namaTahapSurvey && t.formData != null,
          orElse: () => const TahapanModel(
            nama: '',
            formData: null,
          ), // Return dummy if not found
        );

        if (surveyTahap.formData != null &&
            surveyTahap.formData!['tag_lokasi'] != null) {
          String tagLokasiString =
              surveyTahap.formData!['tag_lokasi'] as String;

          // Membersihkan prefix aneh jika ada (dari FormSurveyWidget initialData)
          if (tagLokasiString.startsWith(" 2")) {
            tagLokasiString = tagLokasiString.substring(2);
          }

          final parts = tagLokasiString.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0].trim());
            final lng = double.tryParse(parts[1].trim());

            if (lat != null && lng != null) {
              markers.add(
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: LatLng(lat, lng),
                  child: Tooltip(
                    message: permohonan.namaPelanggan,
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40.0,
                    ),
                  ),
                ),
              );
            }
          }
        }
      } catch (e) {
        // print('Error processing marker for ${permohonan.id}: $e');
        // Abaikan marker jika ada error parsing atau data tidak valid
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peta Permohonan')),
      drawer: AppDrawer(currentRoute: PermohonanMapScreen.routeName),
      body: BlocBuilder<PermohonanCubit, PermohonanState>(
        builder: (context, state) {
          if (state is PermohonanLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PermohonanListLoaded) {
            final markers = _buildMarkers(state.permohonanList);
            return FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(
                  -7.3237947,
                  110.5025821,
                ), // Ganti dengan koordinat default yang sesuai
                initialZoom: 9.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.example.my_project', // GANTI DENGAN PACKAGE NAME APLIKASI ANDA
                  tileProvider: CancellableNetworkTileProvider(),
                ),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
              ],
            );
          } else if (state is PermohonanError) {
            return Center(child: Text('Gagal memuat data: ${state.message}'));
          }
          return const Center(child: Text('Tidak ada data permohonan.'));
        },
      ),
    );
  }
}
