import 'package:flutter/material.dart';
import '../models/establishment.dart';
import '../widgets/establishment_profile.dart';
import '../utils/translations.dart';

/// Tela que mostra os detalhes completos do estabelecimento
/// Acessada ao clicar em um marcador no mapa (estilo Uber/iFood)
/// Usa DraggableScrollableSheet para animação de baixo para cima e arrastar para minimizar
class EstablishmentDetailScreen extends StatelessWidget {
  final Establishment establishment;

  const EstablishmentDetailScreen({
    super.key,
    required this.establishment,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9, // Ocupa 90% da tela inicialmente
      minChildSize: 0.3, // Pode ser minimizado até 30%
      maxChildSize: 0.95, // Máximo de 95% da tela
      builder: (context, scrollController) {
        final level = establishment.difficultyLevel;
        final Color baseColor = level.color;
        final Color borderColor = baseColor.withOpacity(0.9);
        final Color glowColor = baseColor.withOpacity(0.5);

        return RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: borderColor,
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 8, // Reduzido de 20 para 8 para performance
                  spreadRadius: 0, // Removido spread para performance
                  offset: const Offset(0, -2),
                ),
              ],
            ),
          child: Column(
            children: [
              // Barrinha para arrastar (handle)
              _buildDragHandle(),
              // Header com botão de fechar
              _buildHeader(context),
              // Conteúdo do estabelecimento (scrollável)
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: EstablishmentProfile(
                    establishment: establishment,
                    onClose: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  /// Barrinha no topo para indicar que pode ser arrastada
  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Header com botão de voltar e título
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).pop();
            },
            tooltip: Translations.getText(context, 'back'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    establishment.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
          ),
        ],
      ),
    );
  }
}

