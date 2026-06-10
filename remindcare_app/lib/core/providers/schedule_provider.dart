import 'package:flutter/foundation.dart';
import '../models/schedule_model.dart';
import '../models/reminder_log_model.dart';
import '../services/schedule_service.dart';
import '../services/reminder_log_service.dart';

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

  int get takenToday  => _todayLogs.where((l) => l.isDone).length;
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
        final old = _todayLogs[idx];
        _todayLogs[idx] = ReminderLogModel(
          id:           old.id,
          elderlyId:    old.elderlyId,
          scheduleId:   old.scheduleId,
          status:       'confirmed',
          scheduledAt:  old.scheduledAt,
          confirmedAt:  DateTime.now().toIso8601String(),
          medicineName: old.medicineName,
          brandName:    old.brandName,
          dosage:       old.dosage,
          notes:        old.notes,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}