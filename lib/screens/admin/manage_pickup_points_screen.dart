import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ManagePickupPointsScreen extends StatelessWidget {
  const ManagePickupPointsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Manage Pickup Points')),
        body: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.location_on, size: 64, color: AppTheme.primaryGreen),
          SizedBox(height: 16),
          Text('Pickup Point Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Map pin management coming in Phase 4', style: TextStyle(color: Colors.grey)),
        ])),
      );
}