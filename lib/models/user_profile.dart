/// Profile data model stored under users/{uid}/profile/main.
class UserProfile {
  final String userId;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const UserProfile({
    required this.userId,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      userId: uid.isNotEmpty ? uid : (map['userId'] as String? ?? ''),
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'User',
      photoUrl: map['photoUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.tryParse(map['lastLoginAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
