import 'package:flutter/material.dart';
import '../models/reminder_log_model.dart';
import '../models/stats_model.dart';
import '../services/log_service.dart';
import '../services/session_service.dart';

enum HistoryStatus { idle, loading, loaded, error }

class HistoryProvider extends ChangeNotifier {
  final _svc     = LogService();
  final _session = SessionService();

  List<ReminderLogModel> _history    = [];
  List<DailyStatModel>   _weekly     = [];
  MonthlySummaryModel?   _monthly;
  HistoryStatus          _status     = HistoryStatus.idle;
  String                 _message    = '';
  int                    _page       = 1;
  int                    _lastPage   = 1;
  String                 _dateFilter = '';

  List<ReminderLogModel> get history    => _history;
  List<DailyStatModel>   get weekly     => _weekly;
  MonthlySummaryModel?   get monthly    => _monthly;
  HistoryStatus          get status     => _status;
  String                 get message    => _message;
  bool                   get isLoading  => _status == HistoryStatus.loading;
  bool                   get hasMore    => _page < _lastPage;
  String                 get dateFilter => _dateFilter;

  void setDateFilter(String date) {
    _dateFilter = date;
    _page    = 1;
    _history = [];
    loadHistory();
  }

  Future<void> loadHistory({bool loadMore = false}) async {
    if (loadMore && !hasMore) return;
    if (!loadMore) {
      _page    = 1;
      _history = [];
    }
    _status = HistoryStatus.loading;
    notifyListeners();
    try {
      final token = await _session.getToken();
      final result = await _svc.getHistory(token!,
          date: _dateFilter.isEmpty ? null : _dateFilter, page: _page);
      _history  = [..._history, ...(result['items'] as List<ReminderLogModel>)];
      _lastPage = result['last_page'] as int;
      if (loadMore) _page++;
      _status = HistoryStatus.loaded;
    } catch (e) {
      _status  = HistoryStatus.error;
      _message = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadStats() async {
    try {
      final token  = await _session.getToken();
      final result = await _svc.getStats(token!);
      _weekly  = result['weekly'] as List<DailyStatModel>;
      _monthly = result['monthly'] as MonthlySummaryModel;
      notifyListeners();
    } catch (_) {}
  }
}
