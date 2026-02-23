import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/establishment_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/feature_flags_provider.dart';
import '../models/establishment.dart';
import '../models/user.dart';
import '../widgets/featured_establishments_section.dart';
import '../widgets/dietary_filter_chip.dart';
import '../widgets/mapbox_map_widget.dart';
import '../widgets/welcome_dialog.dart';
import '../widgets/empty_map_state.dart';
import '../utils/translations.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import 'establishment_detail_screen.dart';
// ...existing code...
import 'delivery_screen.dart';
import 'refer_establishment_screen.dart';
import '../widgets/delivery_floating_banner.dart';

class SearchScreen extends StatefulWidget {
  final Widget? header;

  const SearchScreen({super.key, this.header});

  static final GlobalKey<_SearchScreenState> searchKey = GlobalKey<_SearchScreenState>();

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

enum SortOption {
  distance,
  rating,
  name,
  openFirst,
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<MapboxMapWidgetState> _mapKey = GlobalKey<MapboxMapWidgetState>();
  SortOption _sortOption = SortOption.distance;
  bool _showOnlyOpen = false;
  bool _showOnlyNearby = false;
  double _maxDistance = 10.0; // km
  final List<String> _searchHistory = [];
  bool _hasSearchText = false;
  bool _isFeaturedSectionVisible = true;
  bool _isTopUIVisible = true;
  Timer? _featuredVisibilityTimer;
  
  // Delivery banner
  bool _showDeliveryBanner = false;
  DeliveryBannerController? _deliveryBannerController;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchController.addListener(() {
      setState(() {
        _hasSearchText = _searchController.text.isNotEmpty;
      });
    });
    
    // Iniciar controller do banner de delivery
    _deliveryBannerController = DeliveryBannerController(
      onVisibilityChanged: (visible) {
        if (mounted) {
          setState(() {
            _showDeliveryBanner = visible;
          });
        }
      },
    );
    _deliveryBannerController!.start();
    
    // Mostrar dialog de boas-vindas na primeira vez
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        WelcomeDialog.showIfNeeded(
          context,
          onSuggestEstablishment: _openSuggestEstablishment,
        );
      }
    });
  }
  
  void _openSuggestEstablishment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ReferEstablishmentScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _featuredVisibilityTimer?.cancel();
    _deliveryBannerController?.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    // TODO: Carregar histórico de SharedPreferences
  }

  void _saveToHistory(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _searchHistory.remove(query.trim());
      _searchHistory.insert(0, query.trim());
      if (_searchHistory.length > 5) {
        _searchHistory.removeLast();
      }
    });
    // TODO: Salvar em SharedPreferences
  }

  void _onMapInteraction() {
    if (_isFeaturedSectionVisible) {
      setState(() {
        _isFeaturedSectionVisible = false;
        _isTopUIVisible = false;
      });
    } else if (_isTopUIVisible) {
      setState(() {
        _isTopUIVisible = false;
      });
    }
    
    // Cancelar timer anterior se existir
    _featuredVisibilityTimer?.cancel();
    
    // Criar novo timer para reexibir após 2.5s de inatividade
    _featuredVisibilityTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && !_isFeaturedSectionVisible) {
        setState(() {
          _isFeaturedSectionVisible = true;
        });
      }
    });
  }

  void _onMapInteractionEnd() {
    if (!_isTopUIVisible) {
      setState(() {
        _isTopUIVisible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EstablishmentProvider>(
      builder: (context, establishmentProvider, _) {
        // Removido lógica de usuário business/premium e cores relacionadas
        Color bannerColor = AppTheme.primaryGreen.withOpacity(0.08);

        // Lista de estabelecimentos patrocinados removida (não há mais planos)
        final bool hasFeaturedEstablishments = false;

        return Container(
          color: AppTheme.background,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Mapa no fundo (ocupa tudo)
              Positioned.fill(
                child: RepaintBoundary(
                  child: _buildMap(establishmentProvider),
                ),
              ),

              // 2. Conteúdo sobreposto (Header, Filtros, Destaques)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Seção com Blur (Header + Filtros)
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      offset: _isTopUIVisible ? Offset.zero : const Offset(0, -1),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _isTopUIVisible ? 1.0 : 0.0,
                        child: Stack(
                          children: [
                            // Camada de Gradiente (Substituindo Blur)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(0.95),
                                      Colors.white.withOpacity(0.8),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // Camada de Conteúdo (Sempre nítida)
                            StreamBuilder<String?>(
                              stream: FirebaseService.seasonalThemeStream(),
                              builder: (context, snapshot) {
                                final seasonalThemeKey = snapshot.data;
                                return Container(
                                  padding: const EdgeInsets.only(bottom: 32),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.header != null) widget.header!,
                                      const SizedBox(height: 12),
                                      // Filtros Dietéticos
                                      _buildFilters(establishmentProvider, seasonalTheme: seasonalThemeKey),
                                      const SizedBox(height: 12),
                                      // Filtros Rápidos
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              _buildQuickFiltersRow(establishmentProvider),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Seção Em Destaque (logo abaixo dos filtros)
                    // Seção de destaques removida (não há mais planos/patrocínio)
                  ],
                ),
              ),
              
              // 5. Banner flutuante de Delivery (rodapé)
              Consumer<FeatureFlagsProvider>(
                builder: (context, featureFlags, _) {
                  if (!featureFlags.deliveryEnabled || !_showDeliveryBanner) {
                    return const SizedBox.shrink();
                  }
                  return Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: DeliveryFloatingBanner(
                      onTap: () {
                        _deliveryBannerController?.dismiss();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DeliveryScreen(),
                          ),
                        );
                      },
                      onDismiss: () {
                        _deliveryBannerController?.dismiss();
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper para agrupar os filtros rápidos numa linha só
  Widget _buildQuickFiltersRow(EstablishmentProvider provider) {
     return Row(
       children: [
         _buildQuickFilterChip(
            icon: Icons.access_time,
            label: Translations.getText(context, 'openNow'),
            isSelected: _showOnlyOpen,
            onTap: () {
              setState(() => _showOnlyOpen = !_showOnlyOpen);
              _applyFilters(provider);
            },
         ),
         const SizedBox(width: 8),
         _buildQuickFilterChip(
            icon: Icons.near_me,
            label: Translations.getText(context, 'nearby'),
            isSelected: _showOnlyNearby,
            onTap: () {
              setState(() => _showOnlyNearby = !_showOnlyNearby);
              _applyFilters(provider);
            },
         ),
       ],
     );
  }

  String _getDietaryIcon(DietaryFilter filter) {
    switch (filter) {
      case DietaryFilter.celiac:
        return 'chipIcons/celiaco.png';
      case DietaryFilter.lactoseFree:
        return 'chipIcons/lactose.png';
      case DietaryFilter.aplv:
        return 'chipIcons/APLV.png';
      case DietaryFilter.eggFree:
        return 'chipIcons/sem ovo.png';
      case DietaryFilter.nutFree:
        return 'chipIcons/amendoim.png';
      case DietaryFilter.oilseedFree:
        return 'chipIcons/oilseed free.png';
      case DietaryFilter.soyFree:
        return 'chipIcons/soja.png';
      case DietaryFilter.sugarFree:
        return 'chipIcons/acucar.png';
      case DietaryFilter.diabetic:
        return 'chipIcons/diabetic.png';
      case DietaryFilter.vegan:
        return 'chipIcons/vegan.png';
      case DietaryFilter.vegetarian:
        return 'chipIcons/vegeteriano.png';
      case DietaryFilter.halal:
        return 'chipIcons/halal.png';
    }
  }

  Widget _buildFilters(EstablishmentProvider provider, {String? seasonalTheme}) {
    final bool isChristmas = seasonalTheme == 'christmas';
    // Cores ainda mais leves, quase brancas
    final Color unselectedBg = isChristmas ? const Color(0xFFFFF9F9) : const Color(0xFFF9FFF9);
    
    return SizedBox(
      height: 125, // Aumentado de 115 para 125 para evitar overflow da sombra/conteúdo
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: DietaryFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final filter = DietaryFilter.values[index];
          final isSelected = provider.selectedFilters.contains(filter);
          
          return GestureDetector(
            onTap: () {
              provider.toggleFilter(filter);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 95,
              decoration: BoxDecoration(
                gradient: isSelected 
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryGreen,
                        AppTheme.primaryGreen.withBlue(100),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        unselectedBg,
                        unselectedBg.withOpacity(0.5),
                      ],
                    ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
                border: Border.all(
                  color: isSelected ? Colors.white.withOpacity(0.5) : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start, // Fixa no topo
                children: [
                  const SizedBox(height: 10), // Espaçamento fixo no topo
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      _getDietaryIcon(filter),
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32, // Altura fixa para o texto para estabilizar o layout
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        filter.getLabel(context),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(BuildContext context) {
    switch (_sortOption) {
      case SortOption.distance:
        return Translations.getText(context, 'sortByDistance');
      case SortOption.rating:
        return Translations.getText(context, 'sortByRating');
      case SortOption.name:
        return Translations.getText(context, 'sortByName');
      case SortOption.openFirst:
        return Translations.getText(context, 'sortByOpenFirst');
    }
  }

  void _applyFilters(EstablishmentProvider provider) {
    setState(() {});
  }

  List<Establishment> _getFilteredAndSortedEstablishments(EstablishmentProvider provider) {
    // Removeu toda lógica de premium/business
    List<Establishment> establishments = provider.filteredEstablishments;
    if (_showOnlyOpen) {
      establishments = establishments.where((e) => e.isOpen).toList();
    }
    if (_showOnlyNearby && provider.userPosition != null) {
      establishments = establishments.where((e) => e.distance <= _maxDistance).toList();
    }
    switch (_sortOption) {
      case SortOption.distance:
        establishments.sort((a, b) => a.distance.compareTo(b.distance));
        break;
      case SortOption.rating:
        establishments.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.name:
        establishments.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.openFirst:
        establishments.sort((a, b) {
          if (a.isOpen && !b.isOpen) return -1;
          if (!a.isOpen && b.isOpen) return 1;
          return a.distance.compareTo(b.distance);
        });
        break;
    }
    return establishments;
  }

  // Widget de banner premium removido

  void openAdvancedFiltersFromHeader() {
    final provider = Provider.of<EstablishmentProvider>(context, listen: false);
    _showAdvancedFilters(context, provider);
  }

  void _showAdvancedFilters(BuildContext context, EstablishmentProvider provider) {


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AdvancedFiltersSheet(
        maxDistance: _maxDistance,
        onDistanceChanged: (value) {
          setState(() {
            _maxDistance = value;
          });
          _applyFilters(provider);
        },
        provider: provider,
      ),
    );
  }

  Widget _buildMap(EstablishmentProvider provider) {
    return Consumer<EstablishmentProvider>(
      builder: (context, provider, _) {
        final establishments = _getFilteredAndSortedEstablishments(provider);
        return MapboxMapWidget(
          key: _mapKey,
          mapStateKey: _mapKey,
          establishments: establishments,
          onMapInteraction: _onMapInteraction,
          onMapInteractionEnd: _onMapInteractionEnd,
          onSuggestEstablishment: _openSuggestEstablishment,
          onMarkerTap: (establishment) {
            // Quando clica no marcador, mostrar modal com animação de baixo para cima
            FirebaseService.registerEstablishmentClick(
              establishment.id,
              isSponsored: establishment.isBoosted,
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
        );
      },
    );
  }
}

// Widget para Filtros avançados
class _AdvancedFiltersSheet extends StatefulWidget {
  final double maxDistance;
  final ValueChanged<double> onDistanceChanged;
  final EstablishmentProvider provider;

  const _AdvancedFiltersSheet({
    required this.maxDistance,
    required this.onDistanceChanged,
    required this.provider,
  });

  @override
  State<_AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<_AdvancedFiltersSheet> {
  late double _maxDistance;
  double? _minRating;
  Set<DietaryFilter> _selectedDietaryFilters = {};
  Set<String> _selectedCategories = {};
  Set<DifficultyLevel> _selectedDifficultyLevels = {};

  @override
  void initState() {
    super.initState();
    _maxDistance = widget.maxDistance;
    _selectedDietaryFilters = Set.from(widget.provider.selectedFilters);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      Translations.getText(context, 'advancedFilters'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Distância máxima
                    _buildDistanceFilter(),
                    const SizedBox(height: 24),
                    // Avaliação mínima
                    _buildRatingFilter(),
                    const SizedBox(height: 24),
                    // Tipo de restrição alimentar
                    _buildDietaryFilters(),
                    const SizedBox(height: 24),
                    // Tipo de estabelecimento
                    _buildCategoryFilters(),
                    const SizedBox(height: 24),
                    // Nível de selo
                    _buildDifficultyLevelFilters(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _maxDistance = 50.0;
                        _minRating = null;
                        _selectedDietaryFilters.clear();
                        _selectedCategories.clear();
                        _selectedDifficultyLevels.clear();
                      });
                    },
                    child: Text(Translations.getText(context, 'clearFilters')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.provider.setSelectedFilters(_selectedDietaryFilters);
                      widget.provider.setAdvancedFilters(
                        minRating: _minRating,
                        categories: _selectedCategories,
                        difficultyLevels: _selectedDifficultyLevels,
                        maxDistance: _maxDistance,
                      );
                      widget.onDistanceChanged(_maxDistance);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text(Translations.getText(context, 'apply')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${Translations.getText(context, 'maxDistance')}: ${_maxDistance.toStringAsFixed(1)} km',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _maxDistance,
          min: 1.0,
          max: 50.0,
          divisions: 49,
          label: '${_maxDistance.toStringAsFixed(1)} km',
          onChanged: (value) {
            setState(() => _maxDistance = value);
          },
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${Translations.getText(context, 'minRating')}: '
          '${_minRating?.toStringAsFixed(1) ?? Translations.getText(context, 'any')}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _minRating ?? 0.0,
          min: 0.0,
          max: 5.0,
          divisions: 10,
          label: _minRating?.toStringAsFixed(1) ?? Translations.getText(context, 'any'),
          onChanged: (value) {
            setState(() => _minRating = value > 0 ? value : null);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _minRating = null),
              child: Text(Translations.getText(context, 'any')),
            ),
            TextButton(
              onPressed: () => setState(() => _minRating = 4.0),
              child: Text(Translations.getText(context, 'rating4Plus')),
            ),
            TextButton(
              onPressed: () => setState(() => _minRating = 4.5),
              child: Text(Translations.getText(context, 'rating45Plus')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDietaryFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Translations.getText(context, 'dietaryRestrictions'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DietaryFilter.values.map((filter) {
            final isSelected = _selectedDietaryFilters.contains(filter);
            return FilterChip(
              label: Text(filter.getLabel(context)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDietaryFilters.add(filter);
                  } else {
                    _selectedDietaryFilters.remove(filter);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [
      'Restaurante',
      'Padaria',
      'Confeitaria',
      'Hotel',
      'Pousada',
      'Lanchonete',
      'Café',
      'Mercado',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Translations.getText(context, 'establishmentType'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDifficultyLevelFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Translations.getText(context, 'sealLevel'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DifficultyLevel.values.map((level) {
            final isSelected = _selectedDifficultyLevels.contains(level);
            return FilterChip(
              label: Text(level.getLabel(context)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDifficultyLevels.add(level);
                  } else {
                    _selectedDifficultyLevels.remove(level);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

