import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _svc        = AuthService();
  String _role      = 'family';
  bool   _loading   = false;
  bool   _obscure   = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = await _svc.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        role: _role,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Registrasi berhasil!', style: GoogleFonts.poppins()),
          backgroundColor: const Color(AppConstants.secondaryColor)));
        Navigator.pushReplacementNamed(context, '/home',
          arguments: data['token'] as String);
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? type, bool required = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c, keyboardType: type, maxLines: maxLines,
        style: GoogleFonts.poppins(),
        validator: required ? (v) => v!.isEmpty ? '$label wajib diisi' : null : null,
        decoration: InputDecoration(
          labelText: label, filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(AppConstants.primaryColor),
        title: Text('Daftar Akun', style: GoogleFonts.poppins(
          color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(children: [
            _field(_nameCtrl,  'Nama Lengkap'),
            _field(_emailCtrl, 'Email', type: TextInputType.emailAddress),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: GoogleFonts.poppins(),
                validator: (v) => (v?.length ?? 0) < 6
                  ? 'Password minimal 6 karakter' : null,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true, fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
            _field(_phoneCtrl, 'Nomor Telepon', type: TextInputType.phone, required: false),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _role,
                  isExpanded: true,
                  style: GoogleFonts.poppins(),
                  items: const [
                    DropdownMenuItem(value: 'family',  child: Text('Keluarga/Pendamping')),
                    DropdownMenuItem(value: 'elderly', child: Text('Lansia')),
                  ],
                  onChanged: (v) => setState(() => _role = v!)))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConstants.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Daftar', style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
          ]))),
    );
  }
}
