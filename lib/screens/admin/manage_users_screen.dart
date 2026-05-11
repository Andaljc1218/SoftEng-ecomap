import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _collectionForTab(int index) {
    switch (index) {
      case 0: return 'community_users';
      case 1: return 'drivers';
      default: return 'admins';
    }
  }

  UserRole _roleForTab(int index) {
    switch (index) {
      case 0: return UserRole.community;
      case 1: return UserRole.driver;
      default: return UserRole.admin;
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin: return Colors.red;
      case UserRole.driver: return Colors.orange;
      case UserRole.community: return Colors.blue;
    }
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin: return Icons.admin_panel_settings;
      case UserRole.driver: return Icons.local_shipping;
      case UserRole.community: return Icons.people;
    }
  }

  Future<void> _deleteUser(String collection, String uid, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Remove $name from EcoMap? This only removes their data — their Firebase Auth account remains.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.collection(collection).doc(uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name removed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changeRole(UserModel user, String fromCollection) async {
    UserRole? newRole = await showDialog<UserRole>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Change Role'),
        children: UserRole.values.map((role) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, role),
            child: Row(children: [
              Icon(_roleIcon(role), color: _roleColor(role), size: 20),
              const SizedBox(width: 12),
              Text(UserModel(
                id: '', name: '', email: '', role: role,
              ).roleLabel),
            ]),
          );
        }).toList(),
      ),
    );

    if (newRole == null || newRole == user.role) return;

    final toCollection = _collectionForTab(
      newRole == UserRole.community ? 0 : newRole == UserRole.driver ? 1 : 2,
    );

    // Move document to new collection
    final newUser = UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      role: newRole,
    );

    final batch = _db.batch();
    batch.delete(_db.collection(fromCollection).doc(user.id));
    batch.set(_db.collection(toCollection).doc(user.id), newUser.toMap());
    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} moved to ${newUser.roleLabel}.'),
          backgroundColor: EcoColors.primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.people, size: 18), text: 'Community'),
            Tab(icon: Icon(Icons.local_shipping, size: 18), text: 'Drivers'),
            Tab(icon: Icon(Icons.admin_panel_settings, size: 18), text: 'Admins'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(3, (tabIndex) {
          final collection = _collectionForTab(tabIndex);
          final role = _roleForTab(tabIndex);
          return StreamBuilder<QuerySnapshot>(
            stream: _db.collection(collection).orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_roleIcon(role), size: 56, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('No ${role.name} users yet.',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              final users = docs
                  .map((d) =>
                      UserModel.fromMap(d.id, d.data() as Map<String, dynamic>))
                  .toList();

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final user = users[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _roleColor(role).withValues(alpha: 0.15),
                        child: Icon(_roleIcon(role),
                            color: _roleColor(role), size: 22),
                      ),
                      title: Text(user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(user.email,
                          style: const TextStyle(fontSize: 12)),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (val) {
                          if (val == 'role') {
                            _changeRole(user, collection);
                          } else if (val == 'delete') {
                            _deleteUser(collection, user.id, user.name);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'role',
                            child: Row(children: [
                              Icon(Icons.swap_horiz, size: 18),
                              SizedBox(width: 8),
                              Text('Change Role'),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        }),
      ),
    );
  }
}