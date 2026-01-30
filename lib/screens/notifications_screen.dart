import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../utils/translations.dart';
import '../theme/app_theme.dart';
import 'public_user_profile_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(Translations.getText(context, 'notifications')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              Translations.getText(context, 'mustBeLoggedIn'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.getText(context, 'notifications')),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: NotificationService.getUserNotifications(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  Translations.getText(context, 'leaderboardError'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  Translations.getText(context, 'noNotificationsYet'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final type = (notification['type'] as String?) ?? 'generic';
              final title = (notification['title'] as String?) ?? '';
              final message = (notification['message'] as String?) ?? '';
              final followerId = notification['followerId'] as String?;
              final notificationId = notification['id'] as String?;

              final icon = _iconForType(type);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    icon,
                    color: type == 'seal_progress'
                        ? AppTheme.premiumBlue
                        : Colors.green.shade700,
                  ),
                  title: Text(title.isNotEmpty ? title : Translations.getText(context, 'notifications')),
                  subtitle: Text(message),
                  onTap: () async {
                    if (notificationId != null) {
                      await NotificationService.markAsRead(notificationId);
                    }
                    if (type == 'new_follower' && followerId != null && followerId.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PublicUserProfileScreen(userId: followerId),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_follower':
        return Icons.person_add;
      case 'new_certified_establishment':
        return Icons.verified;
      case 'seal_progress':
        return Icons.workspace_premium;
      case 'coupon_available':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }
}
