import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/services/medicine_service.dart';

class MedicineFormScreen extends StatefulWidget {
  final MedicineModel? medicine;
  const MedicineFormScreen({super.key, this.medicine});
  @override
  State<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _svc         = MedicineService();
  late final _nameCtrl    = TextEditingController(text: widget.medicine?.name ?? '');
  late final _genericCtrl = TextEditingController(text: widget.medicine?.genericName ?? '');
  late final _brandCtrl   = TextEditingController(text: widget.medicine?.brandName ?? '');
  late final _descCtrl    = TextEditingController(text: widget.medicine?.description ?? '');
  bool _saving = false;

  bool get _isEdit => widget.medicine != null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = {
        'name':         _nameCtrl.text.trim(),
        'generic_name': _genericCtrl.text.trim(),
        'brand_name':   _brandCtrl.text.trim(),
        'description':  _descCtrl.text.trim(),
      };
      if (_isEdit) {
        await _svc.update(widget.medicine!.id, payload);
      } else {
        await _svc.create(payload);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Obat diperbarui' : 'Obat ditambahkan',
            style: GoogleFonts.poppins()),
          backgroundColor: const Color(AppConstants.secondaryColor)));
      }
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.poppins(),
        validator: required ? (v) => v!.isEmpty ? '$label wajib diisi' : null : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(AppConstants.primaryColor), width: 2)))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(AppConstants.primaryColor),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context)),
        title: Text(_isEdit ? 'Edit Obat' : 'Tambah Obat',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(key: _formKey, child: Column(children: [
          _field(_nameCtrl,    'Nama Obat',        required: true),
          _field(_genericCtrl, 'Nama Generik'),
          _field(_brandCtrl,   'Nama Merek / Brand'),
          _field(_descCtrl,    'Deskripsi', maxLines: 3),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _saving
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('Simpan', style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
        ]))));
  }
}
