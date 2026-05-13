class Reminder {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final bool isCompleted;
  final bool isEnabled;
  final String repeatType;
  final int colorIndex;

  Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.isCompleted = false,
    this.isEnabled = true,
    this.repeatType = 'none',
    this.colorIndex = 0,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isCompleted,
    bool? isEnabled,
    String? repeatType,
    int? colorIndex,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatType: repeatType ?? this.repeatType,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'isEnabled': isEnabled ? 1 : 0,
      'repeatType': repeatType,
      'colorIndex': colorIndex,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dateTime: DateTime.parse(map['dateTime'] as String),
      isCompleted: map['isCompleted'] == 1,
      isEnabled: map['isEnabled'] == 1,
      repeatType: map['repeatType'] as String? ?? 'none',
      colorIndex: map['colorIndex'] as int? ?? 0,
    );
  }
}
