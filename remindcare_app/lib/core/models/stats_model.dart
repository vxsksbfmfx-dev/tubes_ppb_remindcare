class DailyStatModel {
  final String tanggal;
  final int    total;
  final int    diminum;
  final int    terlewat;

  const DailyStatModel({
    required this.tanggal,
    required this.total,
    required this.diminum,
    required this.terlewat,
  });

  factory DailyStatModel.fromJson(Map<String, dynamic> j) => DailyStatModel(
    tanggal:  j['tanggal']  as String,
    total:    int.tryParse(j['total'].toString())    ?? 0,
    diminum:  int.tryParse(j['diminum'].toString())  ?? 0,
    terlewat: int.tryParse(j['terlewat'].toString()) ?? 0,
  );

  double get persen => total == 0 ? 0 : (diminum / total * 100);
}

class MonthlySummaryModel {
  final int    total;
  final int    diminum;
  final int    terlewat;
  final int    menunggu;
  final double persentaseKepatuhan;

  const MonthlySummaryModel({
    required this.total,
    required this.diminum,
    required this.terlewat,
    required this.menunggu,
    required this.persentaseKepatuhan,
  });

  factory MonthlySummaryModel.fromJson(Map<String, dynamic> j) => MonthlySummaryModel(
    total:                int.tryParse(j['total'].toString())    ?? 0,
    diminum:              int.tryParse(j['diminum'].toString())  ?? 0,
    terlewat:             int.tryParse(j['terlewat'].toString()) ?? 0,
    menunggu:             int.tryParse(j['menunggu'].toString()) ?? 0,
    persentaseKepatuhan:  double.tryParse(j['persentase_kepatuhan']?.toString() ?? '0') ?? 0,
  );
}
