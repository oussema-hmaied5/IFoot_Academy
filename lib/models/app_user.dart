class AppUser {
  final String id;
  final String email;
  final String name;
  final String mobile;
  final String role;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.mobile,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? 'Unknown',
      name: json['name'] as String? ?? 'Unknown',
      mobile: json['mobile'] as String? ?? 'Unknown',
      role: json['role'] as String? ?? 'user',  // Default to 'USER' if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'mobile': mobile,
      'role': role,
    };
  }
}
