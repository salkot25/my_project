import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/permohonan_model.dart';
import '../../data/models/tahapan_model.dart';
import '../../core/constants/app_stages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'permohonan_state.dart';

class PermohonanCubit extends Cubit<PermohonanState> {
  PermohonanCubit() : super(PermohonanInitial());

  final SupabaseClient _supabase = Supabase.instance.client;

  void loadPermohonanList() {
    emit(PermohonanLoading());
    _supabase
        .from('permohonan')
        .select()
        .order('tanggal_pengajuan', ascending: false)
        .then((data) {
          // Untuk daftar, kita hanya perlu data permohonan, tahapan akan dimuat di detail
          final permohonanList = data
              .map((map) => PermohonanModel.fromMap(map, []))
              .toList();
          emit(PermohonanListLoaded(permohonanList));
        })
        .catchError((e) {
          emit(
            PermohonanError("Gagal memuat daftar permohonan: ${e.toString()}"),
          );
        });
  }

  void loadPermohonanDetail(String idPermohonan) {
    emit(PermohonanLoading());
    try {
      // Ambil data permohonan
      _supabase
          .from('permohonan')
          .select()
          .eq('id', idPermohonan)
          .single()
          .then((permohonanData) {
            // Ambil data tahapan terkait
            _supabase
                .from('tahapan')
                .select()
                .eq('permohonan_id', idPermohonan)
                .order('urutan', ascending: true)
                .then((tahapanData) {
                  final permohonan = PermohonanModel.fromMap(
                    permohonanData,
                    tahapanData.map((t) => TahapanModel.fromMap(t)).toList(),
                  );
                  emit(PermohonanDetailLoaded(permohonan));
                })
                .catchError((e) {
                  emit(
                    PermohonanError("Gagal memuat tahapan: ${e.toString()}"),
                  );
                });
          })
          .catchError((e) {
            emit(PermohonanError("Gagal memuat permohonan: ${e.toString()}"));
          });
    } catch (e) {
      emit(const PermohonanError("Permohonan tidak ditemukan"));
    }
  }

  void tambahPermohonanBaru(String namaPelanggan) {
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
          // prioritas dan catatan_permohonan akan diisi di tahap pertama
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
            Prioritas? prioritas;
            try {
              prioritas = formData['prioritas'] != null
                  ? Prioritas.values.firstWhere(
                      (e) =>
                          e.toString().split('.').last == formData['prioritas'],
                    )
                  : null;
            } catch (e) {
              // handle error jika parsing enum gagal
            }
            _supabase
                .from('permohonan')
                .update({
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

  // Metode completeCurrentStage yang lama tidak lagi digunakan secara langsung oleh UI form
  // Tapi mungkin masih berguna untuk logika lain jika diperlukan.
  // Saya biarkan di sini untuk referensi, tapi bisa dihapus jika tidak dipakai.
  /*
  void completeCurrentStage(String idPermohonan) {
     // Logika lama yang berinteraksi dengan _daftarPermohonan in-memory
  }
  */
}
