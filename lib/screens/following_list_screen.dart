import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../models/user.dart';
import '../utils/translations.dart';
import 'public_user_profile_screen.dart';

class FollowingListScreen extends StatelessWidget {
  final String userId;

  const FollowingListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final isCurrentUser = currentUser != null && currentUser.id == userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCurrentUser
              ? Translations.getText(context, 'following')
              : Translations.getText(context, 'following'),
        ),
      ),
      body: FutureBuilder<List<User>>(
        future: FirebaseService.getFollowing(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Erro ao carregar perfis seguidos. Tente novamente.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  Translations.getText(context, 'noFollowingYet'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.green.shade100,
                    backgroundImage:
                        user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                    child: user.photoUrl == null
                        ? Text(
                            _getInitials(user.name ?? user.email),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    user.name ?? user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${user.followersCount} ${Translations.getText(context, 'followers')} • ${user.totalReviews} ${Translations.getText(context, 'reviews').toLowerCase()}',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PublicUserProfileScreen(userId: user.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getInitials(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
