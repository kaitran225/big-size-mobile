import 'package:flutter/material.dart';

import '../models/store_product.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<StoreNotification>> _notifications;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _notifications = widget.api.getNotifications();
  }

  Future<void> _markRead(StoreNotification notification) async {
    try {
      await widget.api.markNotificationRead(notification.id);
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(displayError(error))));
      }
    }
  }

  Future<void> _delete(StoreNotification notification) async {
    try {
      await widget.api.deleteNotification(notification.id);
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(displayError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(AppStrings.notificationsTitle),
      actions: [
        IconButton(
          tooltip: AppStrings.tooltipRefresh,
          onPressed: () => setState(_reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(34),
        child: Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(AppStrings.pushNotConnectedNotice),
        ),
      ),
    ),
    body: FutureBuilder<List<StoreNotification>>(
      future: _notifications,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(displayError(snapshot.error!)));
        }
        final notifications = snapshot.data!;
        if (notifications.isEmpty) {
          return const Center(child: Text(AppStrings.notificationsEmpty));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = notifications[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  item.isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: item.isRead
                        ? FontWeight.normal
                        : FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  AppStrings.notificationSubtitle(
                    item.message,
                    formatDate(item.createdAt),
                  ),
                ),
                isThreeLine: true,
                onTap: item.isRead ? null : () => _markRead(item),
                trailing: IconButton(
                  tooltip: AppStrings.tooltipDeleteNotification,
                  onPressed: () => _delete(item),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
