import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/schedule_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/eco_app_bar.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  String _scheduleTitle(PickupSchedule s) {
    if (s.pickupPointName.isNotEmpty) return s.pickupPointName;
    return 'Brgy. ${s.barangay}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final driverId = user?.id;

    return Scaffold(
      appBar: const EcoAppBar(
        title: 'Driver Dashboard',
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [EcoColors.primaryGreen, EcoColors.lightGreen]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, ${user?.name ?? 'Driver'}!',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Manage your pickup schedules.',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add New Schedule'),
                onPressed: () => context.push('/driver/add-schedule'),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Your Schedules',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Live schedule list (no orderBy — avoids composite index issues)
            Expanded(
              child: driverId == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('schedules')
                    .where('driverId', isEqualTo: driverId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(
                              'Could not load schedules.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No schedules yet.',
                              style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 4),
                          Text('Tap "Add New Schedule" to get started.',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    );
                  }

                  final schedules = docs
                      .map((d) => PickupSchedule.fromMap(
                          d.id, d.data() as Map<String, dynamic>))
                      .toList()
                    ..sort((a, b) {
                      final byBarangay = a.barangay
                          .toLowerCase()
                          .compareTo(b.barangay.toLowerCase());
                      if (byBarangay != 0) return byBarangay;
                      return a.pickupPointName
                          .toLowerCase()
                          .compareTo(b.pickupPointName.toLowerCase());
                    });

                  return ListView.separated(
                    itemCount: schedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final s = schedules[i];
                      return Card(
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: EcoColors.backgroundGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.event_note,
                                color: EcoColors.primaryGreen),
                          ),
                          title: Text(_scheduleTitle(s),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${s.daysLabel} • ${s.time} • ${s.wasteType}',
                              style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: EcoColors.primaryGreen),
                                tooltip: 'Edit',
                                onPressed: () => context.push(
                                    '/driver/add-schedule?id=${s.id}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () => _confirmDelete(context, s),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, PickupSchedule schedule) async {
    final title = schedule.pickupPointName.isNotEmpty
        ? schedule.pickupPointName
        : 'Brgy. ${schedule.barangay}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Remove the schedule for "$title"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(schedule.id)
          .delete();
    }
  }
}