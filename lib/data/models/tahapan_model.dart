import 'package:equatable/equatable.dart';

enum StatusTahapan { menunggu, aktif, selesai }

class TahapanModel extends Equatable {
  final String nama;
  final StatusTahapan status;
  final DateTime? tanggalSelesai;
  final Map<String, dynamic>? formData; // Untuk menyimpan data form

  const TahapanModel({
    required this.nama,
    this.status = StatusTahapan.menunggu,
    this.tanggalSelesai,
    this.formData,
  });

  factory TahapanModel.fromMap(Map<String, dynamic> map) {
    return TahapanModel(
      nama: map['nama'] as String,
      status: StatusTahapan.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
      ),
      tanggalSelesai: map['tanggal_selesai'] != null
          ? DateTime.parse(map['tanggal_selesai'])
          : null,
      formData: map['form_data'] as Map<String, dynamic>?,
    );
  }

  TahapanModel copyWith({
    String? nama,
    StatusTahapan? status,
    DateTime? tanggalSelesai,
    bool setTanggalSelesaiNull =
        false, // Untuk menghapus tanggal saat status diubah dari selesai
    Map<String, dynamic>? formData,
  }) {
    return TahapanModel(
      nama: nama ?? this.nama,
      status: status ?? this.status,
      tanggalSelesai: setTanggalSelesaiNull
          ? null
          : (tanggalSelesai ?? this.tanggalSelesai),
      formData: formData ?? this.formData,
    );
  }

  @override
  List<Object?> get props => [nama, status, tanggalSelesai, formData];

  bool get isSelesai => status == StatusTahapan.selesai;
  bool get isAktif => status == StatusTahapan.aktif;
  bool get isMenunggu => status == StatusTahapan.menunggu;
}
