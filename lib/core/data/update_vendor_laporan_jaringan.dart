import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> updateVendorLaporanJaringan({
  required String id,
  required String judul,
  required String deskripsi,
  required String tanggal,
  required String status,
  required bool siapPasangApp,
  required String permohonanId,
  String? userId,
}) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('vendor_laporan_jaringan')
      .update({
        'jenis_pekerjaan': judul,
        'catatan': deskripsi,
        'tanggal': tanggal,
        'status': status,
        'siap_pasang_app': siapPasangApp,
        'permohonan_id': permohonanId,
        if (userId != null) 'user_id': userId,
      })
      .eq('id', id)
      .select(); // response berupa List<Map<String, dynamic>>
  if (response.isEmpty) {
    throw Exception('Update gagal: data tidak ditemukan atau tidak berubah');
  }
}
