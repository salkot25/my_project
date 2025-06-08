import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VendorLaporanJaringanForm extends StatefulWidget {
  final void Function(Map<String, dynamic> data) onSubmit;
  final Map<String, dynamic>? initialValues;
  const VendorLaporanJaringanForm({
    super.key,
    required this.onSubmit,
    this.initialValues,
  });

  @override
  State<VendorLaporanJaringanForm> createState() =>
      _VendorLaporanJaringanFormState();
}

class _VendorLaporanJaringanFormState extends State<VendorLaporanJaringanForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _tanggal;
  TimeOfDay? _waktu;
  String? _jenisPekerjaan;
  final TextEditingController _catatanController = TextEditingController();
  bool _siapPasangApp = false;

  final List<String> jenisPekerjaanList = [
    'Pemasangan Tiang',
    'Pemasangan Trafo',
    'Perluasan JTR',
    'Perluasan JTM',
    'Penjumperan',
  ];

  @override
  void initState() {
    super.initState();
    final iv = widget.initialValues;
    DateTime? dt;
    if (iv != null &&
        iv['tanggal'] != null &&
        iv['tanggal'].toString().isNotEmpty) {
      try {
        dt = iv['tanggal'] is DateTime
            ? iv['tanggal']
            : DateTime.tryParse(iv['tanggal'].toString());
      } catch (_) {}
    }
    final now = DateTime.now();
    // Gabungkan tanggal dan waktu dari data awal jika ada, jika tidak pakai now
    if (dt != null) {
      _tanggal = DateTime(dt.year, dt.month, dt.day);
      _waktu = TimeOfDay(hour: dt.hour, minute: dt.minute);
    } else {
      _tanggal = DateTime(now.year, now.month, now.day);
      _waktu = TimeOfDay(hour: now.hour, minute: now.minute);
    }
    if (iv != null) {
      if (iv['jenis_pekerjaan'] != null) {
        _jenisPekerjaan = iv['jenis_pekerjaan'].toString();
      }
      if (iv['catatan'] != null) {
        _catatanController.text = iv['catatan'].toString();
      }
      if (iv['siap_pasang_app'] != null) {
        _siapPasangApp =
            iv['siap_pasang_app'] == true || iv['siap_pasang_app'] == 1;
      }
    }
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tanggal
          TextFormField(
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Tanggal',
              prefixIcon: Icon(Icons.date_range),
            ),
            controller: TextEditingController(
              text: _tanggal == null
                  ? ''
                  : _tanggal!.toIso8601String().substring(0, 10),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _tanggal ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _tanggal = picked);
              }
            },
            validator: (val) => _tanggal == null ? 'Tanggal wajib diisi' : null,
          ),
          const SizedBox(height: 16),
          // Waktu
          TextFormField(
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Waktu',
              prefixIcon: Icon(Icons.access_time),
            ),
            controller: TextEditingController(
              text: _waktu == null ? '' : _waktu!.format(context),
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _waktu ?? TimeOfDay.now(),
              );
              if (picked != null) {
                setState(() => _waktu = picked);
              }
            },
            validator: (val) => _waktu == null ? 'Waktu wajib diisi' : null,
          ),
          const SizedBox(height: 16),
          // Jenis Pekerjaan
          DropdownButtonFormField<String>(
            value: _jenisPekerjaan,
            items: jenisPekerjaanList
                .map(
                  (jenis) => DropdownMenuItem(value: jenis, child: Text(jenis)),
                )
                .toList(),
            onChanged: (val) => setState(() => _jenisPekerjaan = val),
            decoration: const InputDecoration(
              labelText: 'Jenis Pekerjaan',
              prefixIcon: Icon(Icons.build),
            ),
            validator: (val) => val == null || val.isEmpty
                ? 'Jenis pekerjaan wajib dipilih'
                : null,
          ),
          const SizedBox(height: 16),
          // Catatan (opsional)
          TextFormField(
            controller: _catatanController,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              prefixIcon: Icon(Icons.note_alt_outlined),
            ),
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          // Siap Pasang APP
          CheckboxListTile(
            value: _siapPasangApp,
            onChanged: (val) => setState(() => _siapPasangApp = val ?? false),
            title: const Text('Apakah sudah siap dipasang APP?'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Kirim Laporan'),
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  // Gabungkan tanggal dan waktu
                  DateTime? tanggalWaktu;
                  if (_tanggal != null && _waktu != null) {
                    tanggalWaktu = DateTime(
                      _tanggal!.year,
                      _tanggal!.month,
                      _tanggal!.day,
                      _waktu!.hour,
                      _waktu!.minute,
                    );
                  }
                  widget.onSubmit({
                    'tanggal': tanggalWaktu,
                    'jenis_pekerjaan': _jenisPekerjaan,
                    'catatan': _catatanController.text.trim(),
                    'siap_pasang_app': _siapPasangApp,
                    'user_id': Supabase.instance.client.auth.currentUser?.id,
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
