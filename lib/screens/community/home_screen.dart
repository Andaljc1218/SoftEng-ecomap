import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_notifications_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/eco_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final firstName = (user?.name ?? 'User').split(' ').first;

    return Scaffold(
      appBar: EcoAppBar(
        title: 'EcoMap',
        automaticallyImplyLeading: false,
        actions: [
          Consumer<CommunityNotificationsProvider>(
            builder: (context, notifications, _) {
              final unread = notifications.unreadCount;
              return Badge.count(
                count: unread,
                isLabelVisible: unread > 0,
                backgroundColor: EcoColors.gold,
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: () => context.push('/notifications'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero banner ──────────────────────────
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
                    Color(0xFF2E7D32),
                    Color(0xFF43A047),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: EcoColors.midGreen.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Decorative circle
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: -10,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EcoColors.gold.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: EcoColors.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: EcoColors.gold.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.eco_rounded,
                                    color: EcoColors.goldLight, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Batangas City',
                                  style: TextStyle(
                                    color: EcoColors.goldLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Hello, $firstName! 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Let\'s keep our city clean today.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.recycling_rounded,
                                color: Colors.white70, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Waste management made easy',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Section header ────────────────────────
            Row(
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
                const Text(
                  'Quick Access',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: EcoColors.textDark,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Quick access grid ─────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _QuickCard(
                  icon: Icons.map_rounded,
                  label: 'Pickup Map',
                  subtitle: 'Find locations',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00695C), Color(0xFF00897B)],
                  ),
                  onTap: () => context.go('/map'),
                ),
                _QuickCard(
                  icon: Icons.calendar_month_rounded,
                  label: 'Schedule',
                  subtitle: 'View pickups',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  ),
                  onTap: () => context.go('/schedule'),
                ),
                _QuickCard(
                  icon: Icons.menu_book_rounded,
                  label: 'Learn',
                  subtitle: 'Eco tips',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                  ),
                  onTap: () => context.go('/education'),
                ),
                _QuickCard(
                  icon: Icons.notifications_active_rounded,
                  label: 'Alerts',
                  subtitle: 'Updates',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                  ),
                  onTap: () => context.push('/notifications'),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Tip card ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: EcoColors.goldPale,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: EcoColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EcoColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.lightbulb_rounded,
                        color: EcoColors.gold, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eco Tip of the Day',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: EcoColors.textDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Segregate your waste before pickup for faster, cleaner collection.',
                          style: TextStyle(
                            fontSize: 12,
                            color: EcoColors.textMid,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              right: -12,
              top: -12,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}