import 'package:flutter/material.dart';

import '../models/establishment.dart';
import '../theme/app_theme.dart';

/// Carrossel horizontal de estabelecimentos destacados para Delivery
class DeliveryFeaturedCarousel extends StatelessWidget {
  final List<Establishment> establishments;
  final Function(Establishment) onTap;

  const DeliveryFeaturedCarousel({
    super.key,
    required this.establishments,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (establishments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Icon(Icons.local_fire_department, 
                color: Colors.orange.shade600, 
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Destaques',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: establishments.length,
            itemBuilder: (context, index) {
              final establishment = establishments[index];
              return _FeaturedCard(
                establishment: establishment,
                onTap: () => onTap(establishment),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Establishment establishment;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.establishment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem com overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      establishment.photoUrls.isNotEmpty 
                          ? establishment.photoUrls.first 
                          : establishment.avatarUrl,
                      width: 160,
                      height: 100,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 160,
                          height: 100,
                          color: Colors.grey.shade200,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 160,
                        height: 100,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.restaurant, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Badge patrocinado
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rocket_launch, size: 10, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'Destaque',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Taxa de entrega
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: establishment.isFreeDelivery 
                            ? AppTheme.primaryGreen 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        establishment.deliveryFeeFormatted,
                        style: TextStyle(
                          color: establishment.isFreeDelivery 
                              ? Colors.white 
                              : Colors.grey.shade800,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Nome
              Text(
                establishment.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Rating e tempo
              Row(
                children: [
                  if (establishment.rating != null) ...[
                    Icon(Icons.star, size: 12, color: Colors.amber.shade600),
                    const SizedBox(width: 2),
                    Text(
                      establishment.rating!.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                    ),
                  ],
                  if (establishment.deliveryTimeFormatted.isNotEmpty)
                    Text(
                      establishment.deliveryTimeFormatted,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
