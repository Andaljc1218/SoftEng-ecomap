import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
              final point = points[i];
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
                  title: Text(point.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Brgy. ${point.barangay}\n${point.schedule} • ${point.time}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: EcoColors.primaryGreen),
                        onPressed: () => _openForm(context, point),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () =>
                            _deletePoint(context, point.id, point.name),
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
        content: Text('Remove "$name"? This will also remove it from the map.'),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PickupPointForm(existing: existing),
    );
  }
}

class _PickupPointForm extends StatefulWidget {
  final PickupPoint? existing;
  const _PickupPointForm({this.existing});

  @override
  State<_PickupPointForm> createState() => _PickupPointFormState();
}

class _PickupPointFormState extends State<_PickupPointForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _barangayCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _scheduleCtrl;
  late final TextEditingController _timeCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _barangayCtrl = TextEditingController(text: e?.barangay ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _latCtrl = TextEditingController(text: e?.lat.toString() ?? '');
    _lngCtrl = TextEditingController(text: e?.lng.toString() ?? '');
    _scheduleCtrl = TextEditingController(text: e?.schedule ?? '');
    _timeCtrl = TextEditingController(text: e?.time ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barangayCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _scheduleCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'barangay': _barangayCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'lat': double.tryParse(_latCtrl.text.trim()) ?? 0.0,
      'lng': double.tryParse(_lngCtrl.text.trim()) ?? 0.0,
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
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Edit Pickup Point' : 'Add Pickup Point',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Name *',
                    prefixIcon: Icon(Icons.label_outline)),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barangayCtrl,
                decoration: const InputDecoration(
                    labelText: 'Barangay *',
                    prefixIcon: Icon(Icons.location_city_outlined)),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.home_outlined)),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                        labelText: 'Latitude *',
                        hintText: '13.7565'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lngCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                        labelText: 'Longitude *',
                        hintText: '121.0583'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              const Text(
                'Tip: Use Google Maps → long press a location → copy coordinates',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _scheduleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Schedule *',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    hintText: 'Mon, Wed, Fri'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Time *',
                    prefixIcon: Icon(Icons.access_time_outlined),
                    hintText: '6:00 AM'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Icon(isEdit ? Icons.save_outlined : Icons.add),
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
    );
  }
}