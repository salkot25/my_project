import 'package:flutter/material.dart';
import '../../data/models/permohonan_model.dart';
import 'package:intl/intl.dart'; // Tambahkan ini untuk formatting tanggal

class PermohonanListTile extends StatelessWidget {
  final PermohonanModel permohonan;
  final VoidCallback onTap;

  const PermohonanListTile({
    super.key,
    required this.permohonan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(permohonan.namaPelanggan),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${permohonan.id}'),
            Text(
              'Tanggal: ${DateFormat('dd MMM yyyy').format(permohonan.tanggalPengajuan)}',
            ),
            Text(
              'Status: ${permohonan.tahapanAktif}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
