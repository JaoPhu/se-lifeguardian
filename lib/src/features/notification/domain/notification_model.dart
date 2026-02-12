enum NotificationType { success, warning, danger }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime date;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'date': date.toIso8601String(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.warning,
      ),
      date: DateTime.parse(json['date'] as String),
    );
  }
}
