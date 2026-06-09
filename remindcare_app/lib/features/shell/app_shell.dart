import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../history/screens/history_screen.dart';
import '../home/screens/home_screen.dart';
import '../medicines/screens/medicine_list_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../statistics/screens/statistics_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    MedicineListScreen(),
    HistoryScreen(),
    StatisticsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(AppConstants.primaryColor).withOpacity(0.15),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home,
              color: Color(AppConstants.primaryColor)),
            label: 'Beranda'),
          NavigationDestination(
            icon: const Icon(Icons.medication_outlined),
            selectedIcon: const Icon(Icons.medication,
              color: Color(AppConstants.primaryColor)),
            label: 'Obat'),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history,
              color: Color(AppConstants.primaryColor)),
            label: 'Riwayat'),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart,
              color: Color(AppConstants.primaryColor)),
            label: 'Statistik'),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person,
              color: Color(AppConstants.primaryColor)),
            label: 'Profil'),
        ]),
    );
  }
}
