class ActivityLog {
  final int? id;
  final int userId;
  final String action;
  final String? description;
  final DateTime timestamp;

  ActivityLog({
    this.id,
    required this.userId,
    required this.action,
    this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id']?.toInt(),
      userId: map['user_id']?.toInt() ?? 0,
      action: map['action'] ?? '',
      description: map['description'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  ActivityLog copyWith({
    int? id,
    int? userId,
    String? action,
    String? description,
    DateTime? timestamp,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
