import 'package:flutter/material.dart';
import 'package:my_project/presentation/widgets/vendor_laporan_jaringan_history_list.dart';

class VendorLaporanJaringanListScreen extends StatelessWidget {
  static const String routeName = '/vendor-laporan-jaringan';
  const VendorLaporanJaringanListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Laporan Vendor'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: VendorLaporanJaringanHistoryList(),
        ),
      ),
    );
  }
}
