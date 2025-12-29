/// Model class for Reminder
class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime reminderTime;
  final String category;
  final bool isCompleted;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.reminderTime,
    required this.category,
    required this.isCompleted,
    required this.createdAt,
  });

  /// Convert Reminder to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reminderTime': reminderTime.toIso8601String(),
      'category': category,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create Reminder from JSON map
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      reminderTime: DateTime.parse(json['reminderTime'] as String),
      category: json['category'] as String,
      isCompleted: (json['isCompleted'] as int) == 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Create a copy of Reminder with modified fields
  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? reminderTime,
    String? category,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Reminder(id: $id, title: $title, reminderTime: $reminderTime, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reminder &&
        other.id == id &&
        other.title == title &&
        other.reminderTime == reminderTime;
  }

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ reminderTime.hashCode;
}
