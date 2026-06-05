import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_constants.dart';
import 'features/medicines/screens/medicine_list_screen.dart';

void main() => runApp(const RemindCareApp());

class RemindCareApp extends StatelessWidget {
  const RemindCareApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(AppConstants.primaryColor)),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true),
      home: const MedicineListScreen(),
    );
  }
}
