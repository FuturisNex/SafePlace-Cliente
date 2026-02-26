import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/establishment.dart';
import '../services/favorites_service.dart';
import '../services/boost_service.dart';
import '../providers/auth_provider.dart';
import '../utils/translations.dart';
import '../theme/app_theme.dart';

/// Card de estabelecimento com lógica exclusiva para favoritos, rotas, badges de certificação e filtros dietéticos.
/// Este componente faz parte da experiência única do app, focada em segurança alimentar e preferências do usuário.
class EstablishmentCard extends StatefulWidget {
  final Establishment establishment;
  final VoidCallback? onSave;
  final VoidCallback? onTap;

  const EstablishmentCard({
    super.key,
    required this.establishment,
    this.onSave,
    this.onTap,
  });

  @override
  State<EstablishmentCard> createState() => _EstablishmentCardState();
}

/// Estado do card de estabelecimento, com lógica assíncrona para favoritos e navegação.
class _EstablishmentCardState extends State<EstablishmentCard> with SingleTickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;
  bool _isLoading = false;
  bool _showFavAnim = false;
  late final AnimationController _favAnimController;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
    _favAnimController = AnimationController(vsync: this);
  }
  @override
  void dispose() {
    _favAnimController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarregar status de favorito quando o usuário mudar (login/logout)
    _checkFavorite();
  }

  /// Checa se o estabelecimento está nos favoritos do usuário logado.
  /// Lógica exclusiva: favoritos são salvos por usuário autenticado, reforçando personalização.
  Future<void> _checkFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id ?? '';
    if (userId.isEmpty) {
      if (mounted) {
        setState(() {
          _isFavorite = false;
        });
      }
      return;
    }
    final isFav = await _favoritesService.isFavorite(widget.establishment.id, userId);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  /// Alterna favorito, com feedback visual e mensagem customizada.
  /// Experiência fluida mesmo em conexões lentas.
  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id ?? '';
    if (userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Translations.getText(context, 'pleaseLogin')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFavorite) {
        await _favoritesService.removeFavorite(widget.establishment.id, userId);
      } else {
        await _favoritesService.saveFavorite(widget.establishment, userId);
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isLoading = false;
        });

        // Animação de destaque ao favoritar
        if (!_isFavorite) {
          setState(() => _showFavAnim = false);
        } else {
          setState(() => _showFavAnim = true);
          _favAnimController.forward(from: 0);
          await Future.delayed(const Duration(milliseconds: 1200));
          if (mounted) setState(() => _showFavAnim = false);
        }

        if (widget.onSave != null) {
          widget.onSave!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite
                  ? '${widget.establishment.name} adicionado aos favoritos!'
                  : '${widget.establishment.name} removido dos favoritos!',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${Translations.getText(context, 'errorSaving')} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Gera rota até o estabelecimento, com cálculo de tempo de caminhada personalizado.
  /// Tenta abrir no Google Maps, fallback para outros modos. UX pensada para acessibilidade.
  Future<void> _generateRoute() async {
    final distanceKm = widget.establishment.distance;
    int walkingMinutes = (distanceKm / 4.0 * 60).round();
    if (walkingMinutes < 1) walkingMinutes = 1;
    final shouldRoute = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.establishment.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${CategoryTranslator.translate(context, widget.establishment.category)} - ${distanceKm.toStringAsFixed(1)} km'),
            if (widget.establishment.dietaryOptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: widget.establishment.dietaryOptions.map((filter) {
                  return Chip(
                            label: Text(filter.getLabel(context)),
                    backgroundColor: Colors.green.shade50,
                    labelStyle: const TextStyle(fontSize: 10),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${Translations.getText(context, 'estimatedWalkingTime')} ~$walkingMinutes min',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(Translations.getText(context, 'doYouWantToGo')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Translations.getText(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(Translations.getText(context, 'generateRoute')),
          ),
        ],
      ),
    );

    if (shouldRoute == true && mounted) {
      try {
        final lat = widget.establishment.latitude;
        final lng = widget.establishment.longitude;
        final name = Uri.encodeComponent(widget.establishment.name);
        
        // Tentar abrir diretamente com google.navigation primeiro
        try {
          final uri = Uri.parse('google.navigation:q=$lat,$lng');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          // Se falhar, tentar com maps URL
          try {
            final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            // Última tentativa: geo URI
            try {
              final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($name)');
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${Translations.getText(context, 'errorOpeningNavigation')} $e'),
                    duration: const Duration(seconds: 3),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${Translations.getText(context, 'errorGeneratingRoute')} $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  /// Build do card, com destaques para badges de certificação, filtros dietéticos e distância.
  /// Elementos visuais e lógicos reforçam o conceito original do app.
  Widget build(BuildContext context) {
    final establishment = widget.establishment;
    final now = DateTime.now();
    final difficultyLevel = establishment.difficultyLevel;
    final Color difficultyColor = difficultyLevel.color;
    final String difficultyLabel = difficultyLevel.getLabel(context);
    final bool isBoostActive = establishment.isBoosted &&
      (establishment.boostExpiresAt == null || establishment.boostExpiresAt!.isAfter(now));
    // Considera "novo" se cadastrado há menos de 7 dias
    // Considera "novo" se teve inspeção recente (lastInspectionDate) ou boost recente
    final bool isNew = establishment.lastInspectionDate != null &&
      now.difference(establishment.lastInspectionDate!).inDays < 7;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Registrar clique se for boosted
            if (establishment.isBoosted) {
              BoostService.registerClick(establishment.id);
            }
            // Executar callback ou gerar rota
            if (widget.onTap != null) {
              widget.onTap!();
            } else {
              _generateRoute();
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Imagem de Capa e Badges
              // Imagem de capa, badges e botões de ação exclusivos do app
              Stack(
                children: [
                  // Imagem
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: establishment.avatarUrl.isNotEmpty
                          ? Image.network(
                              establishment.avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade100,
                                child: Icon(Icons.store, size: 48, color: Colors.grey.shade300),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green.shade50, Colors.white],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.store_mall_directory_outlined, 
                                  size: 64, 
                                  color: AppTheme.primaryGreen.withOpacity(0.3)
                                ),
                              ),
                            ),
                    ),
                  ),

                  // Badge de Patrocinado (quando boosted)
                  if (isBoostActive)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.rocket_launch,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Patrocinado',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Badge de Novo (estabelecimento recém-cadastrado)
                  if (isNew)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fiber_new,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Novo',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 10, color: establishment.difficultyLevel.color),
                          const SizedBox(width: 6),
                          Text(
                            establishment.difficultyLevel.getLabel(context),
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Botão Favorito (Top Right)
                  // Lógica exclusiva: favoritos por usuário autenticado, com feedback instantâneo.
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _toggleFavorite,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Icon(
                                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: _isFavorite ? Colors.red : Colors.grey.shade400,
                                      size: 20,
                                    ),
                              if (_showFavAnim)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Center(
                                      child: Lottie.asset(
                                        'assets/animations/like_fav.json',
                                        controller: _favAnimController,
                                        onLoaded: (composition) {
                                          _favAnimController.duration = composition.duration;
                                        },
                                        width: 60,
                                        height: 60,
                                        repeat: false,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Informações do estabelecimento
              // Nome, categoria, certificação técnica e filtros dietéticos são exibidos de forma personalizada.
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome e Categoria
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nome do estabelecimento e badge de certificação técnica (exclusivo do app)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: Text(
                                      establishment.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                        height: 1.2,
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
                              // Categoria do estabelecimento, traduzida e adaptada para o público do app
                              Text(
                                CategoryTranslator.translate(context, establishment.category),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Badge de dificuldade, reforçando o diferencial do app em informar o usuário
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: difficultyColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: difficultyColor.withOpacity(0.9),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: difficultyColor.withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.verified,
                                          size: 14,
                                          color: difficultyColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          difficultyLabel,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: difficultyColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Distância Badge
                        // Badge de distância, reforçando a experiência personalizada do app
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: AppTheme.primaryGreen),
                              const SizedBox(width: 4),
                              Text(
                                '${establishment.distance.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Filtros Dietéticos (Chips)
                    // Chips de filtros dietéticos, diferencial do app para usuários com restrições alimentares
                    if (establishment.dietaryOptions.isNotEmpty)
                      SizedBox(
                        height: 28,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: establishment.dietaryOptions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final filter = establishment.dietaryOptions[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                filter.getLabel(context),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      // Mensagem customizada caso não haja filtros, reforçando a curadoria do app
                      Text(
                        Translations.getText(context, 'noDishesRegistered'),
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade400,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

