import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/reminder_log_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/schedule_provider.dart';
import '../../../providers/websocket_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user == null) return;

    // Load data
    context.read<ScheduleProvider>().loadAll(auth.token!);

    // Connect WebSocket
    final ws = context.read<WebSocketProvider>();
    ws.connect(auth.token!, auth.user!.id);

    // Real-time: update log saat ada konfirmasi dari lain
    ws.onLogConfirmed((data) {
      context.read<ScheduleProvider>().loadAll(auth.token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✔ Obat sudah diminum (real-time)',
              style: GoogleFonts.poppins()),
          backgroundColor: const Color(AppConstants.secondaryColor),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final schedule = context.watch<ScheduleProvider>();
    final ws       = context.watch<WebSocketProvider>();

    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(AppConstants.primaryColor),
        title: Text('RemindCare', style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // Indikator WebSocket
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              ws.connected ? Icons.wifi : Icons.wifi_off,
              color: ws.connected ? Colors.greenAccent : Colors.white54,
              size: 20)),
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
            onRefresh: () async {
              if (auth.token != null) {
                await context.read<ScheduleProvider>().loadAll(auth.token!);
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                  ...schedule.todayLogs.map((log) =>
                      _buildLogCard(log, auth.token!, auth.user!.id)),
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
        borderRadius: BorderRadius.circular(20)),
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

  Widget _buildLogCard(ReminderLogModel log, String token, int elderlyId) {
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
              onPressed: () async {
                await context.read<ScheduleProvider>().confirmLog(token, log.id);
                // Broadcast ke WebSocket room
                context.read<WebSocketProvider>().broadcastConfirmed(
                    elderlyId, {'log_id': log.id, 'medicine': log.medicineName});
              },
              child: Text('Sudah Minum', style: GoogleFonts.poppins(
                  color: color, fontWeight: FontWeight.bold)))
          else
            Icon(log.isTaken ? Icons.check_circle : Icons.cancel, color: color),
        ]),
      ),
    );
  }
}
