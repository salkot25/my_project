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
        'daya': _dayaController.text, // <-- pastikan daya selalu dikirim
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
          // Hapus tampilan detail pelanggan dan ID Permohonan (read only)
          // Jenis Permohonan
          DropdownButtonFormField<JenisPermohonan>(
            value: _selectedJenisPermohonan,
            hint: const Text('Pilih Jenis Permohonan'),
            items: JenisPermohonan.values.map((JenisPermohonan value) {
              return DropdownMenuItem<JenisPermohonan>(
                value: value,
                child: Text(value.label),
              );
            }).toList(),
            onChanged: (JenisPermohonan? newValue) {
              setState(() {
                _selectedJenisPermohonan = newValue;
              });
            },
            validator: (value) =>
                value == null ? 'Jenis Permohonan harus dipilih' : null,
            decoration: InputDecoration(
              labelText: 'Jenis Permohonan',
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: Icon(
                Icons.electric_bolt,
                color: Colors.blue.shade400,
              ),
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
          // Daya
          TextFormField(
            controller: _dayaController,
            decoration: InputDecoration(
              labelText: 'Kebutuhan Daya (VA)',
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: Icon(Icons.flash_on, color: Colors.blue.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Daya harus diisi' : null,
          ),
          const SizedBox(height: 16),
          // Prioritas
          DropdownButtonFormField<Prioritas>(
            value: _selectedPrioritas,
            hint: const Text('Pilih Prioritas'),
            items: Prioritas.values.map((Prioritas value) {
              return DropdownMenuItem<Prioritas>(
                value: value,
                child: Text(value.label),
              );
            }).toList(),
            onChanged: (Prioritas? newValue) {
              setState(() {
                _selectedPrioritas = newValue;
              });
            },
            validator: (value) =>
                value == null ? 'Prioritas harus dipilih' : null,
            decoration: InputDecoration(
              labelText: 'Prioritas',
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: Icon(Icons.flag, color: Colors.blue.shade400),
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
          // Catatan Permohonan
          TextFormField(
            controller: _catatanController,
            decoration: InputDecoration(
              labelText: 'Catatan Permohonan',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
