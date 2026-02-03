class SimulationEvent {
  final String id;
  final String type; // 'sitting', 'standing', 'walking', 'laying', 'falling'
  final String timestamp; // HH:mm
  final String? date; // YYYY-MM-DD
  final String? duration; // X.XX hr
  final String? description;
  final String? snapshotUrl;
  final bool isCritical;

  SimulationEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.date,
    this.duration,
    this.description,
    this.snapshotUrl,
    this.isCritical = false,
  });

  String get thaiLabel {
    switch (type) {
      case 'sitting':
        return 'นั่งทำงาน';
      case 'slouching':
        return 'นั่งสลัว/หลังค่อม';
      case 'laying':
        return 'นอนพักผ่อน';
      case 'walking':
        return 'เดิน';
      case 'standing':
        return 'ยืน';
      case 'exercise':
        return 'กายบริหาร';
      case 'falling':
        return 'ตรวจพบการล้ม!';
      case 'near_fall':
        return 'ตรวจพบความเสี่ยงล้ม';
      default:
        return 'กิจกรรม: $type';
    }
  }

  SimulationEvent copyWith({
    String? id,
    String? type,
    String? timestamp,
    String? date,
    String? duration,
    String? description,
    String? snapshotUrl,
    bool? isCritical,
  }) {
    return SimulationEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      snapshotUrl: snapshotUrl ?? this.snapshotUrl,
      isCritical: isCritical ?? this.isCritical,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp,
      'date': date,
      'duration': duration,
      'description': description,
      'snapshotUrl': snapshotUrl,
      'isCritical': isCritical,
    };
  }

  factory SimulationEvent.fromJson(Map<String, dynamic> json) {
    return SimulationEvent(
      id: json['id'] as String,
      type: json['type'] as String,
      timestamp: json['timestamp'] as String,
      date: json['date'] as String?,
      duration: json['duration'] as String?,
      description: json['description'] as String?,
      snapshotUrl: json['snapshotUrl'] as String?,
      isCritical: json['isCritical'] as bool? ?? false,
    );
  }
}
