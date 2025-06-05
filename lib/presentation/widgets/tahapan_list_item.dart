import 'package:flutter/material.dart';
import '../../data/models/tahapan_model.dart';
import 'package:intl/intl.dart';

class TahapanListItem extends StatelessWidget {
  final TahapanModel tahapan;
  final int index;
  final int totalTahapan;

  const TahapanListItem({
    super.key,
    required this.tahapan,
    required this.index,
    required this.totalTahapan,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (tahapan.status) {
      case StatusTahapan.selesai:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case StatusTahapan.aktif:
        icon = Icons.pending_actions;
        iconColor = Colors.orange;
        break;
      case StatusTahapan.menunggu:
        icon = Icons.radio_button_unchecked;
        iconColor = Colors.grey;
        break;
    }

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        tahapan.nama,
        style: TextStyle(
          fontWeight: tahapan.isAktif ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: tahapan.isSelesai && tahapan.tanggalSelesai != null
          ? Text(
              'Selesai pada: ${DateFormat('dd MMM yyyy, HH:mm').format(tahapan.tanggalSelesai!)}',
            )
          : tahapan.isAktif
          ? const Text('Sedang diproses')
          : const Text('Menunggu giliran'),
      // Anda bisa menambahkan trailing widget jika diperlukan, misalnya tombol untuk menyelesaikan tahap aktif
    );
  }
}
