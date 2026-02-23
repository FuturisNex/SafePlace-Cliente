import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../services/gamification_service.dart';
import '../models/user.dart';
import '../models/user_seal.dart';
import '../models/trail_record.dart';
import '../models/checkin.dart';
import '../providers/auth_provider.dart';
import '../utils/translations.dart';
import '../theme/app_theme.dart';

class PublicUserProfileScreen extends StatefulWidget {
  final String userId;

  const PublicUserProfileScreen({super.key, required this.userId});

  @override
  State<PublicUserProfileScreen> createState() => _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState extends State<PublicUserProfileScreen> {
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  bool _initializedFollow = false;

  Future<void> _ensureFollowState(User profileUser) async {
    if (_initializedFollow || !mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null || currentUser.id == profileUser.id) {
      setState(() {
        _initializedFollow = true;
      });
      return;
    }

    try {
      final isFollowing = await FirebaseService.isFollowing(currentUser.id, profileUser.id);
      if (!mounted) return;
      setState(() {
        _isFollowing = isFollowing;
        _initializedFollow = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializedFollow = true;
      });
    }
  }

  Future<void> _toggleFollow(User profileUser) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null || currentUser.id == profileUser.id) {
      return;
    }
    if (_isLoadingFollow) return;

    setState(() {
      _isLoadingFollow = true;
    });

    final wasFollowing = _isFollowing;
    try {
      if (wasFollowing) {
        await FirebaseService.unfollowUser(
          currentUserId: currentUser.id,
          targetUserId: profileUser.id,
        );
      } else {
        await FirebaseService.followUser(
          currentUserId: currentUser.id,
          targetUserId: profileUser.id,
        );
      }

      if (!mounted) return;
      setState(() {
        _isFollowing = !wasFollowing;
        _isLoadingFollow = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingFollow = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.getText(context, 'profile')), // Reaproveita chave existente
      ),
      body: FutureBuilder<User?>(
        future: FirebaseService.getUserData(widget.userId),
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

          final user = snapshot.data;
          if (user == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  Translations.getText(context, 'noUserLoggedIn'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (user != null) {
              _ensureFollowState(user);
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(context, user),
                const SizedBox(height: 16),
                // Seção de Check-ins
                _buildCheckInsSection(context, user),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translations.getText(context, 'trailHistoryTitle'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<List<TrailRecord>>(
                          future: FirebaseService.getUserTrailRecords(user.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Text(
                                Translations.getText(context, 'trailHistoryEmpty'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              );
                            }

                            final trails = snapshot.data ?? [];
                            if (trails.isEmpty) {
                              return Text(
                                Translations.getText(context, 'trailHistoryEmpty'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              );
                            }

                            return Column(
                              children: trails.take(5).map((trail) {
                                final dateText = DateFormat('dd/MM/yyyy HH:mm').format(trail.createdAt);
                                final subtitle = trail.address?.isNotEmpty == true
                                    ? '${trail.address} · $dateText'
                                    : dateText;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.shade50,
                                    child: Icon(
                                      Icons.directions_walk,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  title: Text(
                                    trail.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.green.shade700),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton(BuildContext context, User profileUser) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null || currentUser.id == profileUser.id) {
      return const SizedBox.shrink();
    }

    final labelKey = _isFollowing ? 'followingVerb' : 'follow';

    return OutlinedButton.icon(
      onPressed: _isLoadingFollow ? null : () => _toggleFollow(profileUser),
      icon: _isLoadingFollow
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isFollowing ? Icons.person : Icons.person_add,
              size: 16,
            ),
      label: Text(
        Translations.getText(context, labelKey),
        style: const TextStyle(fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        side: BorderSide(color: Colors.green.shade400),
        foregroundColor: Colors.green.shade700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
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

  Widget _buildProfileHeader(BuildContext context, User user) {
    final sealLabelKey = _getSealLabelKey(user.seal);

    return Stack(
      children: [
        // Capa (cover photo)
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                user.coverPhotoUrl ??
                    'https://images.unsplash.com/photo-1493770348161-369560ae357d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.8),
                  Colors.white,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // Conteúdo do perfil (similar ao perfil pessoal, sem botões de edição)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Avatar com borda de selo
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: user.seal.color,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: user.seal.color.withOpacity(0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                      color: Colors.white,
                    ),
                  ),
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage:
                        user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                    child: user.photoUrl == null
                        ? Text(
                            _getInitials(user.name ?? user.email),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: user.seal.color,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nome e selo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.name ?? Translations.getText(context, 'user'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),

              // Chip de selo
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: user.seal.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${Translations.getText(context, 'seal')} '
                  '${Translations.getText(context, sealLabelKey)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: user.seal.color,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Linha de estatísticas (igual conceito do perfil pessoal)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    context,
                    Icons.star,
                    Translations.getText(context, 'reviews'),
                    user.totalReviews.toString(),
                  ),
                  _buildStatItem(
                    context,
                    Icons.group,
                    Translations.getText(context, 'followers'),
                    user.followersCount.toString(),
                  ),
                  _buildStatItem(
                    context,
                    Icons.person_add,
                    Translations.getText(context, 'following'),
                    user.followingCount.toString(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Botão seguir / deixar de seguir
              Align(
                alignment: Alignment.center,
                child: _buildFollowButton(context, user),
              ),
            ],
          ),
        ),
      ],
    );
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

  /// Seção de check-ins do usuário
  Widget _buildCheckInsSection(BuildContext context, User user) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.place, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  Translations.getText(context, 'checkInHistory'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<CheckIn>>(
              future: GamificationService.getUserCheckIns(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Erro ao carregar check-ins',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  );
                }

                final checkIns = snapshot.data ?? [];
                if (checkIns.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Nenhum check-in registrado ainda.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  );
                }

                // Mostrar até 5 check-ins mais recentes
                return Column(
                  children: checkIns.take(5).map((checkIn) {
                    final dateText = DateFormat('dd/MM/yyyy HH:mm').format(checkIn.createdAt);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: Icon(
                          Icons.location_on,
                          color: Colors.green.shade700,
                        ),
                      ),
                      title: Text(
                        checkIn.establishmentName ?? 'Estabelecimento',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: checkIn.rating != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  checkIn.rating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
