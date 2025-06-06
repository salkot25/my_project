import 'package:flutter/material.dart';
import 'app.dart'; // Pastikan ini mengarah ke file app.dart yang benar
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url:
        'https://sobypfstfkaslkcnvpfg.supabase.co', // Ganti dengan URL Supabase Anda
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNvYnlwZnN0Zmthc2xrY252cGZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxNTc2OTEsImV4cCI6MjA2NDczMzY5MX0.sPN80Hn0Iv51TDwZqEcvMSd2zLoCNZHlpb6vMpLqwl8', // Ganti dengan Anon Key Supabase Anda
  );

  runApp(const MyApp());
}
