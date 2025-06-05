import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/permohonan_model.dart';
import '../../data/models/tahapan_model.dart';

part 'permohonan_state.dart';

class PermohonanCubit extends Cubit<PermohonanState> {
  PermohonanCubit() : super(PermohonanInitial());

  // Data dummy untuk simulasi. Dalam aplikasi nyata, ini akan berasal dari repository/database.
  final List<PermohonanModel> _daftarPermohonan = [
    PermohonanModel.baru(id: "PEL001", namaPelanggan: "Budi Santoso"),
    PermohonanModel.baru(id: "PEL002", namaPelanggan: "Citra Lestari"),
  ];

  void loadPermohonanList() {
    emit(PermohonanLoading());
    // Simulasi delay untuk pengambilan data
    Future.delayed(const Duration(milliseconds: 500), () {
      emit(PermohonanListLoaded(List.from(_daftarPermohonan)));
    });
  }

  void loadPermohonanDetail(String idPermohonan) {
    emit(PermohonanLoading());
    try {
      final permohonan = _daftarPermohonan.firstWhere(
        (p) => p.id == idPermohonan,
      );
      emit(PermohonanDetailLoaded(permohonan));
    } catch (e) {
      emit(const PermohonanError("Permohonan tidak ditemukan"));
    }
  }

  void tambahPermohonanBaru(String namaPelanggan) {
    // Membuat ID unik sederhana untuk contoh
    final newId =
        "PEL${(_daftarPermohonan.length + 1).toString().padLeft(3, '0')}";
    final permohonanBaru = PermohonanModel.baru(
      id: newId,
      namaPelanggan: namaPelanggan,
    );
    _daftarPermohonan.add(permohonanBaru);

    // Jika state saat ini adalah list, update list tersebut
    if (state is PermohonanListLoaded) {
      emit(PermohonanListLoaded(List.from(_daftarPermohonan)));
    } else {
      // Jika tidak, muat ulang list (atau bisa juga langsung emit state baru jika diperlukan)
      loadPermohonanList();
    }
  }

  void completeCurrentStage(String idPermohonan) {
    final permohonanIndex = _daftarPermohonan.indexWhere(
      (p) => p.id == idPermohonan,
    );

    if (permohonanIndex == -1) {
      emit(const PermohonanError("Permohonan tidak ditemukan untuk diupdate"));
      // Kembalikan ke state sebelumnya jika ada, atau muat ulang list
      if (state is PermohonanDetailLoaded) {
        loadPermohonanDetail((state as PermohonanDetailLoaded).permohonan.id);
      } else {
        loadPermohonanList();
      }
      return;
    }

    PermohonanModel currentPermohonan = _daftarPermohonan[permohonanIndex];
    List<TahapanModel> updatedTahapan = List.from(
      currentPermohonan.daftarTahapan,
    );
    int activeStageIndex = updatedTahapan.indexWhere((t) => t.isAktif);

    if (activeStageIndex != -1) {
      // Tandai tahap saat ini sebagai Selesai
      updatedTahapan[activeStageIndex] = updatedTahapan[activeStageIndex]
          .copyWith(
            status: StatusTahapan.selesai,
            tanggalSelesai: DateTime.now(),
          );

      StatusPermohonan statusKeseluruhanBaru =
          currentPermohonan.statusKeseluruhan;

      // Aktifkan tahap berikutnya jika ada
      if (activeStageIndex + 1 < updatedTahapan.length) {
        updatedTahapan[activeStageIndex +
            1] = updatedTahapan[activeStageIndex + 1].copyWith(
          status: StatusTahapan.aktif,
        );
      } else {
        // Semua tahapan dalam alurTahapanDefault telah selesai
        statusKeseluruhanBaru = StatusPermohonan.selesai;
      }

      final updatedPermohonan = currentPermohonan.copyWith(
        daftarTahapan: updatedTahapan,
        statusKeseluruhan: statusKeseluruhanBaru,
      );

      _daftarPermohonan[permohonanIndex] = updatedPermohonan;

      // Update state
      if (state is PermohonanDetailLoaded &&
          (state as PermohonanDetailLoaded).permohonan.id == idPermohonan) {
        emit(PermohonanDetailLoaded(updatedPermohonan));
      } else if (state is PermohonanListLoaded) {
        // Jika di list screen, update listnya juga
        emit(PermohonanListLoaded(List.from(_daftarPermohonan)));
      } else {
        // Fallback, bisa jadi perlu emit state yang sesuai atau load ulang
        loadPermohonanDetail(idPermohonan);
      }
    }
  }
}
