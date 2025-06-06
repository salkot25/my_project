import 'package:equatable/equatable.dart';
import 'tahapan_model.dart';
import '../../core/constants/app_stages.dart'; // Sesuaikan path jika berbeda

enum StatusPermohonan { proses, selesai, dibatalkan }

enum Prioritas { rendah, sedang, tinggi }

class PermohonanModel extends Equatable {
  final String id;
  final String namaPelanggan;
  final DateTime tanggalPengajuan;
  final List<TahapanModel> daftarTahapan;
  final StatusPermohonan statusKeseluruhan;
  final Prioritas? prioritas; // Tambahkan prioritas
  final String? catatanPermohonan; // Tambahkan catatan awal

  const PermohonanModel({
    required this.id,
    required this.namaPelanggan,
    required this.tanggalPengajuan,
    required this.daftarTahapan,
    this.statusKeseluruhan = StatusPermohonan.proses,
    this.prioritas,
    this.catatanPermohonan,
  });

  factory PermohonanModel.fromMap(
    Map<String, dynamic> map,
    List<TahapanModel> tahapan,
  ) {
    return PermohonanModel(
      id: map['id'] as String,
      namaPelanggan: map['nama_pelanggan'] as String,
      tanggalPengajuan: DateTime.parse(map['tanggal_pengajuan']),
      daftarTahapan: tahapan,
      statusKeseluruhan: StatusPermohonan.values.firstWhere(
        (e) => e.toString().split('.').last == map['status_keseluruhan'],
      ),
      prioritas: map['prioritas'] != null
          ? Prioritas.values.firstWhere(
              (e) => e.toString().split('.').last == map['prioritas'],
            )
          : null,
      catatanPermohonan: map['catatan_permohonan'] as String?,
    );
  }

  factory PermohonanModel.baru({
    required String id,
    required String namaPelanggan,
  }) {
    List<TahapanModel> tahapanAwal = alurTahapanDefault
        .map((namaTahap) => TahapanModel(nama: namaTahap))
        .toList();
    if (tahapanAwal.isNotEmpty) {
      tahapanAwal[0] = tahapanAwal[0].copyWith(status: StatusTahapan.aktif);
    }
    return PermohonanModel(
      id: id,
      namaPelanggan: namaPelanggan,
      tanggalPengajuan: DateTime.now(),
      daftarTahapan: tahapanAwal,
      // prioritas dan catatanPermohonan bisa diisi dari form awal
      // atau dibiarkan null dan diisi pada tahap pertama
    );
  }

  PermohonanModel copyWith({
    String? id,
    String? namaPelanggan,
    DateTime? tanggalPengajuan,
    List<TahapanModel>? daftarTahapan,
    StatusPermohonan? statusKeseluruhan,
    Prioritas? prioritas,
    String? catatanPermohonan,
  }) {
    return PermohonanModel(
      id: id ?? this.id,
      namaPelanggan: namaPelanggan ?? this.namaPelanggan,
      tanggalPengajuan: tanggalPengajuan ?? this.tanggalPengajuan,
      daftarTahapan: daftarTahapan ?? this.daftarTahapan,
      statusKeseluruhan: statusKeseluruhan ?? this.statusKeseluruhan,
      prioritas: prioritas ?? this.prioritas,
      catatanPermohonan: catatanPermohonan ?? this.catatanPermohonan,
    );
  }

  @override
  List<Object?> get props => [
    id,
    namaPelanggan,
    tanggalPengajuan,
    daftarTahapan,
    statusKeseluruhan,
    prioritas,
    catatanPermohonan,
  ];

  String get tahapanAktif {
    final aktif = daftarTahapan.firstWhere(
      (t) => t.isAktif,
      orElse: () => const TahapanModel(nama: "N/A"),
    );
    if (statusKeseluruhan == StatusPermohonan.selesai) return "Selesai";
    return aktif.nama;
  }
}
