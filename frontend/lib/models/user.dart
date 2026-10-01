class User {
  final String id;
  final String username;
  final String displayName;
  final String email;
  final String profilePhoto;
  final String bio;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isBlocked;

  User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    this.profilePhoto = '',
    this.bio = 'Hey there! I am using Zylo.',
    this.isOnline = false,
    this.lastSeen,
    this.isBlocked = false,
  });

  /// Sensible display name fallback hierarchy:
  /// 1. displayName
  /// 2. username
  /// 3. email prefix (before @)
  /// 4. 'User' (safe generic fallback, never 'Zylo Contact')
  String get resolvedName {
    final cleanDisplay = displayName.trim();
    final cleanUsername = username.trim();
    final cleanEmail = email.trim();

    if (cleanDisplay.isNotEmpty && cleanDisplay.toLowerCase() != 'user') {
      return cleanDisplay;
    }
    if (cleanUsername.isNotEmpty) {
      return cleanUsername;
    }
    if (cleanEmail.isNotEmpty) {
      final at = cleanEmail.indexOf('@');
      if (at > 0) return cleanEmail.substring(0, at).trim();
      return cleanEmail;
    }
    if (cleanDisplay.isNotEmpty) {
      return cleanDisplay;
    }
    return 'User';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final rawDisplayName = (json['displayName'] ?? json['name'] as dynamic)?.toString().trim();
    final rawUsername = (json['username'] as dynamic)?.toString().trim() ?? '';
    final rawEmail = (json['email'] as dynamic)?.toString().trim() ?? '';

    String effectiveDisplayName;
    if (rawDisplayName != null && rawDisplayName.isNotEmpty) {
      effectiveDisplayName = rawDisplayName;
    } else if (rawUsername.isNotEmpty) {
      effectiveDisplayName = rawUsername;
    } else if (rawEmail.isNotEmpty && rawEmail.contains('@')) {
      effectiveDisplayName = rawEmail.split('@').first.trim();
    } else {
      effectiveDisplayName = 'User';
    }

    return User(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      username: rawUsername,
      displayName: effectiveDisplayName,
      email: rawEmail,
      profilePhoto: (json['profilePhoto'] as dynamic)?.toString() ?? '',
      bio: (json['bio'] as dynamic)?.toString() ?? 'Hey there! I am using Zylo.',
      isOnline: json['isOnline'] == true,
      lastSeen: json['lastSeen'] != null ? DateTime.tryParse(json['lastSeen'].toString()) : null,
      isBlocked: json['isBlocked'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'email': email,
      'profilePhoto': profilePhoto,
      'bio': bio,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'isBlocked': isBlocked,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? displayName,
    String? email,
    String? profilePhoto,
    String? bio,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isBlocked,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
