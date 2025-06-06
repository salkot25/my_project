import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  static const String routeName = '/change-password';

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password baru tidak cocok!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text.trim()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diperbarui.')),
        );
        Navigator.of(context).pop(); // Kembali ke ProfileScreen
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ganti Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(labelText: 'Password Baru'),
                  obscureText: true,
                  validator: (value) => value!.isEmpty
                      ? 'Password baru tidak boleh kosong'
                      : (value.length < 6
                            ? 'Password minimal 6 karakter'
                            : null),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                  ),
                  obscureText: true,
                  validator: (value) => value!.isEmpty
                      ? 'Konfirmasi password tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _updatePassword,
                        child: const Text('Simpan Password Baru'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
