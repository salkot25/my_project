import 'package:flutter/material.dart';

enum Vendor { KAG, Armarin }

class FormKontrakRinciWidget extends StatefulWidget {
  final Function(Map<String, dynamic> formData) onSubmit;
  final Map<String, dynamic>? initialData; // Untuk pre-fill jika ada

  const FormKontrakRinciWidget({
    super.key,
    required this.onSubmit,
    this.initialData,
  });

  @override
  State<FormKontrakRinciWidget> createState() => _FormKontrakRinciWidgetState();
}

class _FormKontrakRinciWidgetState extends State<FormKontrakRinciWidget> {
  final _formKey = GlobalKey<FormState>();
  Vendor? _selectedVendor;
  final _catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _selectedVendor = widget.initialData!['vendor'] != null
          ? Vendor.values.firstWhere(
              (e) =>
                  e.toString().split('.').last == widget.initialData!['vendor'],
            )
          : null;
      _catatanController.text = widget.initialData!['catatan_kontrak'] ?? '';
    }
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final formData = {
        'vendor': _selectedVendor?.toString().split('.').last,
        'catatan_kontrak': _catatanController.text,
        // Anda bisa menambahkan konfirmasi material RAB di sini jika perlu
        // Misalnya, menampilkan data RAB dari tahap sebelumnya dan meminta konfirmasi
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
          // Anda bisa menampilkan data RAB dari tahap sebelumnya di sini
          // Contoh: Text('Kebutuhan Trafo (dari RAB): ${widget.initialData?['ukuran_trafo_rab'] ?? '-'}'),
          // Text('Jumlah Tiang (dari RAB): ${widget.initialData?['jumlah_tiang_rab'] ?? '-'}'),
          // const SizedBox(height: 16),
          const Text(
            'Pilih Vendor:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          DropdownButtonFormField<Vendor>(
            value: _selectedVendor,
            hint: const Text('Pilih Vendor'),
            items: Vendor.values.map((Vendor value) {
              return DropdownMenuItem<Vendor>(
                value: value,
                child: Text(value.toString().split('.').last),
              );
            }).toList(),
            onChanged: (Vendor? newValue) =>
                setState(() => _selectedVendor = newValue),
            validator: (value) => value == null ? 'Vendor harus dipilih' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _catatanController,
            decoration: const InputDecoration(
              labelText: 'Catatan Kontrak Rinci',
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
