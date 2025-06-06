import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FormMomWidget extends StatefulWidget {
  final Function(Map<String, dynamic> formData) onSubmit;
  final Map<String, dynamic>? initialData; // Untuk pre-fill jika ada

  const FormMomWidget({super.key, required this.onSubmit, this.initialData});

  @override
  State<FormMomWidget> createState() => _FormMomWidgetState();
}

class _FormMomWidgetState extends State<FormMomWidget> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  final _catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _selectedDate = widget.initialData!['tanggal_mom'] != null
          ? DateTime.tryParse(widget.initialData!['tanggal_mom'])
          : null;
      _catatanController.text = widget.initialData!['catatan_mom'] ?? '';
    }
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final formData = {
        'tanggal_mom': _selectedDate?.toIso8601String(),
        'catatan_mom': _catatanController.text,
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
            decoration: InputDecoration(
              labelText: 'Tanggal MOM',
              hintText: _selectedDate == null
                  ? 'Pilih Tanggal'
                  : DateFormat('dd MMM yyyy').format(_selectedDate!),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () => _selectDate(context),
            validator: (value) =>
                _selectedDate == null ? 'Tanggal MOM harus diisi' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _catatanController,
            decoration: const InputDecoration(
              labelText: 'Catatan MOM',
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
