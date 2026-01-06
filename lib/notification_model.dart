enum NotificationType { lowStock, system }

class AppNotification {
  final String title;
  final String message;
  final DateTime time;
  final NotificationType type;
  bool isRead;

  AppNotification({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}
