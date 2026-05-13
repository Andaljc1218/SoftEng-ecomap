import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/pickup_point.dart';
import '../../models/schedule_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/eco_app_bar.dart';

class AddScheduleScreen extends StatefulWidget {
  /// When set, loads that schedule document for editing.
  final String? editScheduleId;

  const AddScheduleScreen({super.key, this.editScheduleId});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timeCtrl = TextEditingController();

  final List<String> _allDays = PickupPoint.weekdayOrder;
  final List<String> _selectedDays = [];
  String _wasteType = 'Mixed';
  bool _saving = false;
  bool _loadingEdit = false;

  String? _selectedPointId;
  DateTime? _existingCreatedAt;

  final List<String> _wasteTypes = [
    'Biodegradable',
    'Non-Biodegradable',
    'Mixed',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editScheduleId != null) {
      _loadExistingSchedule();
    }
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSchedule() async {
    setState(() => _loadingEdit = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('schedules')
          .doc(widget.editScheduleId)
          .get();
      if (!doc.exists || !mounted) {
        setState(() => _loadingEdit = false);
        return;
      }
      final data = doc.data() as Map<String, dynamic>;
      final s = PickupSchedule.fromMap(doc.id, data);
      setState(() {
        _selectedPointId = s.pickupPointId;
        _selectedDays
          ..clear()
          ..addAll(s.days);
        _timeCtrl.text = s.time;
        _wasteType = s.wasteType;
        _existingCreatedAt = s.createdAt;
        _loadingEdit = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingEdit = false);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() => _timeCtrl.text = picked.format(context));
    }
  }

  void _applyPointDefaults(PickupPoint p) {
    setState(() {
      _selectedDays
        ..clear()
        ..addAll(p.days.isNotEmpty ? p.days : []);
      if (p.time.isNotEmpty) {
        _timeCtrl.text = p.time;
      }
    });
  }

  Future<void> _save(List<PickupPoint> points) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPointId == null || _selectedPointId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an admin pickup point.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one pickup day.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final match = points.where((p) => p.id == _selectedPointId);
    if (match.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected pickup point is no longer available.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final point = match.first;

    setState(() => _saving = true);

    try {
      final user = context.read<AuthProvider>().currentUser!;
      final schedule = PickupSchedule(
        id: widget.editScheduleId ?? '',
        pickupPointId: point.id,
        pickupPointName: point.name,
        barangay: point.barangay,
        address: point.address,
        driverName: user.name,
        driverId: user.id,
        days: List<String>.from(_selectedDays),
        time: _timeCtrl.text.trim(),
        wasteType: _wasteType,
        createdAt: _existingCreatedAt ?? DateTime.now(),
      );

      final col = FirebaseFirestore.instance.collection('schedules');
      if (widget.editScheduleId != null) {
        await col.doc(widget.editScheduleId).update(schedule.toMap());
      } else {
        await col.add(schedule.toMap());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editScheduleId != null
              ? 'Schedule updated.'
              : 'Schedule added successfully.'),
          backgroundColor: EcoColors.primaryGreen,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editScheduleId != null;

    return Scaffold(
      appBar: EcoAppBar(
        title: isEdit ? 'Edit schedule' : 'Add schedule',
        showHomeLeading: true,
        homeLocation: '/driver/home',
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('pickup_points').snapshots(),
        builder: (context, snapshot) {
          if (_loadingEdit ||
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final points = snapshot.data?.docs
                  .map((d) =>
                      PickupPoint.fromMap(d.id, d.data() as Map<String, dynamic>))
                  .toList() ??
              [];
          points.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          if (points.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No pickup points yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'An administrator must create pickup points on the map '
                      'before you can assign a schedule.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pickup point',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose a location the admin has created. You can change '
                    'days, time, and waste type for your runs.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedPointId != null &&
                            points.any((p) => p.id == _selectedPointId)
                        ? _selectedPointId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Pickup point *',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: points
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              p.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      setState(() => _selectedPointId = id);
                      if (id != null) {
                        final p = points.firstWhere((e) => e.id == id);
                        if (!isEdit) {
                          _applyPointDefaults(p);
                        }
                      }
                    },
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Select a pickup point' : null,
                  ),
                  if (_selectedPointId != null) ...[
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final p = points.firstWhere((e) => e.id == _selectedPointId);
                        return Text(
                          'Brgy. ${p.barangay}${p.address.isNotEmpty ? ' · ${p.address}' : ''}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        );
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _selectedPointId == null
                            ? null
                            : () {
                                final p = points.firstWhere(
                                    (e) => e.id == _selectedPointId);
                                _applyPointDefaults(p);
                              },
                        child: const Text('Reset to point defaults'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Your schedule',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pickup days *',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _allDays.map((day) {
                      final selected = _selectedDays.contains(day);
                      return FilterChip(
                        label: Text(day.substring(0, 3)),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedDays.add(day);
                            } else {
                              _selectedDays.remove(day);
                            }
                          });
                        },
                        selectedColor: EcoColors.primaryGreen,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : null,
                          fontWeight: selected ? FontWeight.w600 : null,
                        ),
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _timeCtrl,
                    readOnly: true,
                    onTap: _pickTime,
                    decoration: const InputDecoration(
                      labelText: 'Pickup time *',
                      prefixIcon: Icon(Icons.access_time_outlined),
                      hintText: 'Tap to select time',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Time is required' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Waste type',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ..._wasteTypes.map(
                    (type) => RadioListTile<String>(
                      value: type,
                      groupValue: _wasteType,
                      title: Text(type),
                      onChanged: (v) => setState(() => _wasteType = v!),
                      activeColor: EcoColors.primaryGreen,
                      contentPadding: EdgeInsets.zero,
                    ),
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
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(isEdit ? Icons.save_outlined : Icons.add),
                      label: Text(_saving
                          ? 'Saving...'
                          : isEdit
                              ? 'Save changes'
                              : 'Save schedule'),
                      onPressed: _saving ? null : () => _save(points),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
