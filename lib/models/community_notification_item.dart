enum CommunityNotificationKind {
  newPickupPoint,
  newPickupSchedule,
  schedulePickupEnded,
}

class CommunityNotificationItem {
  final String id;
  final CommunityNotificationKind kind;
  final String title;
  final String subtitle;
  final DateTime sortTime;

  const CommunityNotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.sortTime,
  });
}
