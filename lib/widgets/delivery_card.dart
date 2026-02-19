import 'package:flutter/material.dart';

import '../models/establishment.dart';
import '../theme/app_theme.dart';

/// Card de estabelecimento para a tela de Delivery (estilo iFood)
class DeliveryCard extends StatelessWidget {
  final Establishment establishment;
  final VoidCallback onTap;

  const DeliveryCard({
    super.key,
    required this.establishment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem do estabelecimento
                _buildImage(),
                const SizedBox(width: 12),
                // Informações
                Expanded(
                  child: _buildInfo(context),
                ),
                // Favorito
                IconButton(
                  onPressed: () {
                    // TODO: Implementar favorito
                  },
                  icon: Icon(
                    Icons.favorite_border,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            establishment.avatarUrl,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 72,
                height: 72,
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: 72,
              height: 72,
              color: Colors.grey.shade200,
              child: Icon(Icons.restaurant, color: Colors.grey.shade400),
            ),
          ),
        ),
        // Badge de patrocinado
        if (establishment.isBoosted)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Patrocinado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nome e verificado
        Row(
          children: [
            Expanded(
              child: Text(
                establishment.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // if (establishment.planType != PlanType.basic)
            //   Padding(
            //     padding: const EdgeInsets.only(left: 4),
            //     child: Icon(
            //       Icons.verified,
            //       size: 16,
            //       color: establishment.planType == PlanType.premium
            //           ? Colors.blue
            //           : Colors.green,
            //     ),
            //   ),
          ],
        ),
        const SizedBox(height: 4),

        // Rating, tempo e taxa
        Row(
          children: [
            // Rating
            if (establishment.rating != null) ...[
              Icon(Icons.star, size: 14, color: Colors.amber.shade600),
              const SizedBox(width: 2),
              Text(
                establishment.rating!.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                ' •',
                style: TextStyle(color: Colors.grey.shade400),
              ),
              const SizedBox(width: 4),
            ],

            // Tempo de entrega
            if (establishment.deliveryTimeFormatted.isNotEmpty) ...[
              Icon(Icons.schedule, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 2),
              Text(
                establishment.deliveryTimeFormatted,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                ' •',
                style: TextStyle(color: Colors.grey.shade400),
              ),
              const SizedBox(width: 4),
            ],

            // Taxa de entrega
            Text(
              establishment.deliveryFeeFormatted,
              style: TextStyle(
                fontSize: 13,
                color: establishment.isFreeDelivery
                    ? AppTheme.primaryGreen
                    : Colors.grey.shade600,
                fontWeight: establishment.isFreeDelivery
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Tags de restrição alimentar
        if (establishment.dietaryOptions.isNotEmpty)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: establishment.dietaryOptions.take(3).map((option) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getDietaryLabel(option),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),

        // Cupons/promoções (placeholder)
        if (establishment.isBoosted) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.local_offer, size: 12, color: Colors.red.shade400),
              const SizedBox(width: 4),
              Text(
                'Cupons disponíveis',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _getDietaryLabel(DietaryFilter filter) {
    switch (filter) {
      case DietaryFilter.celiac:
        return 'Celíaco';
      case DietaryFilter.lactoseFree:
        return 'Sem Lactose';
      case DietaryFilter.aplv:
        return 'APLV';
      case DietaryFilter.eggFree:
        return 'Sem Ovo';
      case DietaryFilter.nutFree:
        return 'Sem Amendoim';
      case DietaryFilter.oilseedFree:
        return 'Sem Oleaginosas';
      case DietaryFilter.soyFree:
        return 'Sem Soja';
      case DietaryFilter.sugarFree:
        return 'Sem Açúcar';
      case DietaryFilter.diabetic:
        return 'Diabético';
      case DietaryFilter.vegan:
        return 'Vegano';
      case DietaryFilter.vegetarian:
        return 'Vegetariano';
      case DietaryFilter.halal:
        return 'Halal';
    }
  }
}
