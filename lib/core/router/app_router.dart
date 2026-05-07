import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/community/home_screen.dart';
import '../../screens/community/map_screen.dart';
import '../../screens/community/schedule_screen.dart';
import '../../screens/community/education_screen.dart';
import '../../screens/community/profile_screen.dart';
import '../../screens/driver/driver_home_screen.dart';
import '../../screens/driver/add_schedule_screen.dart';
import '../../screens/admin/dashboard_screen.dart';
import '../../screens/admin/manage_users_screen.dart';
import '../../screens/admin/manage_materials_screen.dart';
import '../../screens/admin/manage_pickup_points_screen.dart';
import '../../widgets/shells/community_shell.dart';
import '../../widgets/shells/driver_shell.dart';
import '../../widgets/shells/admin_shell.dart';

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) {
        switch (auth.role) {
          case UserRole.admin: return '/admin/dashboard';
          case UserRole.driver: return '/driver/home';
          default: return '/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (_, __, child) => CommunityShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
          GoRoute(path: '/schedule', builder: (_, __) => const ScheduleScreen()),
          GoRoute(path: '/education', builder: (_, __) => const EducationScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      ShellRoute(
        builder: (_, __, child) => DriverShell(child: child),
        routes: [
          GoRoute(path: '/driver/home', builder: (_, __) => const DriverHomeScreen()),
          GoRoute(path: '/driver/add-schedule', builder: (_, __) => const AddScheduleScreen()),
          GoRoute(path: '/driver/map', builder: (_, __) => const MapScreen()),
          GoRoute(path: '/driver/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(path: '/admin/users', builder: (_, __) => const ManageUsersScreen()),
          GoRoute(path: '/admin/materials', builder: (_, __) => const ManageMaterialsScreen()),
          GoRoute(path: '/admin/pickup-points', builder: (_, __) => const ManagePickupPointsScreen()),
          GoRoute(path: '/admin/map', builder: (_, __) => const MapScreen()),
          GoRoute(path: '/admin/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
}