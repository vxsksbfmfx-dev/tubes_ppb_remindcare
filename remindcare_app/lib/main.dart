import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/schedule_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() => runApp(const RemindCareApp());

class RemindCareApp extends StatelessWidget {
  const RemindCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(AppConstants.primaryColor)),
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true),
        initialRoute: '/login',
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home':  (_) => const HomeScreen(),
        },
      ),
    );
  }
}
