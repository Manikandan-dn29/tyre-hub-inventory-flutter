import 'notification_model.dart';

class NotificationService {
  static List<AppNotification> notifications = [
    AppNotification(
      title: "Low Stock Alert",
      message: "Tyre SKU TY-204 is below minimum level",
      time: DateTime.now().subtract(const Duration(minutes: 10)),
      type: NotificationType.lowStock,
    ),
    AppNotification(
      title: "System Message",
      message: "Stock sync completed successfully",
      time: DateTime.now().subtract(const Duration(hours: 1)),
      type: NotificationType.system,
    ),
  ];

  static int unreadCount() =>
      notifications.where((n) => !n.isRead).length;
}
