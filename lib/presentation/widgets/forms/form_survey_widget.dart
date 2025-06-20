import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

enum HasilSurvey { tanpaPerluasan, perluasanTrafo, perluasanJtm, perluasanJtr }

extension HasilSurveyExt on HasilSurvey {
  String get label {
    switch (this) {
      case HasilSurvey.tanpaPerluasan:
        return 'Tanpa Perluasan';
      case HasilSurvey.perluasanTrafo:
        return 'Perluasan Trafo';
      case HasilSurvey.perluasanJtm:
        return 'Perluasan JTM';
      case HasilSurvey.perluasanJtr:
        return 'Perluasan JTR';
    }
  }
}

class FormSurveyWidget extends StatefulWidget {
  final Function(Map<String, dynamic> formData) onSubmit;
  final Map<String, dynamic>? initialData; // Untuk pre-fill jika ada

  const FormSurveyWidget({super.key, required this.onSubmit, this.initialData});

  @override
  State<FormSurveyWidget> createState() => _FormSurveyWidgetState();
}

class _FormSurveyWidgetState extends State<FormSurveyWidget> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  HasilSurvey? _selectedHasilSurvey;
  final _catatanController = TextEditingController();
  String? _tagLokasi;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _selectedDate = widget.initialData!['tanggal_survey'] != null
          ? DateTime.tryParse(widget.initialData!['tanggal_survey'])
          : null;
      _selectedHasilSurvey = widget.initialData!['hasil_survey'] != null
          ? HasilSurvey.values.firstWhere(
              (e) =>
                  e.toString().split('.').last ==
                  widget.initialData!['hasil_survey'],
            )
          : null;
      _catatanController.text = widget.initialData!['catatan_survey'] ?? '';
      if (widget.initialData!['tag_lokasi'] != null) {
        _tagLokasi = widget.initialData!['tag_lokasi'];
      } else if (widget.initialData!['latitude'] != null &&
          widget.initialData!['longitude'] != null) {
        _tagLokasi =
            " 2${widget.initialData!['latitude']}, ${widget.initialData!['longitude']}";
      }
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
        'tanggal_survey': _selectedDate?.toIso8601String(),
        'tag_lokasi': _tagLokasi,
        'hasil_survey': _selectedHasilSurvey?.toString().split('.').last,
        'catatan_survey': _catatanController.text,
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
              labelText: 'Tanggal Survey',
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: Icon(Icons.event, color: Colors.blue.shade400),
              hintText: _selectedDate == null
                  ? 'Pilih Tanggal'
                  : DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate!),
              suffixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
            ),
            readOnly: true,
            onTap: () => _selectDate(context),
            validator: (value) =>
                _selectedDate == null ? 'Tanggal survey harus diisi' : null,
          ),
          const SizedBox(height: 16),
          // Tagging Lokasi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Lokasi',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: Icon(
                      Icons.location_on,
                      color: Colors.blue.shade400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  controller: TextEditingController(text: _tagLokasi ?? ''),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Tag lokasi wajib diisi'
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.my_location, color: Colors.blue.shade400),
                    tooltip: 'Ambil Lokasi',
                    onPressed: () async {
                      bool serviceEnabled =
                          await Geolocator.isLocationServiceEnabled();
                      if (!serviceEnabled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Aktifkan layanan lokasi di perangkat.',
                            ),
                          ),
                        );
                        return;
                      }
                      LocationPermission permission =
                          await Geolocator.checkPermission();
                      if (permission == LocationPermission.denied) {
                        permission = await Geolocator.requestPermission();
                        if (permission == LocationPermission.denied) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Izin lokasi ditolak.'),
                            ),
                          );
                          return;
                        }
                      }
                      if (permission == LocationPermission.deniedForever) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Izin lokasi ditolak permanen. Buka pengaturan untuk mengaktifkan.',
                            ),
                          ),
                        );
                        return;
                      }
                      final pos = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );
                      setState(() {
                        _tagLokasi = "${pos.latitude}, ${pos.longitude}";
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<HasilSurvey>(
            value: _selectedHasilSurvey,
            hint: const Text('Pilih Hasil Survey'),
            items: HasilSurvey.values.map((HasilSurvey value) {
              return DropdownMenuItem<HasilSurvey>(
                value: value,
                child: Text(value.label),
              );
            }).toList(),
            onChanged: (HasilSurvey? newValue) =>
                setState(() => _selectedHasilSurvey = newValue),
            validator: (value) =>
                value == null ? 'Hasil survey harus dipilih' : null,
            decoration: InputDecoration(
              labelText: 'Hasil Survey',
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: Icon(Icons.checklist, color: Colors.blue.shade400),
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
              labelText: 'Catatan Survey',
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
