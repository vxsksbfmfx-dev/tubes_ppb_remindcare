import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/schedule_provider.dart';
import 'core/services/fcm_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';

// ── FCM background handler harus di top-level ─────────────
// (sudah di-register di FcmService.init())

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
      ],
      child: const RemindCareApp(),
    ),
  );
}

class RemindCareApp extends StatefulWidget {
  const RemindCareApp({super.key});
  @override
  State<RemindCareApp> createState() => _RemindCareAppState();
}

class _RemindCareAppState extends State<RemindCareApp> {
  final _fcm = FcmService();

  @override
  void initState() {
    super.initState();
    _fcm.init(); // Inisialisasi FCM setelah app jalan
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(AppConstants.primaryColor)),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          if (auth.status == AuthStatus.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
          }
          return auth.isAuth
              ? const HomeScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
