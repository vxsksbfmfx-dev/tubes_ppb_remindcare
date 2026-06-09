import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';
import '../services/log_service.dart';
import '../services/session_service.dart';

enum DashboardStatus { idle, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  final _svc     = DashboardService();
  final _logSvc  = LogService();
  final _session = SessionService();

  DashboardData?  _data;
  DashboardStatus _status  = DashboardStatus.idle;
  String          _message = '';

  DashboardData?  get data      => _data;
  DashboardStatus get status    => _status;
  String          get message   => _message;
  bool            get isLoading => _status == DashboardStatus.loading;

  Future<void> load({int? elderlyId}) async {
    _status = DashboardStatus.loading;
    notifyListeners();
    try {
      final token = await _session.getToken();
      _data   = await _svc.getDashboard(token!, elderlyId: elderlyId);
      _status = DashboardStatus.loaded;
    } catch (e) {
      _status  = DashboardStatus.error;
      _message = e.toString();
    }
    notifyListeners();
  }

  Future<void> confirmLog(int logId) async {
    try {
      final token = await _session.getToken();
      await _logSvc.confirm(token!, logId);
      await load(); // reload dashboard
    } catch (e) {
      _message = e.toString();
      notifyListeners();
    }
  }
}
