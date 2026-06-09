import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/dashboard_model.dart';
import '../../../core/models/reminder_log_model.dart';
import '../../../core/providers/dashboard_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  Future<void> _refresh() => context.read<DashboardProvider>().load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      body: Consumer<DashboardProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading && prov.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.status == DashboardStatus.error) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              Text(prov.message, style: GoogleFonts.poppins(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _refresh, child: const Text('Coba Lagi')),
            ]));
          }
          final data = prov.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(slivers: [
              _buildAppBar(data),
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  _TodaySummaryCard(today: data.today),
                  const SizedBox(height: 20),
                  if (data.nextSchedule != null) ...[
                    _NextScheduleCard(log: data.nextSchedule!, onConfirm: () {
                      context.read<DashboardProvider>().confirmLog(data.nextSchedule!.id);
                    }),
                    const SizedBox(height: 20),
                  ],
                  _SectionLabel('Jadwal Hari Ini'),
                  const SizedBox(height: 12),
                  ...data.todayLogs.map((log) => _TodayLogTile(
                    log: log,
                    onConfirm: log.isPending
                        ? () => context.read<DashboardProvider>().confirmLog(log.id)
                        : null)),
                  if (data.todayLogs.isEmpty)
                    _EmptyState('Belum ada jadwal hari ini', Icons.event_available),
                ]))),
            ]));
        }),
    );
  }

  SliverAppBar _buildAppBar(DashboardData data) {
    final greeting = _greeting();
    return SliverAppBar(
      expandedHeight: 140,
      floating: true, pinned: true,
      backgroundColor: const Color(AppConstants.primaryColor),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(AppConstants.primaryColor), Color(0xFF1565C0)])),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$greeting,', style: GoogleFonts.poppins(
              color: Colors.white70, fontSize: 14)),
            Text(data.user.name, style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ]))));
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _TodaySummaryCard extends StatelessWidget {
  final TodaySummary today;
  const _TodaySummaryCard({required this.today});

  @override
  Widget build(BuildContext context) {
    final color = today.persen >= 80 ? Colors.green
                : today.persen >= 50 ? Colors.orange : Colors.red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
      child: Column(children: [
        Text('Kepatuhan Hari Ini', style: GoogleFonts.poppins(
          color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 90, height: 90,
            child: CircularProgressIndicator(
              value: today.persen / 100,
              strokeWidth: 9,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color))),
          Text('${today.persen.toStringAsFixed(0)}%', style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _Chip('Diminum',  today.diminum,  Colors.green),
          _Chip('Terlewat', today.terlewat, Colors.red),
          _Chip('Menunggu', today.menunggu, Colors.orange),
          _Chip('Total',    today.total,    Colors.blue),
        ]),
      ]));
  }
}

class _Chip extends StatelessWidget {
  final String label; final int val; final Color color;
  const _Chip(this.label, this.val, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text('$val', style: GoogleFonts.poppins(
      fontSize: 20, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
  ]);
}

class _NextScheduleCard extends StatelessWidget {
  final ReminderLogModel log;
  final VoidCallback     onConfirm;
  const _NextScheduleCard({required this.log, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final time = log.scheduledAt.substring(11, 16);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(AppConstants.secondaryColor), Color(0xFF00897B)]),
        borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(Icons.notifications_active, color: Colors.white, size: 36),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Jadwal Berikutnya — $time', style: GoogleFonts.poppins(
            color: Colors.white70, fontSize: 12)),
          Text(log.medicineName ?? 'Obat', style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          if (log.dosage != null)
            Text('Dosis: ${log.dosage}', style: GoogleFonts.poppins(
              color: Colors.white70, fontSize: 12)),
        ])),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text('Minum', style: GoogleFonts.poppins(
            color: const Color(AppConstants.secondaryColor),
            fontWeight: FontWeight.bold))),
      ]));
  }
}

class _TodayLogTile extends StatelessWidget {
  final ReminderLogModel log;
  final VoidCallback?    onConfirm;
  const _TodayLogTile({required this.log, this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final color = log.isDone ? Colors.green : log.isMissed ? Colors.red : Colors.orange;
    final icon  = log.isDone ? Icons.check_circle
                : log.isMissed ? Icons.cancel : Icons.schedule;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Row(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(log.medicineName ?? 'Obat', style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600)),
          Text(log.scheduledAt.substring(11, 16),
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        ])),
        if (onConfirm != null)
          TextButton(
            onPressed: onConfirm,
            style: TextButton.styleFrom(
              foregroundColor: const Color(AppConstants.primaryColor)),
            child: Text('Konfirmasi', style: GoogleFonts.poppins(fontSize: 12,
              fontWeight: FontWeight.bold))),
      ]));
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) =>
    Align(alignment: Alignment.centerLeft,
      child: Text(text, style: GoogleFonts.poppins(
        fontWeight: FontWeight.bold, fontSize: 15)));
}

class _EmptyState extends StatelessWidget {
  final String text; final IconData icon;
  const _EmptyState(this.text, this.icon);
  @override
  Widget build(BuildContext context) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(children: [
        Icon(icon, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text(text, style: GoogleFonts.poppins(color: Colors.grey)),
      ]));
}
