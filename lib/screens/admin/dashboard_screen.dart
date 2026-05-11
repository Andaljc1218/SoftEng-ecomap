import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<int> _count(String collection) async {
    final snap = await FirebaseFirestore.instance
        .collection(collection)
        .count()
        .get();
    return snap.count ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoMap Admin'),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
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
                  Text('Hello, ${user?.name ?? 'Admin'}! 👋',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Manage EcoMap from here.',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live stats
            const Text('Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _LiveStatCard(
                  label: 'Community Users',
                  future: _count('community_users'),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                _LiveStatCard(
                  label: 'Drivers',
                  future: _count('drivers'),
                  icon: Icons.local_shipping,
                  color: Colors.orange,
                ),
                _LiveStatCard(
                  label: 'Articles',
                  future: _count('education_articles'),
                  icon: Icons.library_books,
                  color: Colors.purple,
                ),
                _LiveStatCard(
                  label: 'Pickup Points',
                  future: _count('pickup_points'),
                  icon: Icons.location_on,
                  color: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick access
            const Text('Quick Access',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _ManageTile(
              icon: Icons.people,
              label: 'Manage Users',
              color: Colors.blue,
              onTap: () => context.go('/admin/users'),
            ),
            const SizedBox(height: 8),
            _ManageTile(
              icon: Icons.library_books,
              label: 'Manage Materials',
              color: Colors.purple,
              onTap: () => context.go('/admin/materials'),
            ),
            const SizedBox(height: 8),
            _ManageTile(
              icon: Icons.location_on,
              label: 'Manage Pickup Points',
              color: Colors.teal,
              onTap: () => context.go('/admin/pickup-points'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveStatCard extends StatelessWidget {
  final String label;
  final Future<int> future;
  final IconData icon;
  final Color color;

  const _LiveStatCard({
    required this.label,
    required this.future,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            FutureBuilder<int>(
              future: future,
              builder: (_, snap) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snap.connectionState == ConnectionState.done
                        ? '${snap.data ?? 0}'
                        : '—',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ManageTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 16),
                Text(label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
}