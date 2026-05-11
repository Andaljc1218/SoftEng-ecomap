import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/schedule_model.dart';
import '../../core/theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _wasteFilters = [
    'All',
    'Biodegradable',
    'Non-Biodegradable',
    'Mixed',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _wasteColor(String type) {
    switch (type) {
      case 'Biodegradable':
        return Colors.green;
      case 'Non-Biodegradable':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData _wasteIcon(String type) {
    switch (type) {
      case 'Biodegradable':
        return Icons.eco;
      case 'Non-Biodegradable':
        return Icons.recycling;
      default:
        return Icons.delete_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickup Schedule')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search barangay or address...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: EcoColors.backgroundGreen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),

          // Waste type filter chips
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _wasteFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _wasteFilters[i];
                final selected = _selectedFilter == f;
                return FilterChip(
                  label: Text(f),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedFilter = f),
                  selectedColor: EcoColors.primaryGreen,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: selected ? FontWeight.w600 : null,
                  ),
                  checkmarkColor: Colors.white,
                );
              },
            ),
          ),

          // Schedule list from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schedules')
                  .orderBy('barangay')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text('Error: ${snapshot.error}',
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                var schedules = docs
                    .map((d) => PickupSchedule.fromMap(
                        d.id, d.data() as Map<String, dynamic>))
                    .toList();

                // Apply filters
                if (_selectedFilter != 'All') {
                  schedules = schedules
                      .where((s) => s.wasteType == _selectedFilter)
                      .toList();
                }
                if (_searchQuery.isNotEmpty) {
                  schedules = schedules
                      .where((s) =>
                          s.barangay.toLowerCase().contains(_searchQuery) ||
                          s.address.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                if (schedules.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 56, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No schedules found',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty || _selectedFilter != 'All'
                              ? 'Try a different search or filter'
                              : 'Schedules will appear here once added.',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: schedules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ScheduleCard(
                    schedule: schedules[i],
                    wasteColor: _wasteColor(schedules[i].wasteType),
                    wasteIcon: _wasteIcon(schedules[i].wasteType),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final PickupSchedule schedule;
  final Color wasteColor;
  final IconData wasteIcon;

  const _ScheduleCard({
    required this.schedule,
    required this.wasteColor,
    required this.wasteIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Waste type icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: wasteColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(wasteIcon, color: wasteColor, size: 26),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Brgy. ${schedule.barangay}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: wasteColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          schedule.wasteType,
                          style: TextStyle(
                              color: wasteColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (schedule.address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(schedule.address,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: EcoColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text(schedule.daysLabel,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_outlined,
                        size: 14, color: EcoColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text(schedule.time,
                        style: const TextStyle(fontSize: 13)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.person_outline,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(schedule.driverName,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}