import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ManageMaterialsScreen extends StatelessWidget {
  const ManageMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Manage Materials')),
        body: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.library_books, size: 64, color: EcoColors.primaryGreen),
          SizedBox(height: 16),
          Text('Educational Materials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Upload/edit/delete coming in Phase 4', style: TextStyle(color: Colors.grey)),
        ])),
      );
}