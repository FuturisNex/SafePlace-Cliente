import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/establishment.dart';
import '../models/delivery_models.dart';
import '../services/delivery_service.dart';
import '../theme/app_theme.dart';

/// Tela de gestão de cardápio do estabelecimento
class BusinessMenuScreen extends StatefulWidget {
  final Establishment establishment;

  const BusinessMenuScreen({
    super.key,
    required this.establishment,
  });

  @override
  State<BusinessMenuScreen> createState() => _BusinessMenuScreenState();
}

class _BusinessMenuScreenState extends State<BusinessMenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Cardápio'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Categorias'),
            Tab(text: 'Itens'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesTab(),
          _buildItemsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddCategoryDialog();
          } else {
            _showAddItemDialog();
          }
        },
        backgroundColor: Colors.green.shade600,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Categoria' : 'Item'),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return StreamBuilder<List<MenuCategory>>(
      stream: DeliveryService.getCategoriesStream(widget.establishment.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return _buildEmptyState(
            icon: Icons.category,
            title: 'Nenhuma categoria',
            subtitle: 'Crie categorias para organizar seu cardápio',
          );
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          onReorder: (oldIndex, newIndex) {
            // TODO: Implementar reordenação
          },
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryCard(category, key: ValueKey(category.id));
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(MenuCategory category, {Key? key}) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.category, color: Colors.green.shade600),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: category.description != null
            ? Text(
                category.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!category.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Inativo',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditCategoryDialog(category);
                } else if (value == 'delete') {
                  _confirmDeleteCategory(category);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Excluir', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          setState(() {
            _selectedCategoryId = category.id;
            _tabController.animateTo(1);
          });
        },
      ),
    );
  }

  Widget _buildItemsTab() {
    return Column(
      children: [
        // Filtro por categoria
        StreamBuilder<List<MenuCategory>>(
          stream: DeliveryService.getCategoriesStream(widget.establishment.id),
          builder: (context, snapshot) {
            final categories = snapshot.data ?? [];
            if (categories.isEmpty) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip(null, 'Todos'),
                    ...categories.map((c) => _buildCategoryChip(c.id, c.name)),
                  ],
                ),
              ),
            );
          },
        ),

        // Lista de itens
        Expanded(
          child: StreamBuilder<List<DeliveryMenuItem>>(
            stream:
                DeliveryService.getMenuItemsStream(widget.establishment.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var items = snapshot.data ?? [];

              // Filtrar por categoria selecionada
              if (_selectedCategoryId != null) {
                items = items
                    .where((i) => i.categoryId == _selectedCategoryId)
                    .toList();
              }

              if (items.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.restaurant_menu,
                  title: 'Nenhum item',
                  subtitle: 'Adicione itens ao seu cardápio',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildItemCard(items[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String? categoryId, String name) {
    final isSelected = _selectedCategoryId == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(name),
        selected: isSelected,
        selectedColor: Colors.green.shade100,
        checkmarkColor: Colors.green.shade700,
        onSelected: (selected) {
          setState(() {
            _selectedCategoryId = selected ? categoryId : null;
          });
        },
      ),
    );
  }

  Widget _buildItemCard(DeliveryMenuItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (item.isPromoted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Destaque',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
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
                        const SizedBox(width: 8),
                      ],
                      Text(
                        'R\$ ${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      // Toggle disponibilidade
                      Switch(
                        value: item.isAvailable,
                        activeColor: Colors.green,
                        onChanged: (value) {
                          DeliveryService.toggleItemAvailability(
                              item.id, value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditItemDialog(item);
                } else if (value == 'delete') {
                  _confirmDeleteItem(item);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Excluir', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade200,
      child: Icon(Icons.restaurant, color: Colors.grey.shade400),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ============ DIALOGS ============

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Categoria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da categoria',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final category = MenuCategory(
                id: '',
                establishmentId: widget.establishment.id,
                name: nameController.text.trim(),
                description: descController.text.trim().isNotEmpty
                    ? descController.text.trim()
                    : null,
              );

              await DeliveryService.createCategory(category);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(MenuCategory category) {
    final nameController = TextEditingController(text: category.name);
    final descController =
        TextEditingController(text: category.description ?? '');
    bool isActive = category.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Categoria'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da categoria',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Ativo'),
                value: isActive,
                onChanged: (value) {
                  setDialogState(() => isActive = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                final updated = MenuCategory(
                  id: category.id,
                  establishmentId: category.establishmentId,
                  name: nameController.text.trim(),
                  description: descController.text.trim().isNotEmpty
                      ? descController.text.trim()
                      : null,
                  order: category.order,
                  isActive: isActive,
                );

                await DeliveryService.updateCategory(updated);
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(MenuCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: Text(
          'Tem certeza que deseja excluir "${category.name}"?\n\n'
          'Todos os itens desta categoria também serão excluídos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DeliveryService.deleteCategory(category.id);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    _showItemFormDialog(null);
  }

  void _showEditItemDialog(DeliveryMenuItem item) {
    _showItemFormDialog(item);
  }

  void _showItemFormDialog(DeliveryMenuItem? existingItem) {
    final nameController =
        TextEditingController(text: existingItem?.name ?? '');
    final descController =
        TextEditingController(text: existingItem?.description ?? '');
    final priceController = TextEditingController(
      text: existingItem?.price.toStringAsFixed(2) ?? '',
    );
    final originalPriceController = TextEditingController(
      text: existingItem?.originalPrice?.toStringAsFixed(2) ?? '',
    );

    String? selectedCategoryId =
        existingItem?.categoryId ?? _selectedCategoryId;
    bool isPromoted = existingItem?.isPromoted ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existingItem == null ? 'Novo Item' : 'Editar Item',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Categoria
                StreamBuilder<List<MenuCategory>>(
                  stream: DeliveryService.getCategoriesStream(
                      widget.establishment.id),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];
                    if (categories.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Crie uma categoria primeiro',
                          style: TextStyle(color: Colors.orange),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                      ),
                      items: categories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setSheetState(() => selectedCategoryId = value);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Nome
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do item',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Descrição
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // Preços
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Preço (R\$)',
                          prefixText: 'R\$ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: originalPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Preço original',
                          hintText: 'Para promoção',
                          prefixText: 'R\$ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Destaque
                SwitchListTile(
                  title: const Text('Destacar item'),
                  subtitle: const Text('Aparece em primeiro na lista'),
                  value: isPromoted,
                  onChanged: (value) {
                    setSheetState(() => isPromoted = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),

                // Botões
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty ||
                              priceController.text.isEmpty ||
                              selectedCategoryId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Preencha os campos obrigatórios'),
                              ),
                            );
                            return;
                          }

                          final item = DeliveryMenuItem(
                            id: existingItem?.id ?? '',
                            establishmentId: widget.establishment.id,
                            categoryId: selectedCategoryId!,
                            name: nameController.text.trim(),
                            description: descController.text.trim().isNotEmpty
                                ? descController.text.trim()
                                : null,
                            price: double.parse(priceController.text),
                            originalPrice:
                                originalPriceController.text.isNotEmpty
                                    ? double.parse(originalPriceController.text)
                                    : null,
                            isPromoted: isPromoted,
                            order: existingItem?.order ?? 0,
                          );

                          if (existingItem == null) {
                            await DeliveryService.createMenuItem(item);
                          } else {
                            await DeliveryService.updateMenuItem(item);
                          }

                          if (mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(existingItem == null ? 'Criar' : 'Salvar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteItem(DeliveryMenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Item'),
        content: Text('Tem certeza que deseja excluir "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DeliveryService.deleteMenuItem(item.id);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
