import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/session_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _svc       = AuthService();
  final _session   = SessionService();
  bool _loading    = false;
  bool _obscure    = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data  = await _svc.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final token = data['token'] as String;
      final user  = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      // Simpan ke SharedPreferences
      await _session.saveSession(token, user);

      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(children: [
              const SizedBox(height: 60),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryColor),
                  borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.medication_rounded, color: Colors.white, size: 44)),
              const SizedBox(height: 24),
              Text('RemindCare', style: GoogleFonts.poppins(
                fontSize: 28, fontWeight: FontWeight.bold,
                color: const Color(AppConstants.primaryColor))),
              Text('Masuk ke akun Anda', style: GoogleFonts.poppins(
                color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(),
                validator: (v) => v!.isEmpty ? 'Email wajib diisi' : null,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: GoogleFonts.poppins(),
                validator: (v) => v!.isEmpty ? 'Password wajib diisi' : null,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure)),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppConstants.primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Masuk', style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Belum punya akun? ', style: GoogleFonts.poppins(color: Colors.grey)),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: Text('Daftar', style: GoogleFonts.poppins(
                    color: const Color(AppConstants.primaryColor),
                    fontWeight: FontWeight.bold))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
