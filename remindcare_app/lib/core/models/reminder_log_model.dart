class ReminderLogModel {
  final int    id;
  final int    elderlyId;
  final int    scheduleId;
  final String status;          // pending | confirmed | missed
  final String scheduledAt;
  final String? confirmedAt;
  final String? medicineName;
  final String? brandName;
  final String? dosage;
  final String? notes;

  const ReminderLogModel({
    required this.id,
    required this.elderlyId,
    required this.scheduleId,
    required this.status,
    required this.scheduledAt,
    this.confirmedAt,
    this.medicineName,
    this.brandName,
    this.dosage,
    this.notes,
  });

  factory ReminderLogModel.fromJson(Map<String, dynamic> j) => ReminderLogModel(
    id:           j['id']            as int,
    elderlyId:    j['elderly_id']    as int,
    scheduleId:   j['schedule_id']   as int,
    status:       j['status']        as String,
    scheduledAt:  j['scheduled_at']  as String,
    confirmedAt:  j['confirmed_at']  as String?,
    medicineName: j['medicine_name'] as String?,
    brandName:    j['brand_name']    as String?,
    dosage:       j['dosage']        as String?,
    notes:        j['notes']         as String?,
  );

  bool get isDone    => status == 'confirmed';
  bool get isMissed  => status == 'missed';
  bool get isPending => status == 'pending';
}