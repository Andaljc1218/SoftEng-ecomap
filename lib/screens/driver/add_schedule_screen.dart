import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AddScheduleScreen extends StatelessWidget {
  const AddScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add Schedule')),
        body: const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_circle_outline, size: 64, color: AppTheme.primaryGreen),
            SizedBox(height: 16),
            Text('Add Pickup Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Form coming in Phase 4', style: TextStyle(color: Colors.grey)),
          ]),
        ),
      );
}