import 'package:flutter/material.dart';

class VendorLaporanJaringanCard extends StatelessWidget {
  final String jenisPekerjaan;
  final String status;
  final String namaPelanggan;
  final String alamat;
  final String tanggal;
  final String username;
  final String? catatan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VendorLaporanJaringanCard({
    super.key,
    required this.jenisPekerjaan,
    required this.status,
    required this.namaPelanggan,
    required this.alamat,
    required this.tanggal,
    required this.username,
    this.catatan,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Status color logic
    Color badgeColor;
    Color textColor;
    if (status.toLowerCase() == 'selesai') {
      badgeColor = Colors.green.shade50;
      textColor = Colors.green;
    } else if (status.toLowerCase() == 'proses') {
      badgeColor = Colors.orange.shade50;
      textColor = Colors.orange;
    } else {
      badgeColor = Colors.red.shade50;
      textColor = Colors.red;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.blue.shade100, width: 1.1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jenisPekerjaan,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2563EB),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: $status',
                      style: TextStyle(
                        color: status == 'selesai'
                            ? Colors.green
                            : (status == 'proses' ? Colors.orange : Colors.red),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            namaPelanggan,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            alamat,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: Colors.blueGrey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tanggal,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 15,
                      color: Colors.blueGrey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      username,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (catatan != null && catatan!.isNotEmpty) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sticky_note_2,
                          size: 15,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            catatan!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
