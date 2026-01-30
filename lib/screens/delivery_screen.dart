import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/establishment.dart';
import '../providers/establishment_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/delivery_card.dart';
import '../widgets/delivery_featured_carousel.dart';
import 'establishment_detail_screen.dart';
import 'establishment_menu_screen.dart';

/// Enums para ordenação
enum DeliverySortOption {
  relevance,
  rating,
  deliveryTime,
  deliveryFee,
}

/// Tela de Delivery estilo iFood
class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  // Filtros
  String? _selectedCategory;
  final Set<DietaryFilter> _selectedDietaryFilters = {};
  bool _freeDeliveryOnly = false;
  DeliverySortOption _sortOption = DeliverySortOption.relevance;

  // Categorias disponíveis
  final List<Map<String, dynamic>> _categories = [
    {'id': null, 'name': 'Todos', 'icon': Icons.apps},
    {'id': 'restaurante', 'name': 'Restaurantes', 'icon': Icons.restaurant},
    {'id': 'pizzaria', 'name': 'Pizzarias', 'icon': Icons.local_pizza},
    {'id': 'hamburgueria', 'name': 'Hambúrgueres', 'icon': Icons.lunch_dining},
    {'id': 'japonesa', 'name': 'Japonesa', 'icon': Icons.set_meal},
    {'id': 'doceria', 'name': 'Doces', 'icon': Icons.cake},
    {'id': 'saudavel', 'name': 'Saudável', 'icon': Icons.eco},
    {'id': 'bebidas', 'name': 'Bebidas', 'icon': Icons.local_bar},
  ];

  @override
  Widget build(BuildContext context) {
    final establishmentProvider = Provider.of<EstablishmentProvider>(context);
    
    // Filtrar apenas estabelecimentos com delivery
    final deliveryEstablishments = establishmentProvider.establishments
        .where((e) => e.hasDelivery)
        .toList();

    // Aplicar filtros
    var filtered = _applyFilters(deliveryEstablishments);

    // Aplicar ordenação
    filtered = _applySorting(filtered);

    // Destacados (boosted + delivery)
    final featured = deliveryEstablishments
        .where((e) => e.isBoosted && e.boostExpiresAt != null && e.boostExpiresAt!.isAfter(DateTime.now()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),

            // Categorias horizontais
            SliverToBoxAdapter(
              child: _buildCategoryChips(),
            ),

            // Filtros rápidos
            SliverToBoxAdapter(
              child: _buildQuickFilters(),
            ),

            // Carrossel de destacados
            if (featured.isNotEmpty)
              SliverToBoxAdapter(
                child: DeliveryFeaturedCarousel(
                  establishments: featured,
                  onTap: _openEstablishment,
                ),
              ),

            // Seção "Meus Cupons" (placeholder)
            SliverToBoxAdapter(
              child: _buildCouponsSection(),
            ),

            // Título da lista
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lojas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: _showSortOptions,
                      icon: const Icon(Icons.sort, size: 18),
                      label: Text(_getSortLabel()),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lista de estabelecimentos
            if (filtered.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final establishment = filtered[index];
                      return DeliveryCard(
                        establishment: establishment,
                        onTap: () => _openEstablishment(establishment),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),

            // Espaço no final
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delivery_dining,
                  color: AppTheme.primaryGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Peça sem sair de casa',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Botão de busca
              IconButton(
                onPressed: () {
                  // TODO: Implementar busca
                },
                icon: const Icon(Icons.search),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['id'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['id'];
                });
              },
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.grey.shade200),
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category['name'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : Colors.grey.shade700,
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

  Widget _buildQuickFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Entrega grátis
          _buildFilterChip(
            label: 'Entrega grátis',
            icon: Icons.local_shipping_outlined,
            isSelected: _freeDeliveryOnly,
            onTap: () {
              setState(() {
                _freeDeliveryOnly = !_freeDeliveryOnly;
              });
            },
          ),
          const SizedBox(width: 8),

          // Filtros de restrição alimentar
          _buildFilterChip(
            label: 'Celíaco',
            icon: Icons.no_food,
            isSelected: _selectedDietaryFilters.contains(DietaryFilter.celiac),
            onTap: () => _toggleDietaryFilter(DietaryFilter.celiac),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Sem Lactose',
            icon: Icons.water_drop_outlined,
            isSelected: _selectedDietaryFilters.contains(DietaryFilter.lactoseFree),
            onTap: () => _toggleDietaryFilter(DietaryFilter.lactoseFree),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Vegano',
            icon: Icons.eco,
            isSelected: _selectedDietaryFilters.contains(DietaryFilter.vegan),
            onTap: () => _toggleDietaryFilter(DietaryFilter.vegan),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Vegetariano',
            icon: Icons.grass,
            isSelected: _selectedDietaryFilters.contains(DietaryFilter.vegetarian),
            onTap: () => _toggleDietaryFilter(DietaryFilter.vegetarian),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.deepOrange.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_offer,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meus Cupons',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Você tem 0 cupons disponíveis',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum estabelecimento encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente ajustar os filtros ou volte mais tarde',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Limpar filtros'),
            ),
          ],
        ),
      ),
    );
  }

  List<Establishment> _applyFilters(List<Establishment> establishments) {
    var result = establishments;

    // Filtro de categoria
    if (_selectedCategory != null) {
      result = result.where((e) => 
        e.category.toLowerCase().contains(_selectedCategory!.toLowerCase())
      ).toList();
    }

    // Filtro de entrega grátis
    if (_freeDeliveryOnly) {
      result = result.where((e) => e.isFreeDelivery).toList();
    }

    // Filtros de restrição alimentar
    if (_selectedDietaryFilters.isNotEmpty) {
      result = result.where((e) {
        return _selectedDietaryFilters.every((filter) => 
          e.dietaryOptions.contains(filter)
        );
      }).toList();
    }

    return result;
  }

  List<Establishment> _applySorting(List<Establishment> establishments) {
    final sorted = List<Establishment>.from(establishments);

    switch (_sortOption) {
      case DeliverySortOption.relevance:
        // Boosted primeiro, depois por rating
        sorted.sort((a, b) {
          if (a.isBoosted && !b.isBoosted) return -1;
          if (!a.isBoosted && b.isBoosted) return 1;
          return (b.rating ?? 0).compareTo(a.rating ?? 0);
        });
        break;
      case DeliverySortOption.rating:
        sorted.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case DeliverySortOption.deliveryTime:
        sorted.sort((a, b) => 
          (a.deliveryTimeMin ?? 999).compareTo(b.deliveryTimeMin ?? 999)
        );
        break;
      case DeliverySortOption.deliveryFee:
        sorted.sort((a, b) => 
          (a.deliveryFee ?? 0).compareTo(b.deliveryFee ?? 0)
        );
        break;
    }

    return sorted;
  }

  void _toggleDietaryFilter(DietaryFilter filter) {
    setState(() {
      if (_selectedDietaryFilters.contains(filter)) {
        _selectedDietaryFilters.remove(filter);
      } else {
        _selectedDietaryFilters.add(filter);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedDietaryFilters.clear();
      _freeDeliveryOnly = false;
      _sortOption = DeliverySortOption.relevance;
    });
  }

  String _getSortLabel() {
    switch (_sortOption) {
      case DeliverySortOption.relevance:
        return 'Ordenar';
      case DeliverySortOption.rating:
        return 'Avaliação';
      case DeliverySortOption.deliveryTime:
        return 'Tempo';
      case DeliverySortOption.deliveryFee:
        return 'Taxa';
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Ordenar por',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildSortOption(
                'Relevância',
                DeliverySortOption.relevance,
                Icons.auto_awesome,
              ),
              _buildSortOption(
                'Melhor avaliação',
                DeliverySortOption.rating,
                Icons.star,
              ),
              _buildSortOption(
                'Tempo de entrega',
                DeliverySortOption.deliveryTime,
                Icons.schedule,
              ),
              _buildSortOption(
                'Taxa de entrega',
                DeliverySortOption.deliveryFee,
                Icons.local_shipping,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, DeliverySortOption option, IconData icon) {
    final isSelected = _sortOption == option;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade600,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppTheme.primaryGreen : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: AppTheme.primaryGreen)
          : null,
      onTap: () {
        setState(() {
          _sortOption = option;
        });
        Navigator.pop(context);
      },
    );
  }

  void _openEstablishment(Establishment establishment) {
    // Abrir cardápio do estabelecimento para delivery
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EstablishmentMenuScreen(establishment: establishment),
      ),
    );
  }
}
