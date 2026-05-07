import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Manage Users')),
        body: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.people, size: 64, color: EcoColors.primaryGreen),
          SizedBox(height: 16),
          Text('User Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('CRUD interface coming in Phase 4', style: TextStyle(color: Colors.grey)),
        ])),
      );
}