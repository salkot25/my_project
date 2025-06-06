import 'package:flutter/material.dart';
import '../../../data/models/permohonan_model.dart'; // Sesuaikan path

class FormPermohonanWidget extends StatefulWidget {
  final PermohonanModel permohonan; // Untuk pre-fill jika ada data awal
  final Function(Map<String, dynamic> formData) onSubmit;

  const FormPermohonanWidget({
    super.key,
    required this.permohonan,
    required this.onSubmit,
  });

  @override
  State<FormPermohonanWidget> createState() => _FormPermohonanWidgetState();
}

class _FormPermohonanWidgetState extends State<FormPermohonanWidget> {
  final _formKey = GlobalKey<FormState>();
  Prioritas? _selectedPrioritas;
  JenisPermohonan? _selectedJenisPermohonan;
  final _dayaController = TextEditingController();
  final _catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPrioritas = widget.permohonan.prioritas;
    _selectedJenisPermohonan = widget.permohonan.jenisPermohonan;
    _dayaController.text = widget.permohonan.daya ?? '';
    _catatanController.text = widget.permohonan.catatanPermohonan ?? '';
  }

  @override
  void dispose() {
    _catatanController.dispose();
    _dayaController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final formData = {
        'prioritas': _selectedPrioritas
            ?.toString()
            .split('.')
            .last, // Simpan sebagai string
        'jenis_permohonan': _selectedJenisPermohonan
            ?.toString()
            .split('.')
            .last, // Simpan sebagai string
        'catatan': _catatanController.text,
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
          Text(
            'Detail Pelanggan: ${widget.permohonan.namaPelanggan}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text('ID Permohonan: ${widget.permohonan.id}'),
          const SizedBox(height: 20),
          const Text(
            'Jenis Permohonan:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          DropdownButtonFormField<JenisPermohonan>(
            value: _selectedJenisPermohonan,
            hint: const Text('Pilih Jenis Permohonan'),
            items: JenisPermohonan.values.map((JenisPermohonan value) {
              return DropdownMenuItem<JenisPermohonan>(
                value: value,
                child: Text(
                  value == JenisPermohonan.pasangBaru
                      ? 'Pasang Baru'
                      : 'Perubahan Daya',
                ),
              );
            }).toList(),
            onChanged: (JenisPermohonan? newValue) {
              setState(() {
                _selectedJenisPermohonan = newValue;
              });
            },
            validator: (value) =>
                value == null ? 'Jenis Permohonan harus dipilih' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dayaController,
            decoration: const InputDecoration(
              labelText: 'Daya (Contoh: 1300 VA)',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Daya harus diisi' : null,
          ),
          const SizedBox(height: 16),
          const Text(
            'Prioritas:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          DropdownButtonFormField<Prioritas>(
            value: _selectedPrioritas,
            hint: const Text('Pilih Prioritas'),
            items: Prioritas.values.map((Prioritas value) {
              return DropdownMenuItem<Prioritas>(
                value: value,
                child: Text(value.toString().split('.').last.capitalize()),
              );
            }).toList(),
            onChanged: (Prioritas? newValue) {
              setState(() {
                _selectedPrioritas = newValue;
              });
            },
            validator: (value) =>
                value == null ? 'Prioritas harus dipilih' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _catatanController,
            decoration: const InputDecoration(
              labelText: 'Catatan Permohonan',
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
