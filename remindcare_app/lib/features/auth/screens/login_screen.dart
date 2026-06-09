import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import 'register_screen.dart';
import '../../home/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;
  bool _loading    = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login gagal'), backgroundColor: Colors.red));
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.loginWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login Google gagal'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.medical_services_rounded,
                  size: 72, color: Color(AppConstants.primaryColor)),
                const SizedBox(height: 12),
                Text('RemindCare',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 28, fontWeight: FontWeight.bold,
                    color: const Color(AppConstants.primaryColor))),
                Text('Reminder Minum Obat',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey[600])),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
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
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 karakter' : null,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure)),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 24),

                SizedBox(height: 52,
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

                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('atau', style: GoogleFonts.poppins(color: Colors.grey))),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),

                SizedBox(height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _loginGoogle,
                    icon: Image.network(
                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      width: 22, height: 22,
                      errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 28)),
                    label: Text('Masuk dengan Google',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white))),
                const SizedBox(height: 24),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Belum punya akun? ', style: GoogleFonts.poppins()),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Text('Daftar',
                      style: GoogleFonts.poppins(
                        color: const Color(AppConstants.primaryColor),
                        fontWeight: FontWeight.bold))),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
