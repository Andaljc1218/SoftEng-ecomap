import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/eco_app_bar.dart';

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
    final firstName = (user?.name ?? 'Admin').split(' ').first;

    return Scaffold(
      appBar: EcoAppBar(
        title: 'EcoMap Admin',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A3D0A),
                    Color(0xFF1B5E20),
                    Color(0xFF43A047),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: EcoColors.midGreen.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: EcoColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: EcoColors.gold.withValues(alpha: 0.35)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings_rounded,
                                color: EcoColors.goldLight, size: 12),
                            SizedBox(width: 4),
                            Text('Administrator',
                                style: TextStyle(
                                    color: EcoColors.goldLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Hello, $firstName! 👋',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text('Manage EcoMap from here.',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _SectionHeader(label: 'Overview'),
            const SizedBox(height: 14),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _LiveStatCard(
                  label: 'Community',
                  future: _count('community_users'),
                  icon: Icons.people_rounded,
                  color: const Color(0xFF1565C0),
                  bgColor: const Color(0xFFE3F2FD),
                ),
                _LiveStatCard(
                  label: 'Drivers',
                  future: _count('drivers'),
                  icon: Icons.local_shipping_rounded,
                  color: const Color(0xFFE65100),
                  bgColor: const Color(0xFFFFF3E0),
                ),
                _LiveStatCard(
                  label: 'Articles',
                  future: _count('education_articles'),
                  icon: Icons.library_books_rounded,
                  color: const Color(0xFF6A1B9A),
                  bgColor: const Color(0xFFF3E5F5),
                ),
                _LiveStatCard(
                  label: 'Pickup Points',
                  future: _count('pickup_points'),
                  icon: Icons.location_on_rounded,
                  color: const Color(0xFF00695C),
                  bgColor: const Color(0xFFE0F2F1),
                ),
              ],
            ),
            const SizedBox(height: 28),

            _SectionHeader(label: 'Quick Access'),
            const SizedBox(height: 14),

            _ManageTile(
              icon: Icons.people_rounded,
              label: 'Manage Users',
              subtitle: 'View, edit and assign roles',
              color: const Color(0xFF1565C0),
              bgColor: const Color(0xFFE3F2FD),
              onTap: () => context.go('/admin/users'),
            ),
            const SizedBox(height: 10),
            _ManageTile(
              icon: Icons.library_books_rounded,
              label: 'Manage Materials',
              subtitle: 'Upload articles and files',
              color: const Color(0xFF6A1B9A),
              bgColor: const Color(0xFFF3E5F5),
              onTap: () => context.go('/admin/materials'),
            ),
            const SizedBox(height: 10),
            _ManageTile(
              icon: Icons.location_on_rounded,
              label: 'Manage Pickup Points',
              subtitle: 'Pin locations on the map',
              color: const Color(0xFF00695C),
              bgColor: const Color(0xFFE0F2F1),
              onTap: () => context.go('/admin/pickup-points'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [EcoColors.midGreen, EcoColors.freshGreen],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: EcoColors.textDark,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
}

class _LiveStatCard extends StatelessWidget {
  final String label;
  final Future<int> future;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _LiveStatCard({
    required this.label,
    required this.future,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EcoColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EcoColors.divider),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          FutureBuilder<int>(
            future: future,
            builder: (_, snap) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snap.connectionState == ConnectionState.done
                      ? '${snap.data ?? 0}'
                      : '—',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: EcoColors.textLight,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ManageTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EcoColors.cardSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EcoColors.divider),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: EcoColors.textDark)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: EcoColors.textLight)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: color.withValues(alpha: 0.6), size: 16),
            ],
          ),
        ),
      );
}