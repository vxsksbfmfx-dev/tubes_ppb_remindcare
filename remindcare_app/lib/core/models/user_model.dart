class UserModel {
  final int    id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? avatar;
  final String? googleId;
  final int?   emailVerified;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.avatar,
    this.googleId,
    this.emailVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:            j['id'],
    name:          j['name'],
    email:         j['email'],
    phone:         j['phone'],
    role:          j['role'],
    avatar:        j['avatar'],
    googleId:      j['google_id'],
    emailVerified: j['email_verified'],
  );

  Map<String, dynamic> toJson() => {
    'id':             id,
    'name':           name,
    'email':          email,
    'phone':          phone,
    'role':           role,
    'avatar':         avatar,
    'google_id':      googleId,
    'email_verified': emailVerified,
  };

  bool get isGoogleUser => googleId != null && googleId!.isNotEmpty;
}
