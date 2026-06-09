import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/services/session_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  Future<void> _pickAvatar() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery, imageQuality: 80, maxWidth: 600);
    if (img == null || !mounted) return;

    final ok = await context.read<ProfileProvider>().uploadAvatar(File(img.path));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Avatar diperbarui!' : context.read<ProfileProvider>().message),
        backgroundColor: ok ? const Color(AppConstants.secondaryColor) : Colors.red));
    }
  }

  Future<void> _logout() async {
    await SessionService().clearSession();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(AppConstants.primaryColor),
        title: Text('Profil Saya', style: GoogleFonts.poppins(
          color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout)]),
      body: Consumer<ProfileProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = prov.user;
          if (user == null) {
            return Center(child: Text('Gagal memuat profil', style: GoogleFonts.poppins()));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              // Avatar
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(alignment: Alignment.bottomRight, children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: const Color(AppConstants.primaryColor).withOpacity(0.15),
                    backgroundImage: user.avatar != null
                      ? NetworkImage('${AppConstants.baseUrl}${user.avatar}') : null,
                    child: user.avatar == null
                      ? const Icon(Icons.person, size: 56,
                          color: Color(AppConstants.primaryColor)) : null),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(AppConstants.primaryColor), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16)),
                ])),
              const SizedBox(height: 16),
              Text(user.name, style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.bold)),
              Text(user.email, style: GoogleFonts.poppins(color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryColor).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(user.role == 'elderly' ? 'Lansia' : 'Keluarga/Pendamping',
                  style: GoogleFonts.poppins(
                    color: const Color(AppConstants.primaryColor),
                    fontWeight: FontWeight.w600, fontSize: 13))),
              const SizedBox(height: 32),
              _infoTile(Icons.phone, 'Telepon', user.phone ?? '-'),
              _infoTile(Icons.cake, 'Usia', user.age != null ? '${user.age} tahun' : '-'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(user: user))),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: Text('Edit Profil', style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppConstants.primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
            ]));
        }),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(children: [
        Icon(icon, color: const Color(AppConstants.primaryColor)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ]),
      ]));
  }
}
