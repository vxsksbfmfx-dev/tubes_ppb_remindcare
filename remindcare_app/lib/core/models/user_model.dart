class UserModel {
  final int    id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatar;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:     j['id'],
    name:   j['name'],
    email:  j['email'],
    role:   j['role'] ?? 'family',
    phone:  j['phone'],
    avatar: j['avatar'],
  );
}
