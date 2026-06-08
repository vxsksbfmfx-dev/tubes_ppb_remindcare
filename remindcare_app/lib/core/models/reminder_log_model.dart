class ReminderLogModel {
  final int    id;
  final int    scheduleId;
  final String medicineName;
  final DateTime scheduledAt;
  final DateTime? takenAt;
  final String status;
  final String? notes;

  ReminderLogModel({
    required this.id,
    required this.scheduleId,
    required this.medicineName,
    required this.scheduledAt,
    this.takenAt,
    required this.status,
    this.notes,
  });

  bool get isPending => status == 'pending';
  bool get isTaken   => status == 'taken';
  bool get isMissed  => status == 'missed';

  factory ReminderLogModel.fromJson(Map<String, dynamic> j) => ReminderLogModel(
    id:           j['id'],
    scheduleId:   j['schedule_id'],
    medicineName: j['medicine_name'] ?? '',
    scheduledAt:  DateTime.parse(j['scheduled_at']),
    takenAt:      j['taken_at'] != null ? DateTime.parse(j['taken_at']) : null,
    status:       j['status'],
    notes:        j['notes'],
  );
}
