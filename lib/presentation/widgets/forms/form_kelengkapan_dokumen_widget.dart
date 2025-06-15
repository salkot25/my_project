import 'package:flutter/material.dart';

class FormKelengkapanDokumenWidget extends StatefulWidget {
  final Function(Map<String, dynamic> formData) onSubmit;
  final Map<String, dynamic>? initialData; // Untuk pre-fill jika ada

  const FormKelengkapanDokumenWidget({
    super.key,
    required this.onSubmit,
    this.initialData,
  });

  @override
  State<FormKelengkapanDokumenWidget> createState() =>
      _FormKelengkapanDokumenWidgetState();
}

class _FormKelengkapanDokumenWidgetState
    extends State<FormKelengkapanDokumenWidget> {
  final _formKey = GlobalKey<FormState>();
  final _catatanController = TextEditingController();

  // Checklist items
  bool _hasNIDI = false;
  bool _hasSLO = false;
  bool _hasNIB = false;
  bool _hasSIUP = false;
  bool _hasIjinTanamTiang = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _hasNIDI = widget.initialData!['has_nidi'] ?? false;
      _hasSLO = widget.initialData!['has_slo'] ?? false;
      _hasNIB = widget.initialData!['has_nib'] ?? false;
      _hasSIUP = widget.initialData!['has_siup'] ?? false;
      _hasIjinTanamTiang = widget.initialData!['has_ijin_tanam_tiang'] ?? false;
      _catatanController.text = widget.initialData!['catatan'] ?? '';
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
        'has_nidi': _hasNIDI,
        'has_slo': _hasSLO,
        'has_nib': _hasNIB,
        'has_siup': _hasSIUP,
        'has_ijin_tanam_tiang': _hasIjinTanamTiang,
        'catatan': _catatanController.text,
      };
      widget.onSubmit(formData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Dokumen yang Diperlukan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // NIDI
            CheckboxListTile(
              value: _hasNIDI,
              onChanged: (val) => setState(() => _hasNIDI = val ?? false),
              title: const Text('NIDI'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.blue.shade400,
            ),
            // SLO
            CheckboxListTile(
              value: _hasSLO,
              onChanged: (val) => setState(() => _hasSLO = val ?? false),
              title: const Text('SLO'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.blue.shade400,
            ),
            // NIB
            CheckboxListTile(
              value: _hasNIB,
              onChanged: (val) => setState(() => _hasNIB = val ?? false),
              title: const Text('NIB'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.blue.shade400,
            ),
            // SIUP
            CheckboxListTile(
              value: _hasSIUP,
              onChanged: (val) => setState(() => _hasSIUP = val ?? false),
              title: const Text('SIUP'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.blue.shade400,
            ),
            // Ijin Tanam Tiang
            CheckboxListTile(
              value: _hasIjinTanamTiang,
              onChanged: (val) =>
                  setState(() => _hasIjinTanamTiang = val ?? false),
              title: const Text('Ijin Tanam Tiang'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.blue.shade400,
            ),
            const SizedBox(height: 16),
            // Catatan
            TextFormField(
              controller: _catatanController,
              decoration: InputDecoration(
                labelText: 'Catatan',
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
            const SizedBox(height: 16), // Add bottom padding for scrolling
          ],
        ),
      ),
    );
  }
}
