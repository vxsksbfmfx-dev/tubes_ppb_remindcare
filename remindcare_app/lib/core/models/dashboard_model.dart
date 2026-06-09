import 'reminder_log_model.dart';
import 'stats_model.dart';
import 'user_model.dart';

class TodaySummary {
  final int    total;
  final int    diminum;
  final int    terlewat;
  final int    menunggu;
  final double persen;

  const TodaySummary({
    required this.total, required this.diminum,
    required this.terlewat, required this.menunggu, required this.persen,
  });

  factory TodaySummary.fromJson(Map<String, dynamic> j) => TodaySummary(
    total:    j['total']    as int,
    diminum:  j['diminum']  as int,
    terlewat: j['terlewat'] as int,
    menunggu: j['menunggu'] as int,
    persen:   double.tryParse(j['persen'].toString()) ?? 0,
  );
}

class DashboardData {
  final TodaySummary          today;
  final ReminderLogModel?     nextSchedule;
  final List<ReminderLogModel> todayLogs;
  final List<DailyStatModel>  weeklyStats;
  final UserModel             user;

  const DashboardData({
    required this.today, this.nextSchedule,
    required this.todayLogs, required this.weeklyStats, required this.user,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
    today:        TodaySummary.fromJson(j['today'] as Map<String, dynamic>),
    nextSchedule: j['next_schedule'] != null
        ? ReminderLogModel.fromJson(j['next_schedule'] as Map<String, dynamic>) : null,
    todayLogs: (j['today_logs'] as List)
        .map((e) => ReminderLogModel.fromJson(e as Map<String, dynamic>)).toList(),
    weeklyStats: (j['weekly_stats'] as List)
        .map((e) => DailyStatModel.fromJson(e as Map<String, dynamic>)).toList(),
    user: UserModel.fromJson(j['user'] as Map<String, dynamic>),
  );
}
