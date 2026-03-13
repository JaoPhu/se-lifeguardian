import 'package:cloud_firestore/cloud_firestore.dart';
enum NotificationType { success, warning, danger }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime date;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final double? confidence;
  final String? eventId;
  final String? cameraId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.date,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.confidence,
    this.eventId,
    this.cameraId,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? date,
    double? latitude,
    double? longitude,
    String? imageUrl,
    double? confidence,
    String? eventId,
    String? cameraId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      date: date ?? this.date,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      confidence: confidence ?? this.confidence,
      eventId: eventId ?? this.eventId,
      cameraId: cameraId ?? this.cameraId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'date': Timestamp.fromDate(date), // Firestore Timestamp for proper ordering
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'confidence': confidence,
      'eventId': eventId,
      'cameraId': cameraId,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final dateValue = json['date'];
    if (dateValue is String) {
      parsedDate = DateTime.parse(dateValue);
    } else if (dateValue is Timestamp) {
      parsedDate = dateValue.toDate();
    } else {
      parsedDate = DateTime.now();
    }

    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.warning,
      ),
      date: parsedDate,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      eventId: json['eventId'] as String?,
      cameraId: json['cameraId'] as String?,
    );
  }
}
