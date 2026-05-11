import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pickup_point.dart';
import '../../core/theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // Center on Batangas City
  static const LatLng _batangasCenter = LatLng(13.7565, 121.0583);

  List<PickupPoint> _points = [];
  bool _loading = true;
  PickupPoint? _selected;

  @override
  void initState() {
    super.initState();
    _loadPickupPoints();
  }

  Future<void> _loadPickupPoints() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('pickup_points')
          .get();
      setState(() {
        _points = snap.docs
            .map((d) => PickupPoint.fromMap(d.id, d.data()))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _onMarkerTap(PickupPoint point) {
    setState(() => _selected = point);
    _mapController.move(LatLng(point.lat, point.lng), 15.5);
    _showBottomSheet(point);
  }

  void _showBottomSheet(PickupPoint point) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EcoColors.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(point.name,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 16),
            _InfoRow(Icons.map_outlined, 'Barangay', point.barangay),
            const SizedBox(height: 8),
            _InfoRow(Icons.home_outlined, 'Address', point.address),
            const SizedBox(height: 8),
            _InfoRow(Icons.calendar_today_outlined, 'Schedule', point.schedule),
            const SizedBox(height: 8),
            _InfoRow(Icons.access_time_outlined, 'Time', point.time),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ).whenComplete(() => setState(() => _selected = null));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Center on Batangas',
            onPressed: () =>
                _mapController.move(_batangasCenter, 13.0),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _batangasCenter,
              initialZoom: 13.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ecomap',
              ),
              MarkerLayer(
                markers: _points.map((point) {
                  final isSelected = _selected?.id == point.id;
                  return Marker(
                    point: LatLng(point.lat, point.lng),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => _onMarkerTap(point),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? EcoColors.darkGreen
                              : EcoColors.primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Loading overlay
          if (_loading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Loading pickup points...'),
                    ],
                  ),
                ),
              ),
            ),

          // Legend
          Positioned(
            bottom: 16,
            left: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: EcoColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${_points.length} Pickup Points',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

          // Empty state
          if (!_loading && _points.isEmpty)
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_off,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No pickup points yet',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Admin will add them soon.',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        onPressed: () {
                          setState(() => _loading = true);
                          _loadPickupPoints();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: EcoColors.primaryGreen),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ]),
        ],
      );
}