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
      if (_selectedVendor == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Vendor harus dipilih')));
        return;
      }

      final formData = {
        'vendor': _selectedVendor.toString().split('.').last,
        'vendor_email': _selectedVendor == Vendor.KAG
            ? 'kag@sipps.app'
            : 'armarin@sipps.app',
        'catatan': _catatanController.text,
      };
      print('DEBUG: Submitting form data - $formData');
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
          const SizedBox(height: 12),
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
            decoration: InputDecoration(
              labelText: 'Vendor',
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: Icon(Icons.business, color: Colors.blue.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _catatanController,
            decoration: InputDecoration(
              labelText: 'Catatan Kontrak Rinci',
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: Icon(Icons.notes, color: Colors.blue.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                elevation: 0,
              ),
              child: const Text('Simpan & Lanjutkan'),
            ),
          ),
        ],
      ),
    );
  }
}
