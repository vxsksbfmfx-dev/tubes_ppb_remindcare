import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/reminder_log_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/schedule_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final auth = context.read<AuthProvider>();
    if (auth.token != null) {
      context.read<ScheduleProvider>().loadAll(auth.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final schedule = context.watch<ScheduleProvider>();

    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(AppConstants.primaryColor),
        title: Text('RemindCare', style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            }),
        ]),
      body: schedule.loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header card
                _buildSummaryCard(schedule.takenToday, schedule.totalToday),
                const SizedBox(height: 20),
                Text('Jadwal Hari Ini', style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (schedule.error != null)
                  Center(child: Text(schedule.error!, style: GoogleFonts.poppins(color: Colors.red)))
                else if (schedule.todayLogs.isEmpty)
                  Center(child: Text('Tidak ada jadwal hari ini',
                      style: GoogleFonts.poppins(color: Colors.grey)))
                else
                  ...schedule.todayLogs.map((log) => _buildLogCard(log, auth.token!)),
              ],
            ),
          ),
    );
  }

  Widget _buildSummaryCard(int taken, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(AppConstants.primaryColor), Color(0xFF1565C0)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Kepatuhan Hari Ini', style: GoogleFonts.poppins(
              color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text('$taken / $total dosis', style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ]),
        SizedBox(
          width: 64, height: 64,
          child: CircularProgressIndicator(
            value: total > 0 ? taken / total : 0,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 6)),
      ]),
    );
  }

  Widget _buildLogCard(ReminderLogModel log, String token) {
    final color = log.isTaken  ? const Color(AppConstants.secondaryColor)
                : log.isMissed ? const Color(AppConstants.warningColor)
                : const Color(AppConstants.primaryColor);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(Icons.medication_rounded, color: color)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(log.medicineName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            Text(
              '${log.scheduledAt.hour.toString().padLeft(2,'0')}:${log.scheduledAt.minute.toString().padLeft(2,'0')}',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
          ])),
          if (log.isPending)
            TextButton(
              onPressed: () => context.read<ScheduleProvider>().confirmLog(token, log.id),
              child: Text('Sudah Minum', style: GoogleFonts.poppins(
                  color: color, fontWeight: FontWeight.bold)))
          else
            Icon(log.isTaken ? Icons.check_circle : Icons.cancel, color: color),
        ]),
      ),
    );
  }
}
