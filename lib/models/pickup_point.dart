class PickupPoint {
  final String id;
  final String name;
  final String barangay;
  final String address;
  final double lat;
  final double lng;
  final String schedule; // e.g. "Mon, Wed, Fri"
  final String time;     // e.g. "6:00 AM"

  const PickupPoint({
    required this.id,
    required this.name,
    required this.barangay,
    required this.address,
    required this.lat,
    required this.lng,
    required this.schedule,
    required this.time,
  });

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
    };
  }
}