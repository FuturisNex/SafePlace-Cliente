import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/establishment.dart';
import '../models/delivery_models.dart';
import '../providers/cart_provider.dart';
import '../services/delivery_service.dart';
import '../theme/app_theme.dart';
import 'cart_screen.dart';

/// Tela de cardápio do estabelecimento para usuários
class EstablishmentMenuScreen extends StatefulWidget {
  final Establishment establishment;

  const EstablishmentMenuScreen({
    super.key,
    required this.establishment,
  });

  @override
  State<EstablishmentMenuScreen> createState() => _EstablishmentMenuScreenState();
}

class _EstablishmentMenuScreenState extends State<EstablishmentMenuScreen> {
  String? _selectedCategoryId;
  DeliveryConfig? _deliveryConfig;
  bool _isLoadingConfig = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveryConfig();
  }

  Future<void> _loadDeliveryConfig() async {
    final config = await DeliveryService.getDeliveryConfig(widget.establishment.id);
    if (mounted) {
      setState(() {
        _deliveryConfig = config;
        _isLoadingConfig = false;
      });

      // Inicializar carrinho com estabelecimento
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.setEstablishment(
        widget.establishment,
        deliveryFee: config?.deliveryFee ?? 0,
        freeDeliveryMinOrder: config?.freeDeliveryMinOrder,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // App Bar com imagem
          _buildSliverAppBar(),

          // Info do estabelecimento
          SliverToBoxAdapter(child: _buildEstablishmentInfo()),

          // Categorias
          SliverToBoxAdapter(child: _buildCategoriesBar()),

          // Lista de itens
          _buildMenuItems(),
        ],
      ),
      bottomNavigationBar: _buildCartBar(),
    );
  }

  Widget _buildSliverAppBar() {
    final establishment = widget.establishment;
    final imageUrl = establishment.photoUrls.isNotEmpty
        ? establishment.photoUrls.first
        : establishment.avatarUrl;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.restaurant, size: 64, color: Colors.white),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Nome do estabelecimento
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          establishment.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (establishment.planType != null &&
                          establishment.planType != 'free')
                        const Icon(Icons.verified, color: Colors.blue, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${establishment.rating?.toStringAsFixed(1) ?? '0.0'}',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.schedule, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        establishment.deliveryTimeFormatted,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.delivery_dining, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        establishment.deliveryFeeFormatted,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildEstablishmentInfo() {
    if (_isLoadingConfig) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final config = _deliveryConfig;
    final establishment = widget.establishment;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info de entrega
          Row(
            children: [
              _buildInfoChip(
                Icons.schedule,
                '${config?.deliveryTimeMin ?? 30}-${config?.deliveryTimeMax ?? 60} min',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.delivery_dining,
                config?.deliveryFee != null
                    ? 'R\$ ${config!.deliveryFee!.toStringAsFixed(2)}'
                    : 'Grátis',
                highlight: config?.deliveryFee == null,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.shopping_bag,
                'Mín R\$ ${(config?.minOrderValue ?? 0).toStringAsFixed(0)}',
              ),
            ],
          ),

          // Frete grátis
          if (config?.freeDeliveryMinOrder != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Frete grátis acima de R\$ ${config!.freeDeliveryMinOrder!.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Formas de pagamento
          if (config?.paymentMethods.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: config!.paymentMethods.map((method) {
                IconData icon;
                String label;
                switch (method) {
                  case 'pix':
                    icon = Icons.pix;
                    label = 'PIX';
                    break;
                  case 'cartao':
                    icon = Icons.credit_card;
                    label = 'Cartão';
                    break;
                  case 'dinheiro':
                    icon = Icons.attach_money;
                    label = 'Dinheiro';
                    break;
                  default:
                    icon = Icons.payment;
                    label = method;
                }
                return Chip(
                  avatar: Icon(icon, size: 16),
                  label: Text(label, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlight ? Colors.green.shade700 : Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: highlight ? Colors.green.shade700 : Colors.grey.shade700,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesBar() {
    return StreamBuilder<List<MenuCategory>>(
      stream: DeliveryService.getCategoriesStream(widget.establishment.id),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        if (categories.isEmpty) return const SizedBox.shrink();

        // Filtrar apenas categorias ativas
        final activeCategories = categories.where((c) => c.isActive).toList();

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryChip(null, 'Todos'),
                ...activeCategories.map((c) => _buildCategoryChip(c.id, c.name)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String? categoryId, String name) {
    final isSelected = _selectedCategoryId == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(name),
        selected: isSelected,
        selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryGreen,
        onSelected: (selected) {
          setState(() {
            _selectedCategoryId = selected ? categoryId : null;
          });
        },
      ),
    );
  }

  Widget _buildMenuItems() {
    return StreamBuilder<List<DeliveryMenuItem>>(
      stream: DeliveryService.getMenuItemsStream(widget.establishment.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        var items = snapshot.data ?? [];

        // Filtrar apenas itens disponíveis
        items = items.where((i) => i.isAvailable).toList();
        
        // Filtrar por dia da semana (mostrar apenas itens disponíveis hoje)
        items = items.where((i) => i.isAvailableToday).toList();

        // Filtrar por categoria
        if (_selectedCategoryId != null) {
          items = items.where((i) => i.categoryId == _selectedCategoryId).toList();
        }

        if (items.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum item disponível',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        // Separar itens em destaque
        final promotedItems = items.where((i) => i.isPromoted).toList();
        final regularItems = items.where((i) => !i.isPromoted).toList();

        return SliverList(
          delegate: SliverChildListDelegate([
            // Itens em destaque
            if (promotedItems.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '⭐ Destaques',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...promotedItems.map((item) => _buildMenuItem(item)),
            ],

            // Itens regulares
            if (regularItems.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  _selectedCategoryId != null ? 'Itens' : 'Cardápio',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...regularItems.map((item) => _buildMenuItem(item)),
            ],

            // Espaço para o carrinho
            const SizedBox(height: 100),
          ]),
        );
      },
    );
  }

  Widget _buildMenuItem(DeliveryMenuItem item) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final quantity = cart.getItemQuantity(item.id);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          child: InkWell(
            onTap: () => _showItemDetails(item),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagem
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.imageUrl != null
                        ? Image.network(
                            item.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (item.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (item.hasDiscount) ...[
                              Text(
                                'R\$ ${item.originalPrice!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              'R\$ ${item.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                                fontSize: 16,
                              ),
                            ),
                            if (item.hasDiscount) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${item.discountPercent.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Botão de adicionar / quantidade
                  const SizedBox(width: 8),
                  if (quantity == 0)
                    IconButton(
                      onPressed: () {
                        cart.addItem(item);
                        _showAddedFeedback();
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => cart.decrementItem(item.id),
                            icon: const Icon(Icons.remove, size: 18),
                            color: AppTheme.primaryGreen,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          Text(
                            '$quantity',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          IconButton(
                            onPressed: () => cart.incrementItem(item.id),
                            icon: const Icon(Icons.add, size: 18),
                            color: AppTheme.primaryGreen,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
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
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade200,
      child: Icon(Icons.restaurant, color: Colors.grey.shade400),
    );
  }

  void _showItemDetails(DeliveryMenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ItemDetailsSheet(item: item),
    );
  }

  void _showAddedFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item adicionado ao carrinho'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildCartBar() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Info do carrinho
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cart.totalItems} ${cart.totalItems == 1 ? 'item' : 'itens'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'R\$ ${cart.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botão ver carrinho
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shopping_cart),
                      SizedBox(width: 8),
                      Text(
                        'Ver Carrinho',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Sheet de detalhes do item
class _ItemDetailsSheet extends StatefulWidget {
  final DeliveryMenuItem item;

  const _ItemDetailsSheet({required this.item});

  @override
  State<_ItemDetailsSheet> createState() => _ItemDetailsSheetState();
}

class _ItemDetailsSheetState extends State<_ItemDetailsSheet> {
  int _quantity = 1;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),

          // Nome e preço
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item.hasDiscount)
                    Text(
                      'R\$ ${item.originalPrice!.toStringAsFixed(2)}',
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  Text(
                    'R\$ ${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Descrição
          if (item.description != null) ...[
            const SizedBox(height: 8),
            Text(
              item.description!,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],

          // Tags dietéticas
          if (item.dietaryTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: item.dietaryTags.map((tag) {
                return Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // Observações
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Observações (opcional)',
              hintText: 'Ex: Sem cebola, bem passado...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 20),

          // Quantidade e adicionar
          Row(
            children: [
              // Seletor de quantidade
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Botão adicionar
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final cart = Provider.of<CartProvider>(context, listen: false);
                    cart.addItem(
                      item,
                      quantity: _quantity,
                      notes: _notesController.text.isNotEmpty
                          ? _notesController.text
                          : null,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$_quantity x ${item.name} adicionado'),
                        backgroundColor: AppTheme.primaryGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Adicionar R\$ ${(item.price * _quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
