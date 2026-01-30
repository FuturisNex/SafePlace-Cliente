import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/review.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../utils/translations.dart';
import '../screens/public_user_profile_screen.dart';

class ReviewCard extends StatefulWidget {
  final Review review;

  const ReviewCard({
    super.key,
    required this.review,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  bool _isLiked = false;
  bool _isLoadingLike = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.review.likesCount;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      if (currentUser == null) return;

      if (currentUser.id != widget.review.userId) {
        try {
          final isFollowing =
              await FirebaseService.isFollowing(currentUser.id, widget.review.userId);
          if (!mounted) return;
          setState(() {
            _isFollowing = isFollowing;
          });
        } catch (_) {
          // Ignorar erros silenciosamente para não quebrar o card
        }
      }

      try {
        final isLiked = await FirebaseService.isReviewLikedByUser(
          reviewId: widget.review.id,
          userId: currentUser.id,
        );
        if (!mounted) return;
        setState(() {
          _isLiked = isLiked;
        });
      } catch (_) {
        // Ignorar erros silenciosamente
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com avatar, nome e rating
            InkWell(
              onTap: () => _openUserProfile(context),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.green.shade100,
                    backgroundImage: widget.review.userPhotoUrl != null
                        ? NetworkImage(widget.review.userPhotoUrl!)
                        : null,
                    child: widget.review.userPhotoUrl == null
                        ? Text(
                            (widget.review.userName ?? 'U').substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Nome e data
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.review.userName ?? Translations.getText(context, 'anonymousUser'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.review.getTimeAgo(context),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Estrelas
                  Row(
                    children: widget.review.getStars(),
                  ),
                  // Badge de visita verificada
                  widget.review.verifiedVisit
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  Translations.getText(context, 'verified'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Comentário
            Text(
              widget.review.comment,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            _buildPhotosSection(),
            // Restrições dietéticas (se houver)
            if (widget.review.dietaryRestrictions != null && widget.review.dietaryRestrictions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.review.dietaryRestrictions!.map((restriction) {
                  return Chip(
                    label: Text(
                      restriction,
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: TextStyle(color: Colors.blue.shade700),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFollowButton(context),
                _buildLikeButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    if (widget.review.photos == null || widget.review.photos!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.review.photos!.length,
            itemBuilder: (context, index) {
              final url = widget.review.photos![index];
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: Stack(
                        children: [
                          Center(
                            child: InteractiveViewer(
                              child: Image.network(
                                url,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null || currentUser.id == widget.review.userId) {
      return const SizedBox.shrink();
    }

    final label = _isFollowing
        ? Translations.getText(context, 'followingVerb')
        : Translations.getText(context, 'follow');

    return TextButton.icon(
      onPressed: _isLoadingFollow ? null : () => _toggleFollow(currentUser.id),
      icon: Icon(
        _isFollowing ? Icons.person : Icons.person_add,
        size: 18,
      ),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildLikeButton(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          iconSize: 20,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: _isLoadingLike || currentUser == null
              ? null
              : () => _toggleLike(currentUser.id),
          icon: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.redAccent : Colors.grey.shade500,
          ),
        ),
        Text(
          _likesCount.toString(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFollow(String currentUserId) async {
    try {
      setState(() {
        _isLoadingFollow = true;
      });

      if (_isFollowing) {
        await FirebaseService.unfollowUser(
          currentUserId: currentUserId,
          targetUserId: widget.review.userId,
        );
      } else {
        await FirebaseService.followUser(
          currentUserId: currentUserId,
          targetUserId: widget.review.userId,
        );
      }

      if (!mounted) return;
      setState(() {
        _isFollowing = !_isFollowing;
        _isLoadingFollow = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingFollow = false;
      });
      // Feedback simples em caso de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar seguidores. Tente novamente.'),
        ),
      );
    }
  }

  Future<void> _toggleLike(String currentUserId) async {
    try {
      setState(() {
        _isLoadingLike = true;
      });

      if (_isLiked) {
        await FirebaseService.unlikeReview(
          reviewId: widget.review.id,
          userId: currentUserId,
        );
        if (!mounted) return;
        setState(() {
          _isLiked = false;
          _likesCount = (_likesCount > 0) ? _likesCount - 1 : 0;
          _isLoadingLike = false;
        });
      } else {
        await FirebaseService.likeReview(
          reviewId: widget.review.id,
          userId: currentUserId,
        );
        if (!mounted) return;
        setState(() {
          _isLiked = true;
          _likesCount += 1;
          _isLoadingLike = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLike = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao curtir avaliação. Tente novamente.'),
        ),
      );
    }
  }

  void _openUserProfile(BuildContext context) {
    final userId = widget.review.userId;
    if (userId.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicUserProfileScreen(userId: userId),
      ),
    );
  }
}

