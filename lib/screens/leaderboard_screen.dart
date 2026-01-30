import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../models/user.dart';
import '../models/user_seal.dart';
import '../providers/auth_provider.dart';
import '../utils/translations.dart';
import 'public_user_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<User>> _futureTopUsers;
  final Map<String, bool> _followingState = {};
  final Set<String> _loadingFollowUserIds = {};

  @override
  void initState() {
    super.initState();
    _futureTopUsers = FirebaseService.getTopUsers(limit: 50);
    _initializeFollowingState();
  }

  Future<void> _initializeFollowingState() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      if (currentUser == null) return;

      final users = await _futureTopUsers;
      for (final user in users) {
        if (user.id == currentUser.id) continue;
        final isFollowing = await FirebaseService.isFollowing(currentUser.id, user.id);
        _followingState[user.id] = isFollowing;
      }

      if (!mounted) return;
      setState(() {});
    } catch (_) {
      // Silenciar erros para não quebrar a tela de ranking
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      appBar: AppBar(
        title: Text(Translations.getText(context, 'topReviewers')),
        elevation: 0,
      ),
      body: FutureBuilder<List<User>>(
        future: _futureTopUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  Translations.getText(context, 'leaderboardError') ?? 'Erro ao carregar ranking.',
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
                  Translations.getText(context, 'leaderboardEmpty') ?? 'Ainda não há avaliadores suficientes para o ranking.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final startIndex = users.length >= 3 ? 3 : users.length;

          return Column(
            children: [
              _buildTopSection(context, users),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: users.length - startIndex,
                  itemBuilder: (context, index) {
                    final actualIndex = startIndex + index;
                    final user = users[actualIndex];
                    final position = actualIndex + 1;
                    return _buildUserListItem(context, user, position);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, List<User> users) {
    final hasUsers = users.isNotEmpty;
    final top1 = hasUsers ? users[0] : null;
    final top2 = users.length > 1 ? users[1] : null;
    final top3 = users.length > 2 ? users[2] : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4C3BCF), Color(0xFF7B5CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Translations.getText(context, 'topReviewers'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Translations.getText(context, 'reviews'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          if (hasUsers)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: top2 != null
                      ? _buildTopCard(context, top2, 2, height: 150)
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: top1 != null
                      ? _buildTopCard(context, top1, 1, height: 170, highlight: true)
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: top3 != null
                      ? _buildTopCard(context, top3, 3, height: 150)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTopCard(BuildContext context, User user, int position,
      {double height = 150, bool highlight = false}) {
    Color medalColor;
    if (position == 1) {
      medalColor = const Color(0xFFFFD700);
    } else if (position == 2) {
      medalColor = const Color(0xFFC0C0C0);
    } else {
      medalColor = const Color(0xFFCD7F32);
    }

    return GestureDetector(
      onTap: () => _openUserProfile(user),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: highlight ? 26 : 24,
                      backgroundColor: Colors.green.shade100,
                      backgroundImage:
                          user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                      child: user.photoUrl == null
                          ? Text(
                              _getInitials(user.name ?? user.email),
                              style: TextStyle(
                                fontSize: highlight ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: medalColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        position.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              user.name ?? user.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${user.points} pts',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListItem(BuildContext context, User user, int position) {
    Color medalColor;
    if (position == 1) {
      medalColor = const Color(0xFFFFD700);
    } else if (position == 2) {
      medalColor = const Color(0xFFC0C0C0);
    } else if (position == 3) {
      medalColor = const Color(0xFFCD7F32);
    } else {
      medalColor = Colors.grey.shade400;
    }

    return InkWell(
      onTap: () => _openUserProfile(user),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              alignment: Alignment.center,
              child: Text(
                position.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: medalColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green.shade100,
                  backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  child: user.photoUrl == null
                      ? Text(
                          _getInitials(user.name ?? user.email),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.totalReviews} ${Translations.getText(context, 'reviews').toLowerCase()} · ${user.points} pts · ${user.followersCount} ${Translations.getText(context, 'followers')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildTrailingForUser(user),
          ],
        ),
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

  Widget _buildTrailingForUser(User user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    final String? communityBadgeKey = _getCommunityBadgeKey(user.followersCount);
    final String sealLabelKey = _getSealLabelKey(user.seal);
    final String sealDescriptionKey = _getSealDescriptionKey(user.seal);

    final sealWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${Translations.getText(context, 'seal')} ${Translations.getText(context, sealLabelKey)}',
          style: TextStyle(
            fontSize: 12,
            color: user.seal.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Translations.getText(context, sealDescriptionKey),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        if (communityBadgeKey != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_people,
                size: 14,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                Translations.getText(context, communityBadgeKey),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );

    if (currentUser == null || currentUser.id == user.id) {
      return sealWidget;
    }

    final isFollowing = _followingState[user.id] ?? false;
    final isLoading = _loadingFollowUserIds.contains(user.id);
    final labelKey = isFollowing ? 'followingVerb' : 'follow';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        sealWidget,
        const SizedBox(height: 8),
        SizedBox(
          height: 30,
          child: TextButton.icon(
            onPressed: isLoading ? null : () => _toggleFollow(user),
            icon: isLoading
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    isFollowing ? Icons.person : Icons.person_add,
                    size: 16,
                  ),
            label: Text(
              Translations.getText(context, labelKey),
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFollow(User targetUser) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null || currentUser.id == targetUser.id) {
      return;
    }

    final targetId = targetUser.id;
    if (_loadingFollowUserIds.contains(targetId)) {
      return;
    }

    setState(() {
      _loadingFollowUserIds.add(targetId);
    });

    final isCurrentlyFollowing = _followingState[targetId] ?? false;

    try {
      if (isCurrentlyFollowing) {
        await FirebaseService.unfollowUser(
          currentUserId: currentUser.id,
          targetUserId: targetId,
        );
      } else {
        await FirebaseService.followUser(
          currentUserId: currentUser.id,
          targetUserId: targetId,
        );
      }

      if (!mounted) return;
      setState(() {
        _followingState[targetId] = !isCurrentlyFollowing;
        _loadingFollowUserIds.remove(targetId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingFollowUserIds.remove(targetId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao atualizar seguidores. Tente novamente.'),
        ),
      );
    }
  }

  void _openUserProfile(User user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicUserProfileScreen(userId: user.id),
      ),
    );
  }

  String? _getCommunityBadgeKey(int followersCount) {
    if (followersCount >= 50) {
      return 'communityBadgeAmbassador';
    } else if (followersCount >= 25) {
      return 'communityBadgeInfluencer';
    } else if (followersCount >= 10) {
      return 'communityBadgeConnector';
    }
    return null;
  }

  String _getSealLabelKey(UserSeal seal) {
    switch (seal) {
      case UserSeal.bronze:
        return 'userSealBronzeLabel';
      case UserSeal.silver:
        return 'userSealSilverLabel';
      case UserSeal.gold:
        return 'userSealGoldLabel';
    }
  }

  String _getSealDescriptionKey(UserSeal seal) {
    switch (seal) {
      case UserSeal.bronze:
        return 'userSealBronzeDescription';
      case UserSeal.silver:
        return 'userSealSilverDescription';
      case UserSeal.gold:
        return 'userSealGoldDescription';
    }
  }
}
