import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/auth_gate.dart'; // Untuk navigasi setelah logout
import 'auth/change_password_screen.dart'; // Import layar ganti password

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  static const String routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = _user?.id;
    final email = _user?.email;
    if (userId == null || email == null) return;
    final response = await Supabase.instance.client
        .from('profile')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (response == null) {
      // Auto-create jika belum ada profile
      final username = email.split('@').first;
      await Supabase.instance.client.from('profile').insert({
        'user_id': userId,
        'username': username,
        'whatsapp': '',
        'role': '',
        'avatar_url': '',
        'updated_at': DateTime.now().toIso8601String(),
      });
      // Query ulang agar _profile terisi
      final newProfile = await Supabase.instance.client
          .from('profile')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _profile = newProfile ?? {};
        });
      }
    } else if (mounted) {
      setState(() {
        _profile = response;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        // Arahkan kembali ke AuthGate, yang akan menangani pengalihan ke LoginScreen
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AuthGate.routeName, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal logout: ${e.toString()}')),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final usernameController = TextEditingController(
      text: _profile?['username'] ?? '',
    );
    final whatsappController = TextEditingController(
      text: _profile?['whatsapp'] ?? '',
    );
    final roleController = TextEditingController(text: _profile?['role'] ?? '');
    final avatarController = TextEditingController(
      text: _profile?['avatar_url'] ?? '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: whatsappController,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp',
                    prefixIcon: Icon(Icons.chat_bubble_outline),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roleController,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.work_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: avatarController,
                  decoration: const InputDecoration(
                    labelText: 'Avatar URL',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final userId = _user?.id;
                if (userId == null) return;
                await Supabase.instance.client
                    .from('profile')
                    .update({
                      'username': usernameController.text.trim(),
                      'whatsapp': whatsappController.text.trim(),
                      'role': roleController.text.trim(),
                      'avatar_url': avatarController.text.trim(),
                      'updated_at': DateTime.now().toIso8601String(),
                    })
                    .eq('user_id', userId);
                if (mounted) {
                  Navigator.of(context).pop();
                  _loadProfile();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = _user?.createdAt != null
        ? DateTime.tryParse(_user!.createdAt)
        : null;
    final lastSignIn = _user?.lastSignInAt != null
        ? DateTime.tryParse(_user!.lastSignInAt ?? '')
        : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.black,
                  size: 22,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Avatar besar di tengah
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        _profile?['avatar_url'] != null &&
                            _profile!['avatar_url'] != ''
                        ? NetworkImage(_profile!['avatar_url'])
                        : null,
                    child:
                        _profile?['avatar_url'] == null ||
                            _profile!['avatar_url'] == ''
                        ? Icon(
                            Icons.person,
                            color: Colors.blueGrey.shade300,
                            size: 64,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 22,
                          color: Colors.blueGrey,
                        ),
                        tooltip: 'Edit Profile',
                        onPressed: _showEditProfileDialog,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Nama dan email
            Text(
              _profile?['username'] ?? '-',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _user?.email ?? '-',
              style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            // Section Account
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Account',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Info Card List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                children: [
                  _ProfileInfoTile(
                    icon: Icons.chat_bubble_outline,
                    label: 'WhatsApp Number',
                    value: _profile?['whatsapp'] ?? '-',
                  ),
                  const SizedBox(height: 14),
                  _ProfileInfoTile(
                    icon: Icons.work_outline_rounded,
                    label: 'Role',
                    value: _profile?['role'] ?? '-',
                  ),
                  const SizedBox(height: 14),
                  _ProfileInfoTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Account Created',
                    value: createdAt != null
                        ? 'Joined on ${_formatDate(createdAt)}'
                        : '-',
                  ),
                  const SizedBox(height: 14),
                  _ProfileInfoTile(
                    icon: Icons.access_time_outlined,
                    label: 'Last Sign In',
                    value: lastSignIn != null
                        ? 'Last signed in on ${_formatDate(lastSignIn)}'
                        : '-',
                  ),
                  const SizedBox(height: 14),
                  _ProfileInfoTile(
                    icon: Icons.mail_outline,
                    label: 'Email Verified',
                    valueWidget: _user?.emailConfirmedAt != null
                        ? const Icon(Icons.check, color: Colors.black, size: 22)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            // Tombol aksi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pushNamed(ChangePasswordScreen.routeName);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade100),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Change Password'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _signOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Format: Jan 15, 2023
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.black87, size: 22),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                if (value != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.5),
                    child: Text(
                      value!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (valueWidget != null) ...[const SizedBox(width: 8), valueWidget!],
        ],
      ),
    );
  }
}
