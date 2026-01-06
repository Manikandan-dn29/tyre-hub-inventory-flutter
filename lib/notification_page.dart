import 'package:flutter/material.dart';
import 'notification_model.dart';
import 'notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    final notifications = NotificationService.notifications;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text("Notifications",style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: notifications.isEmpty
          ? const Center(
              child: Text(
                "No notifications",
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (_, index) {
                final n = notifications[index];

                return Card(
                  color: Colors.black87,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      n.type == NotificationType.lowStock
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline,
                      color: n.type == NotificationType.lowStock
                          ? Colors.redAccent
                          : Colors.blueAccent,
                    ),
                    title: Text(
                      n.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      n.message,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Text(
                      _formatTime(n.time),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                    onTap: () {
                      setState(() => n.isRead = true);
                    },
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
