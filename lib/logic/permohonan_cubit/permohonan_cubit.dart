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
    print(
      'PermohonanCubit STATE CHANGE: ${change.currentState} -> ${change.nextState}',
    );
  }

  void loadPermohonanList() {
    emit(PermohonanLoading());
    _supabase
        .from('permohonan')
        .select()
        .order('tanggal_pengajuan', ascending: false)
        .then((data) {
          print(
            'PermohonanCubit: loadPermohonanList - Supabase call successful. Data count: ${data.length}',
          );
          // Untuk daftar, kita hanya perlu data permohonan, tahapan akan dimuat di detail
          final permohonanList = data
              .map((map) => PermohonanModel.fromMap(map, []))
              .toList();
          emit(PermohonanListLoaded(permohonanList));
        })
        .catchError((e, stackTrace) {
          print(
            'PermohonanCubit: loadPermohonanList - Supabase call failed. Error: $e',
          );
          print(
            'PermohonanCubit: loadPermohonanList - StackTrace: $stackTrace',
          );
          emit(
            PermohonanError("Gagal memuat daftar permohonan: ${e.toString()}"),
          );
        });
  }

  void loadPermohonanDetail(String idPermohonan) {
    print(
      'PermohonanCubit: loadPermohonanDetail called for ID $idPermohonan. Current state: $state',
    );
    emit(PermohonanLoading());
    try {
      // Ambil data permohonan
      _supabase
          .from('permohonan')
          .select()
          .eq('id', idPermohonan)
          .single()
          .then((permohonanData) {
            print(
              'PermohonanCubit: loadPermohonanDetail - Permohonan data fetched.',
            );
            // Ambil data tahapan terkait
            _supabase
                .from('tahapan')
                .select()
                .eq('permohonan_id', idPermohonan)
                .order('urutan', ascending: true)
                .then((tahapanData) {
                  print(
                    'PermohonanCubit: loadPermohonanDetail - Tahapan data fetched.',
                  );
                  final permohonan = PermohonanModel.fromMap(
                    permohonanData,
                    tahapanData.map((t) => TahapanModel.fromMap(t)).toList(),
                  );
                  emit(PermohonanDetailLoaded(permohonan));
                })
                .catchError((e) {
                  print(
                    'PermohonanCubit: loadPermohonanDetail - Error fetching tahapan: $e',
                  );
                  emit(
                    PermohonanError("Gagal memuat tahapan: ${e.toString()}"),
                  );
                });
          })
          .catchError((e) {
            print(
              'PermohonanCubit: loadPermohonanDetail - Error fetching permohonan: $e',
            );
            emit(PermohonanError("Gagal memuat permohonan: ${e.toString()}"));
          });
    } catch (e) {
      print('PermohonanCubit: loadPermohonanDetail - General error: $e');
      emit(const PermohonanError("Permohonan tidak ditemukan"));
    }
  }

  void tambahPermohonanBaru(String namaPelanggan) {
    print(
      'PermohonanCubit: tambahPermohonanBaru called for $namaPelanggan. Current state: $state',
    );
    // Membuat ID unik sederhana untuk contoh (Supabase juga bisa generate UUID)
    final newId =
        "PERM_${DateTime.now().millisecondsSinceEpoch}"; // Contoh ID unik
    final permohonanBaru = PermohonanModel.baru(
      id: newId,
      namaPelanggan: namaPelanggan,
    );

    // Simpan ke Supabase
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
          // prioritas, jenis_permohonan, daya, dan catatan_permohonan akan diisi di tahap pertama
        })
        .then((_) {
          // Simpan tahapan-tahapan awal
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
                // Muat ulang daftar setelah berhasil menambah
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
  ) {
    // 1. Update data form dan status tahap saat ini di tabel 'tahapan'
    _supabase
        .from('tahapan')
        .update({
          'status': StatusTahapan.selesai.toString().split('.').last,
          'tanggal_selesai': DateTime.now().toIso8601String(),
          'form_data': formData, // Simpan Map<String, dynamic> langsung
        })
        .eq('permohonan_id', idPermohonan)
        .eq('nama', namaTahapAktif)
        .then((_) {
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
                      (e) =>
                          e.toString().split('.').last == formData['prioritas'],
                    )
                  : null;
            } catch (e) {
              // handle error jika parsing enum gagal
              // Anda bisa menambahkan logging atau emit error state di sini
            }
            _supabase
                .from('permohonan')
                .update({
                  'jenis_permohonan': jenisPermohonan
                      ?.toString()
                      .split('.')
                      .last,
                  'daya':
                      formData['daya'] as String?, // Ambil daya dari formData
                  'prioritas': prioritas?.toString().split('.').last,
                  'catatan_permohonan': formData['catatan'] as String?,
                })
                .eq('id', idPermohonan)
                .catchError((e) {
                  emit(
                    PermohonanError(
                      "Gagal mengupdate data permohonan awal: ${e.toString()}",
                    ),
                  );
                });
          }

          // 2. Cari tahap berikutnya berdasarkan urutan
          _supabase
              .from('tahapan')
              .select('urutan')
              .eq('permohonan_id', idPermohonan)
              .eq('nama', namaTahapAktif)
              .single()
              .then((currentTahapData) {
                final currentUrutan = currentTahapData['urutan'] as int;
                final nextUrutan = currentUrutan + 1;

                // 3. Update status tahap berikutnya menjadi 'aktif' jika ada
                if (nextUrutan < alurTahapanDefault.length) {
                  _supabase
                      .from('tahapan')
                      .update({
                        'status': StatusTahapan.aktif
                            .toString()
                            .split('.')
                            .last,
                      })
                      .eq('permohonan_id', idPermohonan)
                      .eq('urutan', nextUrutan)
                      .then((_) {
                        // 4. Update status keseluruhan di tabel 'permohonan'
                        final nextTahapNama = alurTahapanDefault[nextUrutan];
                        _updatePermohonanStatus(idPermohonan, nextTahapNama);
                      })
                      .catchError((e) {
                        emit(
                          PermohonanError(
                            "Gagal mengaktifkan tahap berikutnya: ${e.toString()}",
                          ),
                        );
                      });
                } else {
                  // Jika tidak ada tahap berikutnya, tandai permohonan selesai
                  _updatePermohonanStatus(idPermohonan, "Selesai");
                }
              })
              .catchError((e) {
                emit(
                  PermohonanError(
                    "Gagal mencari urutan tahap: ${e.toString()}",
                  ),
                );
              });
        })
        .catchError((e) {
          emit(
            PermohonanError("Gagal menyimpan data form tahap: ${e.toString()}"),
          );
        });
  }

  void advanceToNextStage(String idPermohonan, String namaTahapSaatIni) {
    // 1. Update status tahap saat ini menjadi 'selesai'
    _supabase
        .from('tahapan')
        .update({
          'status': StatusTahapan.selesai.toString().split('.').last,
          'tanggal_selesai': DateTime.now().toIso8601String(),
          // formData bisa null atau kosong jika tahap ini tidak memiliki form
        })
        .eq('permohonan_id', idPermohonan)
        .eq('nama', namaTahapSaatIni)
        .then((_) {
          // 2. Cari tahap berikutnya berdasarkan urutan
          _supabase
              .from('tahapan')
              .select('urutan')
              .eq('permohonan_id', idPermohonan)
              .eq('nama', namaTahapSaatIni)
              .single()
              .then((currentTahapData) {
                final currentUrutan = currentTahapData['urutan'] as int;
                final nextUrutan = currentUrutan + 1;

                // 3. Update status tahap berikutnya menjadi 'aktif' jika ada
                if (nextUrutan < alurTahapanDefault.length) {
                  _supabase
                      .from('tahapan')
                      .update({
                        'status': StatusTahapan.aktif
                            .toString()
                            .split('.')
                            .last,
                      })
                      .eq('permohonan_id', idPermohonan)
                      .eq('urutan', nextUrutan)
                      .then((_) {
                        // 4. Update status keseluruhan di tabel 'permohonan'
                        final nextTahapNama = alurTahapanDefault[nextUrutan];
                        _updatePermohonanStatus(idPermohonan, nextTahapNama);
                      })
                      .catchError((e) {
                        emit(
                          PermohonanError(
                            "Gagal mengaktifkan tahap berikutnya (advance): ${e.toString()}",
                          ),
                        );
                      });
                } else {
                  // Jika tidak ada tahap berikutnya, tandai permohonan selesai
                  _updatePermohonanStatus(idPermohonan, "Selesai");
                }
              })
              .catchError((e) {
                emit(
                  PermohonanError(
                    "Gagal mencari urutan tahap (advance): ${e.toString()}",
                  ),
                );
              });
        })
        .catchError((e) {
          emit(
            PermohonanError(
              "Gagal menyelesaikan tahap (advance): ${e.toString()}",
            ),
          );
        });
  }

  void _updatePermohonanStatus(String idPermohonan, String statusNamaTahap) {
    StatusPermohonan statusKeseluruhan;
    if (statusNamaTahap == "Selesai") {
      statusKeseluruhan = StatusPermohonan.selesai;
    } else {
      // Asumsi status keseluruhan adalah nama tahap aktif saat ini
      statusKeseluruhan = StatusPermohonan.proses; // Atau status lain jika ada
    }

    _supabase
        .from('permohonan')
        .update({
          'status_keseluruhan': statusKeseluruhan.toString().split('.').last,
          // Anda bisa menyimpan nama tahap aktif di sini juga jika perlu
          // 'tahapan_aktif_nama': statusNamaTahap, // Ini bisa membantu query list
        })
        .eq('id', idPermohonan)
        .then((_) {
          // Muat ulang detail permohonan untuk refresh UI
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
  }) {
    emit(PermohonanLoading()); // Atau state spesifik untuk update
    _supabase
        .from('permohonan')
        .update({
          'nama_pelanggan': namaPelanggan,
          'prioritas': prioritas?.toString().split('.').last,
          'jenis_permohonan': jenisPermohonan?.toString().split('.').last,
          'daya': daya,
          'catatan_permohonan': catatanPermohonan,
        })
        .eq('id', idPermohonan)
        .then((_) {
          loadPermohonanDetail(idPermohonan); // Muat ulang detail
          // Pertimbangkan untuk memuat ulang list juga jika nama pelanggan berubah dan ditampilkan di list
          // loadPermohonanList();
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
