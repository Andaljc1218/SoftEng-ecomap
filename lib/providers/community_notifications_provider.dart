import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/community_notification_item.dart';
import '../models/pickup_point.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

const _kSeenIds = 'community_notification_seen_ids';

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _monthAbbr = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatCalendarDay(DateTime d) {
  return '${_monthAbbr[d.month - 1]} ${d.day}, ${d.year}';
}

TimeOfDay? _parsePickupTime(String raw) {
  final s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  final m = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)?$').firstMatch(s);
  if (m == null) return null;
  var hour = int.tryParse(m.group(1)!);
  final minute = int.tryParse(m.group(2)!);
  if (hour == null || minute == null || minute > 59) return null;
  final ap = m.group(3)?.toUpperCase();
  if (ap == 'PM' && hour < 12) hour += 12;
  if (ap == 'AM' && hour == 12) hour = 0;
  if (hour > 23) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _weekdayName(int weekday) => _weekdayNames[weekday - 1];

/// Recurring pickup days at [time] that have fully ended (4h window after start),
/// only for occurrences on or after [schedule.createdAt].
List<CommunityNotificationItem> _scheduleEndedNotifications(
  PickupSchedule schedule,
  DateTime now,
) {
  final tod = _parsePickupTime(schedule.time);
  if (tod == null || schedule.days.isEmpty) return [];

  final items = <CommunityNotificationItem>[];
  final today = DateTime(now.year, now.month, now.day);
  final horizon = today.subtract(const Duration(days: 90));
  var day = today;

  while (!day.isBefore(horizon) && items.length < 10) {
    final wname = _weekdayName(day.weekday);
    if (schedule.days.contains(wname)) {
      final occStart = DateTime(day.year, day.month, day.day, tod.hour, tod.minute);
      if (!occStart.isBefore(schedule.createdAt)) {
        final occEnd = occStart.add(const Duration(hours: 4));
        if (now.isAfter(occEnd)) {
          final id = 'sched_done_${schedule.id}_${day.year}_${day.month}_${day.day}';
          items.add(CommunityNotificationItem(
            id: id,
            kind: CommunityNotificationKind.schedulePickupEnded,
            title: 'Pickup round completed',
            subtitle:
                'Brgy. ${schedule.barangay} · ${schedule.time} · ${_formatCalendarDay(day)} · ${schedule.wasteType}',
            sortTime: occEnd,
          ));
        }
      }
    }
    day = day.subtract(const Duration(days: 1));
  }
  return items;
}

class CommunityNotificationsProvider extends ChangeNotifier {
  CommunityNotificationsProvider(this._auth) {
    _auth.addListener(_syncAuth);
    _syncAuth();
  }

  final AuthProvider _auth;

  StreamSubscription<QuerySnapshot>? _pickupSub;
  StreamSubscription<QuerySnapshot>? _scheduleSub;
  bool _attached = false;

  QuerySnapshot? _lastPickupSnap;
  QuerySnapshot? _lastScheduleSnap;

  final Set<String> _seen = {};
  bool _prefsLoaded = false;

  List<CommunityNotificationItem> _items = [];

  List<CommunityNotificationItem> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((e) => !_seen.contains(e.id)).length;

  void _syncAuth() {
    final community =
        _auth.isLoggedIn && _auth.role == UserRole.community;
    if (community) {
      _startListening();
    } else {
      _stopListening();
      _items = [];
      notifyListeners();
    }
  }

  Future<void> _ensurePrefs() async {
    if (_prefsLoaded) return;
    final p = await SharedPreferences.getInstance();
    _seen.addAll(p.getStringList(_kSeenIds) ?? const []);
    _prefsLoaded = true;
  }

  Future<void> _persistSeen() async {
    final p = await SharedPreferences.getInstance();
    final list = _seen.toList()..sort();
    if (list.length > 400) {
      _seen
        ..clear()
        ..addAll(list.sublist(list.length - 400));
    }
    await p.setStringList(_kSeenIds, _seen.toList()..sort());
  }

  void _startListening() {
    if (_attached) return;
    _attached = true;
    unawaited(_ensurePrefs().then((_) {
      _rebuildIfReady();
      notifyListeners();
    }));

    _pickupSub = FirebaseFirestore.instance
        .collection('pickup_points')
        .snapshots()
        .listen((snap) {
      _lastPickupSnap = snap;
      _rebuildIfReady();
      notifyListeners();
    });

    _scheduleSub = FirebaseFirestore.instance
        .collection('schedules')
        .snapshots()
        .listen((snap) {
      _lastScheduleSnap = snap;
      _rebuildIfReady();
      notifyListeners();
    });
  }

  void _stopListening() {
    _pickupSub?.cancel();
    _scheduleSub?.cancel();
    _pickupSub = null;
    _scheduleSub = null;
    _attached = false;
    _lastPickupSnap = null;
    _lastScheduleSnap = null;
  }

  void _rebuildIfReady() {
    final pSnap = _lastPickupSnap;
    final sSnap = _lastScheduleSnap;
    if (pSnap == null || sSnap == null) return;

    final now = DateTime.now();
    final out = <CommunityNotificationItem>[];

    for (final d in pSnap.docs) {
      final data = d.data() as Map<String, dynamic>;
      final point = PickupPoint.fromMap(d.id, data);
      final created = point.createdAt;
      if (created == null) continue;
      out.add(CommunityNotificationItem(
        id: 'pickup_new_${point.id}',
        kind: CommunityNotificationKind.newPickupPoint,
        title: 'New garbage pickup point',
        subtitle: '${point.name} · Brgy. ${point.barangay}',
        sortTime: created,
      ));
    }

    for (final d in sSnap.docs) {
      final schedule = PickupSchedule.fromMap(d.id, d.data() as Map<String, dynamic>);
      final loc = schedule.pickupPointName.isNotEmpty
          ? schedule.pickupPointName
          : 'Brgy. ${schedule.barangay}';
      // Avoid flooding with ancient data: only "new schedule" rows for recent adds.
      if (now.difference(schedule.createdAt) <= const Duration(days: 60)) {
        out.add(CommunityNotificationItem(
          id: 'sched_added_${schedule.id}',
          kind: CommunityNotificationKind.newPickupSchedule,
          title: 'New pickup schedule',
          subtitle:
              '$loc · ${schedule.daysLabel} · ${schedule.time} · ${schedule.driverName}',
          sortTime: schedule.createdAt,
        ));
      }
      out.addAll(_scheduleEndedNotifications(schedule, now));
    }

    out.sort((a, b) => b.sortTime.compareTo(a.sortTime));
    if (out.length > 100) {
      _items = out.sublist(0, 100);
    } else {
      _items = out;
    }
  }

  Future<void> markAllRead() async {
    await _ensurePrefs();
    _seen.addAll(_items.map((e) => e.id));
    await _persistSeen();
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_syncAuth);
    _stopListening();
    super.dispose();
  }
}
