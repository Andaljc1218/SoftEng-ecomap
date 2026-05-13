import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/eco_app_bar.dart';
import '../../models/community_notification_item.dart';
import '../../providers/community_notifications_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  CommunityNotificationsProvider? _notifications;
  bool _markedAfterItemsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<CommunityNotificationsProvider>();
      _notifications = p;
      p.addListener(_onNotificationsChanged);
      _tryMarkAllRead();
    });
  }

  void _onNotificationsChanged() {
    _tryMarkAllRead();
  }

  void _tryMarkAllRead() {
    final p = _notifications;
    if (p == null || !mounted) return;
    if (p.items.isEmpty) return;
    if (_markedAfterItemsLoaded) return;
    _markedAfterItemsLoaded = true;
    unawaited(p.markAllRead());
  }

  @override
  void dispose() {
    final p = _notifications;
    if (p != null) {
      p.removeListener(_onNotificationsChanged);
      unawaited(p.markAllRead());
    }
    super.dispose();
  }

  IconData _iconFor(CommunityNotificationKind k) {
    switch (k) {
      case CommunityNotificationKind.newPickupPoint:
        return Icons.add_location_alt_outlined;
      case CommunityNotificationKind.newPickupSchedule:
        return Icons.calendar_month_outlined;
      case CommunityNotificationKind.schedulePickupEnded:
        return Icons.event_available_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityNotificationsProvider>();
    final items = provider.items;

    return Scaffold(
      appBar: EcoAppBar(
        title: 'Notifications',
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_outlined,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You will see updates when a new pickup point is added, '
                      'when drivers publish pickup schedules, and when scheduled '
                      'pickup rounds have finished.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = items[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: EcoColors.backgroundGreen,
                      child: Icon(
                        _iconFor(n.kind),
                        color: EcoColors.primaryGreen,
                      ),
                    ),
                    title: Text(
                      n.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(n.subtitle),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
