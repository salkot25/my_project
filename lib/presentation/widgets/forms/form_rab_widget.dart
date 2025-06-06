import 'package:flutter/material.dart';

class FormRabWidget extends StatefulWidget {
  final Function(Map<String, dynamic> formData) onSubmit;
  final Map<String, dynamic>? initialData; // Untuk pre-fill jika ada

  const FormRabWidget({super.key, required this.onSubmit, this.initialData});

  @override
  State<FormRabWidget> createState() => _FormRabWidgetState();
}

class _FormRabWidgetState extends State<FormRabWidget> {
  final _formKey = GlobalKey<FormState>();
  final _ukuranTrafoController = TextEditingController();
  final _jumlahTiangController = TextEditingController();
  final _catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _ukuranTrafoController.text =
          widget.initialData!['ukuran_trafo']?.toString() ?? '';
      _jumlahTiangController.text =
          widget.initialData!['jumlah_tiang']?.toString() ?? '';
      _catatanController.text = widget.initialData!['catatan_rab'] ?? '';
    }
  }

  @override
  void dispose() {
    _ukuranTrafoController.dispose();
    _jumlahTiangController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final formData = {
        'ukuran_trafo': _ukuranTrafoController.text,
        'jumlah_tiang': _jumlahTiangController.text,
        'catatan_rab': _catatanController.text,
      };
      widget.onSubmit(formData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            controller: _ukuranTrafoController,
            decoration: const InputDecoration(
              labelText: 'Ukuran Trafo (kVA)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty
                ? 'Ukuran Trafo harus diisi'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _jumlahTiangController,
            decoration: const InputDecoration(
              labelText: 'Jumlah Tiang',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty
                ? 'Jumlah Tiang harus diisi'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _catatanController,
            decoration: const InputDecoration(
              labelText: 'Catatan RAB',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Simpan & Lanjutkan'),
            ),
          ),
        ],
      ),
    );
  }
}
