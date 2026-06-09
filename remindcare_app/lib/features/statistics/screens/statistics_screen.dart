import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/stats_model.dart';
import '../../../core/providers/history_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(AppConstants.primaryColor),
        title: Text('Statistik Kepatuhan', style: GoogleFonts.poppins(
          color: Colors.white, fontWeight: FontWeight.bold))),
      body: Consumer<HistoryProvider>(
        builder: (_, prov, __) {
          final monthly = prov.monthly;
          final weekly  = prov.weekly;

          if (monthly == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // ── Ringkasan Bulanan ──────────────────────────
              _SectionHeader(title: 'Ringkasan Bulan Ini'),
              const SizedBox(height: 12),
              _MonthlyCard(summary: monthly),
              const SizedBox(height: 24),

              // ── Grafik Bar 7 Hari ──────────────────────────
              _SectionHeader(title: '7 Hari Terakhir'),
              const SizedBox(height: 12),
              _WeeklyBarChart(data: weekly),
              const SizedBox(height: 24),

              // ── Legend ────────────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _LegendDot(color: Colors.green, label: 'Diminum'),
                const SizedBox(width: 20),
                _LegendDot(color: Colors.red,   label: 'Terlewat'),
                const SizedBox(width: 20),
                _LegendDot(color: Colors.grey,  label: 'Total'),
              ]),
            ]));
        }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) =>
    Align(alignment: Alignment.centerLeft,
      child: Text(title, style: GoogleFonts.poppins(
        fontWeight: FontWeight.bold, fontSize: 16)));
}

class _MonthlyCard extends StatelessWidget {
  final MonthlySummaryModel summary;
  const _MonthlyCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final persen = summary.persentaseKepatuhan;
    final color  = persen >= 80 ? Colors.green
                 : persen >= 50 ? Colors.orange : Colors.red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
      child: Column(children: [
        Text('$persen%', style: GoogleFonts.poppins(
          fontSize: 52, fontWeight: FontWeight.bold, color: color)),
        Text('Tingkat Kepatuhan', style: GoogleFonts.poppins(color: Colors.grey)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _StatChip(label: 'Total',    value: summary.total,    color: Colors.blue),
          _StatChip(label: 'Diminum',  value: summary.diminum,  color: Colors.green),
          _StatChip(label: 'Terlewat', value: summary.terlewat, color: Colors.red),
          _StatChip(label: 'Menunggu', value: summary.menunggu, color: Colors.orange),
        ]),
      ]));
  }
}

class _StatChip extends StatelessWidget {
  final String label; final int value; final Color color;
  const _StatChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) =>
    Column(children: [
      Text('$value', style: GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
    ]);
}

class _WeeklyBarChart extends StatelessWidget {
  final List<DailyStatModel> data;
  const _WeeklyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text('Tidak ada data', style: GoogleFonts.poppins(color: Colors.grey)));
    }
    final maxVal = data.fold<int>(0, (m, d) => d.total > m ? d.total : m);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((d) {
          final day = d.tanggal.substring(8); // DD
          return _BarGroup(
            day: day, total: d.total, diminum: d.diminum, terlewat: d.terlewat,
            maxVal: maxVal);
        }).toList()));
  }
}

class _BarGroup extends StatelessWidget {
  final String day;
  final int total, diminum, terlewat, maxVal;
  const _BarGroup({required this.day, required this.total,
      required this.diminum, required this.terlewat, required this.maxVal});

  @override
  Widget build(BuildContext context) {
    const maxH = 130.0;
    final tH = maxVal == 0 ? 0.0 : (total   / maxVal * maxH);
    final dH = maxVal == 0 ? 0.0 : (diminum  / maxVal * maxH);
    final mH = maxVal == 0 ? 0.0 : (terlewat / maxVal * maxH);

    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        _Bar(height: dH, color: Colors.green),
        const SizedBox(width: 2),
        _Bar(height: mH, color: Colors.red),
        const SizedBox(width: 2),
        _Bar(height: tH, color: Colors.grey.shade300),
      ]),
      const SizedBox(height: 4),
      Text(day, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
    ]);
  }
}

class _Bar extends StatelessWidget {
  final double height; final Color color;
  const _Bar({required this.height, required this.color});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 500),
    width: 10, height: height.clamp(2, 130),
    decoration: BoxDecoration(
      color: color, borderRadius: BorderRadius.circular(4)));
}

class _LegendDot extends StatelessWidget {
  final Color color; final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(
      color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.poppins(fontSize: 12)),
  ]);
}
