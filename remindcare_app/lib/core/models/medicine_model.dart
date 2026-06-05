class MedicineModel {
  final int    id;
  final String name;
  final String? genericName;
  final String? brandName;
  final String? description;

  const MedicineModel({
    required this.id,
    required this.name,
    this.genericName,
    this.brandName,
    this.description,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> j) => MedicineModel(
    id:          j['id'],
    name:        j['name'],
    genericName: j['generic_name'],
    brandName:   j['brand_name'],
    description: j['description'],
  );

  Map<String, dynamic> toJson() => {
    'name':         name,
    'generic_name': genericName,
    'brand_name':   brandName,
    'description':  description,
  };
}
