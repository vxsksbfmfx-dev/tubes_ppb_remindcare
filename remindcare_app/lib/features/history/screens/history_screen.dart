import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/reminder_log_model.dart';
import '../../../core/providers/history_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadHistory();
    });
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        context.read<HistoryProvider>().loadHistory(loadMore: true);
      }
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final now  = DateTime.now();
    final pick = await showDatePicker(
      context: context, initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)), lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(AppConstants.primaryColor))),
        child: child!));
    if (pick != null && mounted) {
      final str = '${pick.year}-${pick.month.toString().padLeft(2,'0')}-${pick.day.toString().padLeft(2,'0')}';
      context.read<HistoryProvider>().setDateFilter(str);
    }
  }

  Color _statusColor(String s) => switch (s) {
    'confirmed' => Colors.green,
    'missed'    => Colors.red,
    _           => Colors.orange,
  };

  IconData _statusIcon(String s) => switch (s) {
    'confirmed' => Icons.check_circle,
    'missed'    => Icons.cancel,
    _           => Icons.schedule,
  };

  String _statusLabel(String s) => switch (s) {
    'confirmed' => 'Diminum',
    'missed'    => 'Terlewat',
    _           => 'Menunggu',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(AppConstants.primaryColor),
        title: Text('Riwayat Minum Obat', style: GoogleFonts.poppins(
          color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Consumer<HistoryProvider>(
            builder: (_, prov, __) => Row(children: [
              if (prov.dateFilter.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  tooltip: 'Reset filter',
                  onPressed: () => prov.setDateFilter('')),
              IconButton(
                icon: const Icon(Icons.calendar_month, color: Colors.white),
                onPressed: _pickDate),
            ]))]),
      body: Consumer<HistoryProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading && prov.history.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.history.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.history, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Belum ada riwayat', style: GoogleFonts.poppins(color: Colors.grey)),
            ]));
          }
          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: prov.history.length + (prov.hasMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (i >= prov.history.length) {
                return const Center(
                  child: Padding(padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator()));
              }
              return _LogTile(log: prov.history[i],
                statusColor: _statusColor, statusIcon: _statusIcon,
                statusLabel: _statusLabel);
            });
        }),
    );
  }
}

class _LogTile extends StatelessWidget {
  final ReminderLogModel log;
  final Color Function(String)  statusColor;
  final IconData Function(String) statusIcon;
  final String Function(String) statusLabel;
  const _LogTile({required this.log, required this.statusColor,
      required this.statusIcon, required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(log.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(statusIcon(log.status), color: color, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(log.medicineName ?? 'Obat #${log.scheduleId}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          if (log.dosage != null)
            Text('Dosis: ${log.dosage}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          Text(log.scheduledAt.substring(0, 16).replaceFirst('T', ' '),
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20)),
          child: Text(statusLabel(log.status),
            style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
      ]));
  }
}
