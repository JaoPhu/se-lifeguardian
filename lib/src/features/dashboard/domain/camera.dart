import 'package:flutter/foundation.dart';
import '../../statistics/domain/simulation_event.dart';

enum CameraSource { camera, demo }
enum CameraStatus { online, offline }

@immutable
class CameraConfig {
  final String? date;
  final String? originalDate;
  final String? startTime;
  final String? thumbnailUrl;
  final String? eventType;
  final String? durationText;

  const CameraConfig({
    this.date,
    this.originalDate,
    this.startTime,
    this.thumbnailUrl,
    this.eventType,
    this.durationText,
  });

  CameraConfig copyWith({
    String? date,
    String? originalDate,
    String? startTime,
    String? thumbnailUrl,
    String? eventType,
    String? durationText,
  }) {
    return CameraConfig(
      date: date ?? this.date,
      originalDate: originalDate ?? this.originalDate,
      startTime: startTime ?? this.startTime,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      eventType: eventType ?? this.eventType,
      durationText: durationText ?? this.durationText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'originalDate': originalDate,
      'startTime': startTime,
      'thumbnailUrl': thumbnailUrl,
      'eventType': eventType,
      'durationText': durationText,
    };
  }

  factory CameraConfig.fromJson(Map<String, dynamic> json) {
    return CameraConfig(
      date: json['date'] as String?,
      originalDate: json['originalDate'] as String?,
      startTime: json['startTime'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      eventType: json['eventType'] as String?,
      durationText: json['durationText'] as String?,
    );
  }
}

@immutable
class Camera {
  final String id;
  final String name;
  final CameraStatus status;
  final CameraSource source;
  final List<SimulationEvent> events;
  final CameraConfig? config;

  const Camera({
    required this.id,
    required this.name,
    required this.status,
    required this.source,
    required this.events,
    this.config,
  });

  Camera copyWith({
    String? id,
    String? name,
    CameraStatus? status,
    CameraSource? source,
    List<SimulationEvent>? events,
    CameraConfig? config,
  }) {
    return Camera(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      source: source ?? this.source,
      events: events ?? this.events,
      config: config ?? this.config,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status.name,
      'source': source.name,
      'config': config?.toJson(),
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  factory Camera.fromJson(Map<String, dynamic> json) {
    return Camera(
      id: json['id'] as String,
      name: json['name'] as String,
      status: CameraStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => CameraStatus.offline),
      source: CameraSource.values.firstWhere((e) => e.name == json['source'], orElse: () => CameraSource.demo),
      events: (json['events'] as List<dynamic>?)
          ?.map((e) => SimulationEvent.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      config: json['config'] != null ? CameraConfig.fromJson(json['config'] as Map<String, dynamic>) : null,
    );
  }
}
