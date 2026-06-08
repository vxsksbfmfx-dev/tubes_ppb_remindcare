class ScheduleModel {
  final int    id;
  final int    elderlyUserId;
  final int    medicineId;
  final double dose;
  final String doseUnit;
  final List<String> times;
  final List<String>? days;
  final String startDate;
  final String? endDate;
  final String? notes;
  final bool   isActive;

  ScheduleModel({
    required this.id,
    required this.elderlyUserId,
    required this.medicineId,
    required this.dose,
    required this.doseUnit,
    required this.times,
    this.days,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.isActive,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> j) => ScheduleModel(
    id:            j['id'],
    elderlyUserId: j['elderly_user_id'],
    medicineId:    j['medicine_id'],
    dose:          double.tryParse(j['dose'].toString()) ?? 1,
    doseUnit:      j['dose_unit'] ?? 'tablet',
    times:         List<String>.from(j['times'] ?? []),
    days:          j['days'] != null ? List<String>.from(j['days']) : null,
    startDate:     j['start_date'],
    endDate:       j['end_date'],
    notes:         j['notes'],
    isActive:      j['is_active'] == 1 || j['is_active'] == true,
  );
}
