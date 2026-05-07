import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pickup Schedule')),
        body: const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.calendar_today, size: 64, color: EcoColors.primaryGreen),
            SizedBox(height: 16),
            Text('Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('List & Calendar view coming in Phase 3', style: TextStyle(color: Colors.grey)),
          ]),
        ),
      );
}