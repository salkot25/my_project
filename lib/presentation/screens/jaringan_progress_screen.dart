import 'package:flutter/material.dart';
import '../widgets/forms/form_jaringan_widget.dart';

class JaringanProgressScreen extends StatelessWidget {
  final String permohonanId;
  final String? namaPelanggan;

  const JaringanProgressScreen({
    super.key,
    required this.permohonanId,
    this.namaPelanggan,
  });

  static const String routeName = '/jaringan-progress';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(namaPelanggan ?? 'Progress Jaringan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: FormJaringanWidget(
        permohonanId: permohonanId,
        namaPelanggan: namaPelanggan,
      ),
    );
  }
}
