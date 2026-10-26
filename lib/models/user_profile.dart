class UserProfile {
  final String id;
  final String deviceId;
  final String nickname;
  final String avatarUrl;
  final DateTime createdAt;
  final DateTime lastLogin;

  const UserProfile({
    required this.id,
    required this.deviceId,
    required this.nickname,
    this.avatarUrl = 'default_avatar.png',
    required this.createdAt,
    required this.lastLogin,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatar_url'] as String? ?? 'default_avatar.png',
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLogin: DateTime.parse(json['last_login'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin.toIso8601String(),
    };
  }
}
