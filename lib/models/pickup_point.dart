import 'package:cloud_firestore/cloud_firestore.dart';

class PickupPoint {
  final String id;
  final String name;
  final String barangay;
  final String address;
  final double lat;
  final double lng;
  /// Short label (e.g. "Mon, Wed") — kept for older data and map display fallback.
  final String schedule;
  final String time;
  /// Structured pickup days (same naming as driver schedules).
  final List<String> days;
  /// Set when the point is created (used for community notifications).
  final DateTime? createdAt;

  PickupPoint({
    required this.id,
    required this.name,
    required this.barangay,
    required this.address,
    required this.lat,
    required this.lng,
    required this.schedule,
    required this.time,
    this.days = const [],
    this.createdAt,
  });

  /// Human-readable schedule for lists and map (prefers structured [days]).
  String get displaySchedule =>
      days.isNotEmpty ? days.join(', ') : schedule;

  static const List<String> weekdayOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Builds the short `schedule` string stored in Firestore (e.g. Mon, Wed, Fri).
  static String abbrevScheduleFromDays(List<String> selected) {
    final sorted = selected.where(weekdayOrder.contains).toList()
      ..sort((a, b) =>
          weekdayOrder.indexOf(a).compareTo(weekdayOrder.indexOf(b)));
    return sorted.map((d) => d.substring(0, 3)).join(', ');
  }

  factory PickupPoint.fromMap(String id, Map<String, dynamic> map) {
    return PickupPoint(
      id: id,
      name: map['name'] ?? '',
      barangay: map['barangay'] ?? '',
      address: map['address'] ?? '',
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
      schedule: map['schedule'] ?? '',
      time: map['time'] ?? '',
      days: List<String>.from(map['days'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'barangay': barangay,
      'address': address,
      'lat': lat,
      'lng': lng,
      'schedule': schedule,
      'time': time,
      'days': days,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
