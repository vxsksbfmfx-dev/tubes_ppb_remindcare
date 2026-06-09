import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/session_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.forward();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final session  = SessionService();
    final loggedIn = await session.isLoggedIn();
    if (!loggedIn) { Navigator.pushReplacementNamed(context, '/login'); return; }
    try {
      final token = await session.getToken();
      await AuthService().me(token!);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (_) {
      await session.clearSession();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.primaryColor),
      body: FadeTransition(
        opacity: _fade,
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(28)),
            child: const Icon(Icons.medication_rounded,
              color: Color(AppConstants.primaryColor), size: 60)),
          const SizedBox(height: 24),
          Text('RemindCare', style: GoogleFonts.poppins(
            fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Reminder Jadwal Minum Obat', style: GoogleFonts.poppins(
            color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 48),
          const CircularProgressIndicator(color: Colors.white54),
        ]))),
    );
  }
}
