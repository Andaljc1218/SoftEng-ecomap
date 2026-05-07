import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pickup Map')),
        body: const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.map, size: 64, color: EcoColors.primaryGreen),
            SizedBox(height: 16),
            Text('Interactive Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('flutter_map coming in Phase 3', style: TextStyle(color: Colors.grey)),
          ]),
        ),
      );
}