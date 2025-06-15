import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/permohonan_model.dart';
import '../../data/models/tahapan_model.dart';
import '../../core/constants/app_stages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'permohonan_state.dart';

class PermohonanCubit extends Cubit<PermohonanState> {
  PermohonanCubit() : super(PermohonanInitial()) {
    // Log saat cubit diinisialisasi
    // print('PermohonanCubit: Initialized with state $state');
  }

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void onChange(Change<PermohonanState> change) {
    super.onChange(change);
    // print(
    //   'PermohonanCubit STATE CHANGE: ${change.currentState} -> ${change.nextState}',
    // );
  }

  void loadPermohonanList() {
    emit(PermohonanLoading());
    _supabase
        .from('permohonan')
        .select()
        .order('tanggal_pengajuan', ascending: false)
        .then((data) {
          // print(
          //   'PermohonanCubit: loadPermohonanList - Supabase call successful. Data count: ${data.length}',
          // );
          // Untuk daftar, kita hanya perlu data permohonan, tahapan akan dimuat di detail
          final permohonanList = data
              .map((map) => PermohonanModel.fromMap(map, []))
              .toList();
          emit(PermohonanListLoaded(permohonanList));
        })
        .catchError((e, stackTrace) {
          // print(
          //   'PermohonanCubit: loadPermohonanList - Supabase call failed. Error: $e',
          // );
          // print(
          //   'PermohonanCubit: loadPermohonanList - StackTrace: $stackTrace',
          // );
          emit(
            PermohonanError("Gagal memuat daftar permohonan: ${e.toString()}"),
          );
        });
  }

  void loadPermohonanDetail(String idPermohonan) {
    // print(
    //   'PermohonanCubit: loadPermohonanDetail called for ID $idPermohonan. Current state: $state',
    // );
    emit(PermohonanLoading());
    try {
      // Ambil data permohonan
      _supabase
          .from('permohonan')
          .select()
          .eq('id', idPermohonan)
          .single()
          .then((permohonanData) {
            // print(
            //   'PermohonanCubit: loadPermohonanDetail - Permohonan data fetched.',
            // );
            // Ambil data tahapan terkait
            _supabase
                .from('tahapan')
                .select()
                .eq('permohonan_id', idPermohonan)
                .order('urutan', ascending: true)
                .then((tahapanData) {
                  // print(
                  //   'PermohonanCubit: loadPermohonanDetail - Tahapan data fetched.',
                  // );
                  final permohonan = PermohonanModel.fromMap(
                    permohonanData,
                    tahapanData.map((t) => TahapanModel.fromMap(t)).toList(),
                  );
                  emit(PermohonanDetailLoaded(permohonan));
                })
                .catchError((e) {
                  // print(
                  //   'PermohonanCubit: loadPermohonanDetail - Error fetching tahapan: $e',
                  // );
                  emit(
                    PermohonanError("Gagal memuat tahapan: ${e.toString()}"),
                  );
                });
          })
          .catchError((e) {
            // print(
            //   'PermohonanCubit: loadPermohonanDetail - Error fetching permohonan: $e',
            // );
            emit(PermohonanError("Gagal memuat permohonan: ${e.toString()}"));
          });
    } catch (e) {
      // print('PermohonanCubit: loadPermohonanDetail - General error: $e');
      emit(const PermohonanError("Permohonan tidak ditemukan"));
    }
  }

  // Ubah: tambahPermohonanBaru menerima seluruh data form
  void tambahPermohonanBaru(
    String namaPelanggan, {
    String? prioritas,
    String? jenisPermohonan,
    String? daya,
    String? catatanPermohonan,
    String? alamat,
    String? waPelanggan, // Tambah parameter WA
  }) {
    // print(
    //   'PermohonanCubit: tambahPermohonanBaru called for $namaPelanggan. Current state: $state',
    // );
    final newId = "PERM_${DateTime.now().millisecondsSinceEpoch}";
    final permohonanBaru = PermohonanModel.baru(
      id: newId,
      namaPelanggan: namaPelanggan,
      alamat: alamat,
      waPelanggan: waPelanggan,
    );

    _supabase
        .from('permohonan')
        .insert({
          'id': permohonanBaru.id,
          'nama_pelanggan': permohonanBaru.namaPelanggan,
          'tanggal_pengajuan': permohonanBaru.tanggalPengajuan
              .toIso8601String(),
          'status_keseluruhan': permohonanBaru.statusKeseluruhan
              .toString()
              .split('.')
              .last,
          'nama_tahapan_aktif_cache': permohonanBaru.namaTahapanAktifCache,
          'prioritas': prioritas,
          'jenis_permohonan': jenisPermohonan,
          'daya': daya,
          'catatan_permohonan': catatanPermohonan,
          'alamat': alamat,
          'wa_pelanggan': waPelanggan, // Insert WA
        })
        .then((_) {
          final tahapanToInsert = permohonanBaru.daftarTahapan
              .asMap()
              .entries
              .map((entry) {
                int index = entry.key;
                TahapanModel tahap = entry.value;
                return {
                  'permohonan_id': permohonanBaru.id,
                  'nama': tahap.nama,
                  'status': tahap.status.toString().split('.').last,
                  'urutan': index,
                };
              })
              .toList();
          _supabase
              .from('tahapan')
              .insert(tahapanToInsert)
              .then((_) {
                loadPermohonanList();
              })
              .catchError((e) {
                emit(
                  PermohonanError("Gagal menyimpan tahapan: ${e.toString()}"),
                );
              });
        })
        .catchError((e) {
          emit(
            PermohonanError("Gagal menyimpan permohonan baru: ${e.toString()}"),
          );
        });
  }

  void saveStageFormDataAndComplete(
    String idPermohonan,
    String namaTahapAktif,
    Map<String, dynamic> formData,
  ) async {
    // Otomatisasi pengisian user_update dan tanggal_update pada setiap submit form tahapan
    final user = Supabase.instance.client.auth.currentUser;
    String? username;
    if (user != null) {
      // Coba ambil username dari tabel profile
      final profile = await Supabase.instance.client
          .from('profile')
          .select('username')
          .eq('user_id', user.id)
          .maybeSingle();
      username =
          profile != null &&
              profile['username'] != null &&
              profile['username'].toString().isNotEmpty
          ? profile['username'].toString()
          : null;
    }

    // Convert formData to a JSON-serializable format
    final serializedFormData = Map<String, dynamic>.from(formData);
    serializedFormData['user_update'] = username ?? user?.email ?? 'User';
    serializedFormData['tanggal_update'] = DateTime.now().toIso8601String();

    // 1. Update data form dan status tahap saat ini di tabel 'tahapan'
    await _supabase
        .from('tahapan')
        .update({
          'status': StatusTahapan.selesai.toString().split('.').last,
          'tanggal_selesai': DateTime.now().toIso8601String(),
          'form_data': serializedFormData,
        })
        .eq('permohonan_id', idPermohonan)
        .eq('nama', namaTahapAktif);

    // Jika tahap "Permohonan" yang diisi, update juga data di PermohonanModel
    if (namaTahapAktif == "Permohonan") {
      JenisPermohonan? jenisPermohonan;
      Prioritas? prioritas;
      try {
        jenisPermohonan = formData['jenis_permohonan'] != null
            ? JenisPermohonan.values.firstWhere(
                (e) =>
                    e.toString().split('.').last ==
                    formData['jenis_permohonan'],
              )
            : null;
        prioritas = formData['prioritas'] != null
            ? Prioritas.values.firstWhere(
                (e) => e.toString().split('.').last == formData['prioritas'],
              )
            : null;
        await _supabase
            .from('permohonan')
            .update({
              'jenis_permohonan': jenisPermohonan?.toString().split('.').last,
              'prioritas': prioritas?.toString().split('.').last,
              'daya': formData['daya'],
              'catatan_permohonan': formData['catatan'],
              'alamat': formData['alamat'],
              'wa_pelanggan': formData['wa_pelanggan'],
            })
            .eq('id', idPermohonan);
      } catch (_) {}
    }

    // Refresh detail
    loadPermohonanDetail(idPermohonan);

    // Cari urutan tahap saat ini
    final currentTahapData = await _supabase
        .from('tahapan')
        .select('urutan')
        .eq('permohonan_id', idPermohonan)
        .eq('nama', namaTahapAktif)
        .single();

    final currentUrutan = currentTahapData['urutan'] as int;
    final nextUrutan = currentUrutan + 1;

    // Jika ada tahap berikutnya
    if (nextUrutan < alurTahapanDefault.length) {
      // Cek status tahap berikutnya
      final nextTahapData = await _supabase
          .from('tahapan')
          .select('status')
          .eq('permohonan_id', idPermohonan)
          .eq('urutan', nextUrutan)
          .single();

      // Hanya update jika tahap berikutnya belum selesai
      if (nextTahapData['status'] !=
          StatusTahapan.selesai.toString().split('.').last) {
        await _supabase
            .from('tahapan')
            .update({'status': StatusTahapan.aktif.toString().split('.').last})
            .eq('permohonan_id', idPermohonan)
            .eq('urutan', nextUrutan);
      }

      // Update status keseluruhan di tabel 'permohonan'
      final nextTahapNama = alurTahapanDefault[nextUrutan];
      _updatePermohonanStatus(idPermohonan, nextTahapNama);
    } else {
      // Jika tidak ada tahap berikutnya, tandai permohonan selesai
      _updatePermohonanStatus(idPermohonan, "Selesai");
    }
  }

  void _updatePermohonanStatus(String idPermohonan, String statusNamaTahap) {
    StatusPermohonan statusKeseluruhan;
    if (statusNamaTahap == "Selesai") {
      statusKeseluruhan = StatusPermohonan.selesai;
    } else {
      statusKeseluruhan = StatusPermohonan.proses;
    }

    _supabase
        .from('permohonan')
        .update({
          'status_keseluruhan': statusKeseluruhan.toString().split('.').last,
          'nama_tahapan_aktif_cache': statusNamaTahap,
        })
        .eq('id', idPermohonan)
        .then((_) {
          loadPermohonanDetail(idPermohonan);
        })
        .catchError((e) {
          emit(
            PermohonanError(
              "Gagal mengupdate status permohonan: ${e.toString()}",
            ),
          );
        });
  }

  void updatePermohonanDetailData(
    String idPermohonan, {
    required String namaPelanggan,
    Prioritas? prioritas,
    JenisPermohonan? jenisPermohonan,
    String? daya,
    String? catatanPermohonan,
    String? alamat,
    String? waPelanggan, // Tambah parameter WA
  }) {
    emit(PermohonanLoading());
    _supabase
        .from('permohonan')
        .update({
          'nama_pelanggan': namaPelanggan,
          'prioritas': prioritas?.toString().split('.').last,
          'jenis_permohonan': jenisPermohonan?.toString().split('.').last,
          'daya': daya,
          'catatan_permohonan': catatanPermohonan,
          'alamat': alamat,
          'wa_pelanggan': waPelanggan, // Update WA
        })
        .eq('id', idPermohonan)
        .then((_) {
          loadPermohonanDetail(idPermohonan);
        })
        .catchError((e) {
          emit(
            PermohonanError(
              "Gagal mengupdate detail permohonan: ${e.toString()}",
            ),
          );
        });
  }

  void hapusPermohonan(String idPermohonan) {
    emit(PermohonanLoading()); // Atau state spesifik untuk delete
    _supabase
        .from('permohonan')
        .delete()
        .eq('id', idPermohonan)
        .then((_) {
          // Setelah berhasil hapus, kembali ke daftar atau muat ulang daftar
          // Untuk kesederhanaan, kita akan emit state yang menandakan penghapusan berhasil
          // dan biarkan UI menangani navigasi/refresh.
          emit(PermohonanOperationSuccess("Permohonan berhasil dihapus."));
          loadPermohonanList(); // Muat ulang daftar
        })
        .catchError((e) {
          emit(PermohonanError("Gagal menghapus permohonan: ${e.toString()}"));
        });
  }

  void batalkanPermohonan(String idPermohonan) {
    emit(PermohonanLoading()); // Atau state spesifik
    _supabase
        .from('permohonan')
        .update({
          'status_keseluruhan': StatusPermohonan.dibatalkan
              .toString()
              .split('.')
              .last,
          'nama_tahapan_aktif_cache':
              "Dibatalkan", // Update cache saat dibatalkan
          // Anda mungkin ingin menghentikan semua tahapan aktif juga
        })
        .eq('id', idPermohonan)
        .then((_) {
          loadPermohonanDetail(idPermohonan); // Muat ulang detail
        })
        .catchError((e) {
          emit(
            PermohonanError("Gagal membatalkan permohonan: ${e.toString()}"),
          );
        });
  }

  // Metode completeCurrentStage yang lama tidak lagi digunakan secara langsung oleh UI form
  // Tapi mungkin masih berguna untuk logika lain jika diperlukan.
  // Saya biarkan di sini untuk referensi, tapi bisa dihapus jika tidak dipakai.
  /*
  void completeCurrentStage(String idPermohonan) {
     // Logika lama yang berinteraksi dengan _daftarPermohonan in-memory
  }
  */
}
