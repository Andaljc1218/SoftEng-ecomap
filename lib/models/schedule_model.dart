import 'package:cloud_firestore/cloud_firestore.dart';

class PickupSchedule {
  final String id;
  final String? pickupPointId;
  final String pickupPointName;
  final String barangay;
  final String address;
  final String driverName;
  final String driverId;
  final List<String> days; // ['Monday', 'Wednesday', 'Friday']
  final String time; // '6:00 AM'
  final String wasteType; // 'Biodegradable', 'Non-Biodegradable', 'Mixed'
  final DateTime createdAt;

  const PickupSchedule({
    required this.id,
    this.pickupPointId,
    this.pickupPointName = '',
    required this.barangay,
    required this.address,
    required this.driverName,
    required this.driverId,
    required this.days,
    required this.time,
    required this.wasteType,
    required this.createdAt,
  });

  String get daysLabel => days.join(', ');

  factory PickupSchedule.fromMap(String id, Map<String, dynamic> map) {
    return PickupSchedule(
      id: id,
      pickupPointId: map['pickupPointId'] as String?,
      pickupPointName: map['pickupPointName'] ?? '',
      barangay: map['barangay'] ?? '',
      address: map['address'] ?? '',
      driverName: map['driverName'] ?? '',
      driverId: map['driverId'] ?? '',
      days: List<String>.from(map['days'] ?? []),
      time: map['time'] ?? '',
      wasteType: map['wasteType'] ?? 'Mixed',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (pickupPointId != null) 'pickupPointId': pickupPointId,
      'pickupPointName': pickupPointName,
      'barangay': barangay,
      'address': address,
      'driverName': driverName,
      'driverId': driverId,
      'days': days,
      'time': time,
      'wasteType': wasteType,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
