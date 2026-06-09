import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _ageCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    _ageCtrl   = TextEditingController(text: widget.user.age?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<ProfileProvider>().updateProfile(
      name:  _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      age:   _ageCtrl.text.isEmpty ? null : int.tryParse(_ageCtrl.text),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Profil diperbarui!'
          : context.read<ProfileProvider>().message),
        backgroundColor: ok ? const Color(AppConstants.secondaryColor) : Colors.red));
      if (ok) Navigator.pop(context);
    }
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? type, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c, keyboardType: type,
        style: GoogleFonts.poppins(),
        validator: validator,
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
        title: Text('Edit Profil', style: GoogleFonts.poppins(
          color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(children: [
            _field(_nameCtrl, 'Nama Lengkap',
              validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null),
            _field(_phoneCtrl, 'Nomor Telepon', type: TextInputType.phone),
            _field(_ageCtrl, 'Usia', type: TextInputType.number),
            const SizedBox(height: 8),
            Consumer<ProfileProvider>(
              builder: (_, prov, __) => SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: prov.isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppConstants.primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: prov.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Simpan', style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))))),
          ]))),
    );
  }
}
