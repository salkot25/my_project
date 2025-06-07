import 'package:equatable/equatable.dart';
import 'tahapan_model.dart';
import '../../core/constants/app_stages.dart'; // Sesuaikan path jika berbeda

enum JenisPermohonan { pasangBaru, perubahanDaya }

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
  final JenisPermohonan? jenisPermohonan;
  final String? daya; // Misal: "1300 VA", "2200 VA"
  final String? namaTahapanAktifCache; // Kolom cache baru
  final String? alamat; // Tambah field alamat
  final String? waPelanggan; // Tambah field WA

  const PermohonanModel({
    required this.id,
    required this.namaPelanggan,
    required this.tanggalPengajuan,
    required this.daftarTahapan,
    this.statusKeseluruhan = StatusPermohonan.proses,
    this.prioritas,
    this.catatanPermohonan,
    this.jenisPermohonan,
    this.daya,
    this.namaTahapanAktifCache,
    this.alamat,
    this.waPelanggan, // Tambah ke konstruktor
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
      jenisPermohonan: map['jenis_permohonan'] != null
          ? JenisPermohonan.values.firstWhere(
              (e) => e.toString().split('.').last == map['jenis_permohonan'],
            )
          : null,
      daya: map['daya'] as String?,
      namaTahapanAktifCache: map['nama_tahapan_aktif_cache'] as String?,
      alamat: map['alamat'] as String?, // Mapping alamat
      waPelanggan: map['wa_pelanggan'] as String?, // Mapping WA
    );
  }

  factory PermohonanModel.baru({
    required String id,
    required String namaPelanggan,
    String? alamat, // Tambah ke factory baru
    String? waPelanggan, // Tambah ke factory baru
  }) {
    List<TahapanModel> tahapanAwal = alurTahapanDefault
        .map((namaTahap) => TahapanModel(nama: namaTahap))
        .toList();
    if (tahapanAwal.isNotEmpty) {
      tahapanAwal[0] = tahapanAwal[0].copyWith(status: StatusTahapan.aktif);
    }
    final String? initialNamaTahapanAktifCache = tahapanAwal.isNotEmpty
        ? tahapanAwal[0].nama
        : null;
    return PermohonanModel(
      id: id,
      namaPelanggan: namaPelanggan,
      tanggalPengajuan: DateTime.now(),
      daftarTahapan: tahapanAwal,
      namaTahapanAktifCache: initialNamaTahapanAktifCache,
      alamat: alamat, // Set alamat jika ada
      waPelanggan: waPelanggan, // Set WA jika ada
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
    JenisPermohonan? jenisPermohonan,
    String? daya,
    String? namaTahapanAktifCache,
    String? alamat, // Tambah ke copyWith
    String? waPelanggan, // Tambah ke copyWith
  }) {
    return PermohonanModel(
      id: id ?? this.id,
      namaPelanggan: namaPelanggan ?? this.namaPelanggan,
      tanggalPengajuan: tanggalPengajuan ?? this.tanggalPengajuan,
      daftarTahapan: daftarTahapan ?? this.daftarTahapan,
      statusKeseluruhan: statusKeseluruhan ?? this.statusKeseluruhan,
      prioritas: prioritas ?? this.prioritas,
      catatanPermohonan: catatanPermohonan ?? this.catatanPermohonan,
      jenisPermohonan: jenisPermohonan ?? this.jenisPermohonan,
      daya: daya ?? this.daya,
      namaTahapanAktifCache:
          namaTahapanAktifCache ?? this.namaTahapanAktifCache,
      alamat: alamat ?? this.alamat, // Copy alamat
      waPelanggan: waPelanggan ?? this.waPelanggan, // Copy WA
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
    jenisPermohonan,
    daya,
    namaTahapanAktifCache,
    alamat, // Tambah ke props
    waPelanggan, // Tambah ke props
  ];

  String get tahapanAktif {
    if (statusKeseluruhan == StatusPermohonan.selesai) {
      return "Selesai";
    }
    if (statusKeseluruhan == StatusPermohonan.dibatalkan) {
      return "Dibatalkan";
    }
    // Jika status proses, coba gunakan cache dulu jika ada
    if (namaTahapanAktifCache != null && namaTahapanAktifCache!.isNotEmpty) {
      return namaTahapanAktifCache!;
    }
    // Jika cache kosong, cari dari daftarTahapan (berguna untuk detail screen)
    final aktifDariDaftar = daftarTahapan.where((t) => t.isAktif).toList();
    if (aktifDariDaftar.isNotEmpty) return aktifDariDaftar.first.nama;

    return "Proses"; // Fallback jika status 'proses' tapi tidak ada tahap aktif
  }
}

extension JenisPermohonanExt on JenisPermohonan {
  String get label {
    switch (this) {
      case JenisPermohonan.pasangBaru:
        return 'Pasang Baru (PB)';
      case JenisPermohonan.perubahanDaya:
        return 'Perubahan Daya (PD)';
    }
  }
}

extension PrioritasExt on Prioritas {
  String get label {
    switch (this) {
      case Prioritas.rendah:
        return 'Rendah';
      case Prioritas.sedang:
        return 'Sedang';
      case Prioritas.tinggi:
        return 'Tinggi';
    }
  }
}
