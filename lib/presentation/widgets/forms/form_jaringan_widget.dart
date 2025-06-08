import 'package:flutter/material.dart';
import '../vendor_laporan_jaringan_history.dart';

class FormJaringanWidget extends StatelessWidget {
  final String permohonanId;
  final String? namaPelanggan;

  const FormJaringanWidget({
    super.key,
    required this.permohonanId,
    this.namaPelanggan,
  });

  @override
  Widget build(BuildContext context) {
    return VendorLaporanJaringanHistory(
      permohonanId: permohonanId,
      namaPelanggan: namaPelanggan ?? "Detail Laporan Vendor",
      onLaporanAdded: () {
        // Refresh will be handled by VendorLaporanJaringanHistory internally
      },
    );
  }
}
