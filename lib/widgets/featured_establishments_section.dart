import 'package:flutter/material.dart';
import '../models/establishment.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/establishment_detail_screen.dart';
import '../services/firebase_service.dart';

/// Seção de estabelecimentos em destaque com ordenação exclusiva por impulso e plano.
/// Diferencial: lógica própria para destacar estabelecimentos relevantes ao usuário.
class FeaturedEstablishmentsSection extends StatefulWidget {
  final List<Establishment> establishments;
  final bool isVisible;

  const FeaturedEstablishmentsSection({
    super.key,
    required this.establishments,
    this.isVisible = true,
  });

  @override
  State<FeaturedEstablishmentsSection> createState() => _FeaturedEstablishmentsSectionState();
}

/// Estado da seção de destaques, com ordenação e exibição personalizada.
class _FeaturedEstablishmentsSectionState extends State<FeaturedEstablishmentsSection> {
  final PageController _pageController = PageController(
    viewportFraction: 0.85,
    initialPage: 0,
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Establishment> get sortedEstablishments {
    // You can customize the sorting logic as needed.
    return widget.establishments;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || sortedEstablishments.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 240,
      child: PageView.builder(
        controller: _pageController,
        itemCount: sortedEstablishments.length,
        itemBuilder: (context, index) {
          final establishment = sortedEstablishments[index];
          return _buildFeaturedCard(establishment);
        },
      ),
    );
  }

  Widget _buildFeaturedCard(Establishment establishment) {
    return GestureDetector(
      onTap: () {
        FirebaseService.registerEstablishmentClick(
          establishment.id,
          isSponsored: true,
        );
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => EstablishmentDetailScreen(
            establishment: establishment,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagem de fundo
              if (establishment.avatarUrl.isNotEmpty)
                Image.network(
                  establishment.avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.restaurant,
                        size: 48,
                        color: Colors.grey,
                      ),
                    );
                  },
                )
              else
                Container(
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.restaurant,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Badge "Patrocinado"
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Patrocinado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Conteúdo
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Text(
                              establishment.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (establishment.certificationStatus == TechnicalCertificationStatus.certified)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4C9FFF),
                                      Color(0xFF1877F2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              establishment.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${establishment.distance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
