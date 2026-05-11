import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameKey = GlobalKey<FormState>();
  final _passKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _editingName = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl.text = user?.name ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (!_nameKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.updateName(_nameCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Name updated!' : auth.errorMessage ?? 'Failed to update name.'),
      backgroundColor: success ? EcoColors.primaryGreen : Colors.red,
    ));
    if (success) setState(() => _editingName = false);
  }

  Future<void> _changePassword() async {
    if (!_passKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(
      currentPassword: _currentPassCtrl.text,
      newPassword: _newPassCtrl.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Password changed!' : auth.errorMessage ?? 'Failed to change password.'),
      backgroundColor: success ? EcoColors.primaryGreen : Colors.red,
    ));
    if (success) {
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final passCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action is permanent and cannot be undone. Enter your password to confirm.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
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

    if (confirmed == true && mounted) {
      final auth = context.read<AuthProvider>();
      final success = await auth.deleteAccount(passCtrl.text);
      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to delete account.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar + info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [EcoColors.primaryGreen, EcoColors.lightGreen],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 44, color: EcoColors.primaryGreen),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? 'User',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(user?.email ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(user?.roleLabel ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Edit name
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _nameKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Display Name',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          TextButton.icon(
                            icon: Icon(_editingName ? Icons.close : Icons.edit, size: 18),
                            label: Text(_editingName ? 'Cancel' : 'Edit'),
                            onPressed: () => setState(() {
                              _editingName = !_editingName;
                              if (!_editingName) _nameCtrl.text = user?.name ?? '';
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameCtrl,
                        enabled: _editingName,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Name cannot be empty' : null,
                      ),
                      if (_editingName) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _saveName,
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Save Name'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Change password
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _passKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Change Password',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _currentPassCtrl,
                        obscureText: _obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscureCurrent = !_obscureCurrent),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter current password' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newPassCtrl,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.length < 6 ? 'Min 6 characters' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPassCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) =>
                            v != _newPassCtrl.text ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _changePassword,
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Change Password'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () => context.read<AuthProvider>().logout(),
              ),
            ),
            const SizedBox(height: 8),

            // Delete account
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Delete Account',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () => _showDeleteDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}