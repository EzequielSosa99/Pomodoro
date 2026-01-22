// Task/Note model for the calendar
class Task {
  final String id;
  final String description;
  final bool isCompleted;
  final DateTime date;

  const Task({
    required this.id,
    required this.description,
    required this.date,
    this.isCompleted = false,
  });

  Task copyWith({
    String? id,
    String? description,
    bool? isCompleted,
    DateTime? date,
  }) =>
      Task(
        id: id ?? this.id,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
        date: date ?? this.date,
      );

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'isCompleted': isCompleted,
        'date': date.toIso8601String(),
      };

  // Create from JSON
  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        description: json['description'],
        isCompleted: json['isCompleted'] ?? false,
        date: DateTime.parse(json['date']),
      );
}
