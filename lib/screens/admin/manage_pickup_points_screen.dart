import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/pickup_point.dart';
import '../../core/theme/app_theme.dart';

class ManagePickupPointsScreen extends StatelessWidget {
  const ManagePickupPointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Pickup Points')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add Point'),
        backgroundColor: EcoColors.primaryGreen,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(context, null),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pickup_points')
            .orderBy('barangay')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 56, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No pickup points yet.',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Tap + Add Point to create one.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Add First Point'),
                    onPressed: () => _openForm(context, null),
                  ),
                ],
              ),
            );
          }

          final points = docs
              .map((d) =>
                  PickupPoint.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: points.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final p = points[i];
              return Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EcoColors.backgroundGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on,
                        color: EcoColors.primaryGreen),
                  ),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Brgy. ${p.barangay}\n${p.schedule} • ${p.time}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: EcoColors.primaryGreen),
                        onPressed: () => _openForm(context, p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () =>
                            _deletePoint(context, p.id, p.name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deletePoint(
      BuildContext context, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pickup Point'),
        content: Text(
            'Remove "$name"? It will disappear from the map immediately.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('pickup_points')
          .doc(id)
          .delete();
    }
  }

  void _openForm(BuildContext context, PickupPoint? existing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PickupPointFormScreen(existing: existing),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Full-screen form with embedded map picker
// ─────────────────────────────────────────────
class _PickupPointFormScreen extends StatefulWidget {
  final PickupPoint? existing;
  const _PickupPointFormScreen({this.existing});

  @override
  State<_PickupPointFormScreen> createState() =>
      _PickupPointFormScreenState();
}

class _PickupPointFormScreenState extends State<_PickupPointFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _barangayCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _scheduleCtrl;
  late final TextEditingController _timeCtrl;

  static const LatLng _defaultCenter = LatLng(13.7565, 121.0583);

  LatLng? _markerPosition;
  bool _saving = false;
  bool _showInstruction = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _barangayCtrl = TextEditingController(text: e?.barangay ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _scheduleCtrl = TextEditingController(text: e?.schedule ?? '');
    _timeCtrl = TextEditingController(text: e?.time ?? '');

    if (e != null) {
      _markerPosition = LatLng(e.lat, e.lng);
      _showInstruction = false;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barangayCtrl.dispose();
    _addressCtrl.dispose();
    _scheduleCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_markerPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap the map to set the pickup location.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'barangay': _barangayCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'lat': _markerPosition!.latitude,
      'lng': _markerPosition!.longitude,
      'schedule': _scheduleCtrl.text.trim(),
      'time': _timeCtrl.text.trim(),
    };

    final col = FirebaseFirestore.instance.collection('pickup_points');
    if (widget.existing != null) {
      await col.doc(widget.existing!.id).update(data);
    } else {
      await col.add(data);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Pickup Point' : 'Add Pickup Point'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section header ──
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Pin Location on Map',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),

            // Instruction
            if (_showInstruction)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: EcoColors.backgroundGreen,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: EcoColors.accentGreen),
                  ),
                  child: const Row(children: [
                    Icon(Icons.touch_app_outlined,
                        color: EcoColors.primaryGreen, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap anywhere on the map to drop a marker. Tap again to move it.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ]),
                ),
              ),

            // Map
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 300,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _markerPosition ?? _defaultCenter,
                      initialZoom: 14.0,
                      onTap: (_, latLng) {
                        setState(() {
                          _markerPosition = latLng;
                          _showInstruction = false;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.ecomap',
                      ),
                      if (_markerPosition != null)
                        MarkerLayer(markers: [
                          Marker(
                            point: _markerPosition!,
                            width: 44,
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: EcoColors.primaryGreen,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.location_on,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ]),
                    ],
                  ),
                ),
              ),
            ),

            // Coordinates + clear
            if (_markerPosition != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(children: [
                  const Icon(Icons.my_location,
                      size: 14, color: EcoColors.primaryGreen),
                  const SizedBox(width: 6),
                  Text(
                    '${_markerPosition!.latitude.toStringAsFixed(5)}, '
                    '${_markerPosition!.longitude.toStringAsFixed(5)}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Clear',
                        style: TextStyle(fontSize: 12)),
                    onPressed: () => setState(() {
                      _markerPosition = null;
                      _showInstruction = true;
                    }),
                  ),
                ]),
              )
            else
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text('No location selected',
                    style: TextStyle(fontSize: 12, color: Colors.red)),
              ),

            const Divider(height: 28),

            // ── Details form ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Details',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Point Name *',
                        prefixIcon: Icon(Icons.label_outline),
                        hintText: 'e.g. Brgy. Hall Dumpsite',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _barangayCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Barangay *',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Address / Landmark',
                        prefixIcon: Icon(Icons.home_outlined),
                        hintText: 'e.g. Near the basketball court',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _scheduleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Schedule *',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        hintText: 'e.g. Mon, Wed, Fri',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _timeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pickup Time *',
                        prefixIcon: Icon(Icons.access_time_outlined),
                        hintText: 'e.g. 6:00 AM',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Icon(isEdit
                                ? Icons.save_outlined
                                : Icons.add_location_alt_outlined),
                        label: Text(_saving
                            ? 'Saving...'
                            : isEdit
                                ? 'Save Changes'
                                : 'Add Pickup Point'),
                        onPressed: _saving ? null : _save,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}