import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Education')),
        body: const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.library_books, size: 64, color: AppTheme.primaryGreen),
            SizedBox(height: 16),
            Text('Educational Resources', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('PDF, video, search coming in Phase 3', style: TextStyle(color: Colors.grey)),
          ]),
        ),
      );
}