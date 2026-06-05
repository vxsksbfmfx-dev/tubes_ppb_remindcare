class UserModel {
  final int    id;
  final String name;
  final String email;
  final String? phone;
  final String role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:    j['id']   as int,
    name:  j['name'] as String,
    email: j['email'] as String,
    phone: j['phone'] as String?,
    role:  j['role']  as String? ?? 'family',
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'phone': phone, 'role': role,
  };
}
