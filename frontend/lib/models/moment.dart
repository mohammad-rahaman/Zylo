import 'user.dart';

class Moment {
  final String id;
  final int currentCount;
  final String status;
  final DateTime startedAt;
  final DateTime currentWindowStartedAt;
  final DateTime? lastCompletedAt;
  final DateTime expiresAt;
  final int hoursRemaining;
  final bool isExpiringSoon;
  final bool hasInteractedInCurrentWindow;
  final User? friend;

  const Moment({
    required this.id,
    required this.currentCount,
    required this.status,
    required this.startedAt,
    required this.currentWindowStartedAt,
    this.lastCompletedAt,
    required this.expiresAt,
    required this.hoursRemaining,
    required this.isExpiringSoon,
    required this.hasInteractedInCurrentWindow,
    this.friend,
  });

  factory Moment.fromJson(Map<String, dynamic> json) {
    return Moment(
      id: json['id'] ?? json['_id'] ?? '',
      currentCount: json['currentCount'] ?? 0,
      status: json['status'] ?? 'active',
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      currentWindowStartedAt: json['currentWindowStartedAt'] != null
          ? DateTime.parse(json['currentWindowStartedAt'])
          : DateTime.now(),
      lastCompletedAt: json['lastCompletedAt'] != null
          ? DateTime.parse(json['lastCompletedAt'])
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(hours: 24)),
      hoursRemaining: json['hoursRemaining'] ?? 24,
      isExpiringSoon: json['isExpiringSoon'] ?? false,
      hasInteractedInCurrentWindow: json['hasInteractedInCurrentWindow'] ?? false,
      friend: json['friend'] != null ? User.fromJson(json['friend']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currentCount': currentCount,
      'status': status,
      'startedAt': startedAt.toIso8601String(),
      'currentWindowStartedAt': currentWindowStartedAt.toIso8601String(),
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'hoursRemaining': hoursRemaining,
      'isExpiringSoon': isExpiringSoon,
      'hasInteractedInCurrentWindow': hasInteractedInCurrentWindow,
      if (friend != null) 'friend': friend!.toJson(),
    };
  }

  String get daysTogetherText =>
      '$currentCount ${currentCount == 1 ? 'day' : 'days'} together';

  bool get isActive => status == 'active' || status == 'expiring_soon';
}
