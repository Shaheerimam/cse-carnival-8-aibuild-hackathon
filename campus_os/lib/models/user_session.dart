class UserSession {
  UserSession({
    required this.uid,
    required this.email,
    required this.name,
    required this.department,
    required this.role,
    this.identifier,
  });

  final String uid;
  final String email;
  final String name;
  final String department;
  final String role;
  final String? identifier;

  factory UserSession.fromFirestore(
    Map<String, dynamic> data, {
    required String uid,
  }) {
    return UserSession(
      uid: uid,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? 'Campus User',
      department: data['department'] as String? ?? 'General',
      role: data['role'] as String? ?? 'Student',
      identifier: data['identifier'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'department': department,
      'role': role,
      'identifier': identifier,
      'displayLabel': displayLabel,
      'subtitle': subtitle,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  String get displayLabel => '$name • $department';

  String get subtitle {
    final id = identifier;
    if (id == null || id.isEmpty) {
      return role;
    }
    return '$role • $id';
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}