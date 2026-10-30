/// Local authenticated user representation replacing Firebase User.
class LocalUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;

  const LocalUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
    };
  }

  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      uid: map['uid'] as String? ?? map['userId'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'User',
      photoURL: map['photoURL'] as String? ?? map['photoUrl'] as String?,
    );
  }

  LocalUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
  }) {
    return LocalUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
    );
  }
}
