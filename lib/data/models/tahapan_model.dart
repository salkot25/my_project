import 'package:equatable/equatable.dart';

enum StatusTahapan { menunggu, aktif, selesai }

class TahapanModel extends Equatable {
  final String nama;
  final StatusTahapan status;
  final DateTime? tanggalSelesai;

  const TahapanModel({
    required this.nama,
    this.status = StatusTahapan.menunggu,
    this.tanggalSelesai,
  });

  TahapanModel copyWith({
    String? nama,
    StatusTahapan? status,
    DateTime? tanggalSelesai,
    bool setTanggalSelesaiNull =
        false, // Untuk menghapus tanggal saat status diubah dari selesai
  }) {
    return TahapanModel(
      nama: nama ?? this.nama,
      status: status ?? this.status,
      tanggalSelesai: setTanggalSelesaiNull
          ? null
          : (tanggalSelesai ?? this.tanggalSelesai),
    );
  }

  @override
  List<Object?> get props => [nama, status, tanggalSelesai];

  bool get isSelesai => status == StatusTahapan.selesai;
  bool get isAktif => status == StatusTahapan.aktif;
  bool get isMenunggu => status == StatusTahapan.menunggu;
}
