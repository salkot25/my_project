import 'package:flutter/material.dart';

class FormRabWidget extends StatefulWidget {
  final Function(Map<String, dynamic> formData) onSubmit;
  final Map<String, dynamic>? initialData; // Untuk pre-fill jika ada
  final Map<String, dynamic>? surveyData; // Data dari tahap survey

  const FormRabWidget({
    super.key,
    required this.onSubmit,
    this.initialData,
    this.surveyData,
  });

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
          if (widget.surveyData != null && widget.surveyData!.isNotEmpty) ...[
            Text(
              'Informasi dari Survey Lokasi:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            if (widget.surveyData!['jenis_layanan'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(
                  'Jenis Layanan: ${widget.surveyData!['jenis_layanan']}',
                ),
              ),
            if (widget.surveyData!['alamat_survey'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(
                  'Alamat Survey: ${widget.surveyData!['alamat_survey']}',
                ),
              ),
            if (widget.surveyData!['catatan_survey'] != null &&
                widget.surveyData!['catatan_survey'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(
                  'Catatan Survey: ${widget.surveyData!['catatan_survey']}',
                ),
              ),
            const Divider(height: 20, thickness: 1),
          ],
          Text(
            'Input Data RAB',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ukuranTrafoController,
            decoration: InputDecoration(
              labelText: 'Ukuran Trafo (kVA)',
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: Icon(
                Icons.electrical_services,
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
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty
                ? 'Ukuran Trafo harus diisi'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _jumlahTiangController,
            decoration: InputDecoration(
              labelText: 'Jumlah Tiang',
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: Icon(Icons.account_tree, color: Colors.blue.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty
                ? 'Jumlah Tiang harus diisi'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _catatanController,
            decoration: InputDecoration(
              labelText: 'Catatan RAB',
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
