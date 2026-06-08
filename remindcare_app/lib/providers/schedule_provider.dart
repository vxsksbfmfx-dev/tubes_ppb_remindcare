import 'package:flutter/foundation.dart';
import '../core/models/schedule_model.dart';
import '../core/models/reminder_log_model.dart';
import '../core/services/schedule_service.dart';
import '../core/services/reminder_log_service.dart';

class ScheduleProvider extends ChangeNotifier {
  List<ScheduleModel>    _schedules = [];
  List<ReminderLogModel> _todayLogs = [];
  List<Map<String, dynamic>> _weeklyReport = [];
  bool   _loading = false;
  String? _error;

  List<ScheduleModel>    get schedules    => _schedules;
  List<ReminderLogModel> get todayLogs    => _todayLogs;
  List<Map<String, dynamic>> get weeklyReport => _weeklyReport;
  bool    get loading => _loading;
  String? get error   => _error;

  int get takenToday  => _todayLogs.where((l) => l.isTaken).length;
  int get totalToday  => _todayLogs.length;

  Future<void> loadAll(String token, {int? elderlyId}) async {
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      final sSvc = ScheduleService(token);
      final lSvc = ReminderLogService(token);
      _schedules    = await sSvc.getSchedules(elderlyId: elderlyId);
      _todayLogs    = await lSvc.getLogs(elderlyId: elderlyId);
      _weeklyReport = await lSvc.weeklyReport(elderlyId: elderlyId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> confirmLog(String token, int logId) async {
    try {
      await ReminderLogService(token).confirm(logId);
      final idx = _todayLogs.indexWhere((l) => l.id == logId);
      if (idx != -1) {
        // Rebuild with updated status
        final old = _todayLogs[idx];
        _todayLogs[idx] = ReminderLogModel(
          id: old.id,
          scheduleId: old.scheduleId,
          medicineName: old.medicineName,
          scheduledAt: old.scheduledAt,
          takenAt: DateTime.now(),
          status: 'taken',
          notes: old.notes,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
