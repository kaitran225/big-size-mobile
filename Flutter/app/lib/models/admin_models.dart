/// One account row in the administrator's user list.
class UserAccountSummary {
  const UserAccountSummary({
    required this.id,
    required this.email,
    required this.displayName,
    required this.roles,
  });

  final String id;
  final String email;
  final String displayName;
  final List<String> roles;

  bool get isAdmin =>
      roles.any((role) => role.toLowerCase().contains('admin'));

  bool get isStaff => roles.any((role) => role.toLowerCase().contains('staff'));

  factory UserAccountSummary.fromJson(Map<String, dynamic> json) =>
      UserAccountSummary(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        roles: (json['roles'] as List<dynamic>? ?? const [])
            .cast<String>()
            .toList(growable: false),
      );
}
