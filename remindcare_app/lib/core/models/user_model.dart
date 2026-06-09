class UserModel {
  final int    id;
  final String name;
  final String email;
  final String? phone;
  final String  role;
  final String? avatar;
  final int?    age;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatar,
    this.age,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:     j['id']     as int,
    name:   j['name']   as String,
    email:  j['email']  as String,
    phone:  j['phone']  as String?,
    role:   j['role']   as String? ?? 'family',
    avatar: j['avatar'] as String?,
    age:    j['age']    as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email,
    'phone': phone, 'role': role, 'avatar': avatar, 'age': age,
  };

  UserModel copyWith({
    String? name, String? phone, String? avatar, int? age,
  }) => UserModel(
    id: id, email: email, role: role,
    name:   name   ?? this.name,
    phone:  phone  ?? this.phone,
    avatar: avatar ?? this.avatar,
    age:    age    ?? this.age,
  );
}
