import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/profile_provider.dart';
import 'core/providers/schedule_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/medicines/screens/medicine_list_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/splash/splash_screen.dart';

void main() => runApp(const RemindCareApp());

class RemindCareApp extends StatelessWidget {
  const RemindCareApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(AppConstants.primaryColor)),
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true),
        initialRoute: '/',
        routes: {
          '/':        (_) => const SplashScreen(),
          '/login':   (_) => const LoginScreen(),
          '/home':    (_) => const MedicineListScreen(),
          '/profile': (_) => const ProfileScreen(),
        },
      ),
    );
  }
}
