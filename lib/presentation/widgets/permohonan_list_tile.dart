import 'package:flutter/material.dart';
import '../../data/models/permohonan_model.dart';
import 'tahapan_progress_circle.dart';
import '../../core/constants/app_stages.dart';

class PermohonanListTile extends StatelessWidget {
  final PermohonanModel permohonan;
  final VoidCallback onTap;

  const PermohonanListTile({
    super.key,
    required this.permohonan,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (permohonan.statusKeseluruhan) {
      case StatusPermohonan.proses:
        return Colors.blue;
      case StatusPermohonan.selesai:
        return Colors.green;
      case StatusPermohonan.dibatalkan:
        return Colors.red;
    }
  }

  Color _getPriorityColor() {
    switch (permohonan.prioritas) {
      case Prioritas.tinggi:
        return Colors.red;
      case Prioritas.sedang:
        return Colors.orange;
      case Prioritas.rendah:
        return Colors.green;
      case null:
        return Colors.grey;
    }
  }

  String _getPriorityText() {
    return permohonan.prioritas?.label ?? '';
  }

  String _getFormattedDate() {
    final date = permohonan.tanggalPengajuan;
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final String alamat =
        (permohonan.alamat == null || permohonan.alamat!.isEmpty)
        ? '-'
        : permohonan.alamat!;

    // Cari index tahapan aktif dari nama di permohonan.tahapanAktif
    int tahapIndex = alurTahapanDefault.indexWhere(
      (t) => t == permohonan.tahapanAktif,
    );
    final int totalTahapan = alurTahapanDefault.length;
    double progress = 0;
    if (permohonan.statusKeseluruhan == StatusPermohonan.selesai) {
      progress = 1.0;
    } else if (permohonan.statusKeseluruhan == StatusPermohonan.dibatalkan) {
      progress = 0.0;
    } else if (tahapIndex >= 0) {
      progress = (tahapIndex) / totalTahapan;
    } else {
      progress = 0.0;
    }
    final int percentValue = (progress * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Status Indicator Line
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Progress Circle Avatar
                      TahapanProgressCircle(
                        total: 100,
                        done: percentValue,
                        size: 44,
                        mainColor: statusColor,
                        bgColor: Colors.grey.shade200,
                        textStyle: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Customer Name and Address
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              permohonan.namaPelanggan,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alamat,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Current Stage Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              permohonan.tahapanAktif,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Date Container
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getFormattedDate(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Priority Badge (if exists)
                      if (permohonan.prioritas != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getPriorityColor().withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flag,
                                size: 12,
                                color: _getPriorityColor(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getPriorityText(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getPriorityColor(),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Jenis Permohonan Badge (if exists)
                      if (permohonan.jenisPermohonan != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.electric_bolt,
                                size: 12,
                                color: Colors.purple.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                permohonan.jenisPermohonan?.label ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
