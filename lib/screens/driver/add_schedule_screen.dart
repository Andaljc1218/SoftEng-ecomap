import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/schedule_model.dart';
import '../../core/theme/app_theme.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barangayCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  final List<String> _allDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  final List<String> _selectedDays = [];
  String _wasteType = 'Mixed';
  bool _saving = false;

  final List<String> _wasteTypes = ['Biodegradable', 'Non-Biodegradable', 'Mixed'];

  @override
  void dispose() {
    _barangayCtrl.dispose();
    _addressCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final user = context.read<AuthProvider>().currentUser!;
      final schedule = PickupSchedule(
        id: '',
        barangay: _barangayCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        driverName: user.name,
        driverId: user.id,
        days: List<String>.from(_selectedDays),
        time: _timeCtrl.text,
        wasteType: _wasteType,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('schedules')
          .add(schedule.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule added successfully!'),
          backgroundColor: EcoColors.primaryGreen,
        ),
      );

      // Reset form
      _formKey.currentState!.reset();
      _barangayCtrl.clear();
      _addressCtrl.clear();
      _timeCtrl.clear();
      setState(() {
        _selectedDays.clear();
        _wasteType = 'Mixed';
        _saving = false;
      });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Schedule')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location section
              const Text('Location',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barangayCtrl,
                decoration: const InputDecoration(
                  labelText: 'Barangay *',
                  prefixIcon: Icon(Icons.location_city_outlined),
                  hintText: 'e.g. Poblacion, Kumintang Ibaba',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Barangay is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Specific Address',
                  prefixIcon: Icon(Icons.home_outlined),
                  hintText: 'e.g. Near the church',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Schedule section
              const Text('Schedule',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),

              // Day selection
              const Text('Pickup Days *',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _allDays.map((day) {
                  final selected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day.substring(0, 3)), // Mon, Tue, etc.
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

              // Time picker
              TextFormField(
                controller: _timeCtrl,
                readOnly: true,
                onTap: _pickTime,
                decoration: const InputDecoration(
                  labelText: 'Pickup Time *',
                  prefixIcon: Icon(Icons.access_time_outlined),
                  hintText: 'Tap to select time',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Time is required' : null,
              ),
              const SizedBox(height: 24),

              // Waste type section
              const Text('Waste Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ..._wasteTypes.map((type) => RadioListTile<String>(
                    value: type,
                    groupValue: _wasteType,
                    title: Text(type),
                    onChanged: (v) => setState(() => _wasteType = v!),
                    activeColor: EcoColors.primaryGreen,
                    contentPadding: EdgeInsets.zero,
                  )),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save Schedule'),
                  onPressed: _saving ? null : _save,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}