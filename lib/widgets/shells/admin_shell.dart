import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/admin/dashboard') return 0;
    if (location == '/admin/users') return 1;
    if (location == '/admin/materials') return 2;
    if (location == '/admin/pickup-points') return 3;
    if (location == '/admin/map') return 4;
    if (location == '/admin/profile') return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _selectedIndex(context);
    final auth = context.read<AuthProvider>();

    return Scaffold(
      body: child,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.primaryGreen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, color: AppTheme.primaryGreen, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(auth.currentUser?.name ?? 'Admin',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(auth.currentUser?.email ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            _tile(context, Icons.dashboard, 'Dashboard', '/admin/dashboard', index == 0),
            _tile(context, Icons.people, 'Manage Users', '/admin/users', index == 1),
            _tile(context, Icons.library_books, 'Manage Materials', '/admin/materials', index == 2),
            _tile(context, Icons.location_on, 'Pickup Points', '/admin/pickup-points', index == 3),
            _tile(context, Icons.map, 'Map', '/admin/map', index == 4),
            _tile(context, Icons.person, 'Profile', '/admin/profile', index == 5),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => context.read<AuthProvider>().logout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, String route, bool selected) {
    return ListTile(
      leading: Icon(icon, color: selected ? AppTheme.primaryGreen : null),
      title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      selected: selected,
      selectedTileColor: AppTheme.backgroundGreen,
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}