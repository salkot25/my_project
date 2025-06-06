import 'package:flutter/material.dart';

enum Vendor { KAG, Armarin }

class FormKontrakRinciWidget extends StatefulWidget {
  final Function(Map<String, dynamic> formData) onSubmit;
  final Map<String, dynamic>? initialData; // Untuk pre-fill jika ada
  final Map<String, dynamic>? rabData; // Data dari tahap RAB

  const FormKontrakRinciWidget({
    super.key,
    required this.onSubmit,
    this.initialData,
    this.rabData,
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
          if (widget.rabData != null && widget.rabData!.isNotEmpty) ...[
            Text(
              'Informasi dari RAB:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            if (widget.rabData!['ukuran_trafo'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(
                  'Ukuran Trafo: ${widget.rabData!['ukuran_trafo']} kVA',
                ),
              ),
            if (widget.rabData!['jumlah_tiang'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text('Jumlah Tiang: ${widget.rabData!['jumlah_tiang']}'),
              ),
            if (widget.rabData!['catatan_rab'] != null &&
                widget.rabData!['catatan_rab'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text('Catatan RAB: ${widget.rabData!['catatan_rab']}'),
              ),
            const Divider(height: 20, thickness: 1),
          ],
          Text(
            'Input Data Kontrak Rinci',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
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
