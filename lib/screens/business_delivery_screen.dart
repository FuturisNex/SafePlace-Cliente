import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/establishment.dart';
import '../models/delivery_models.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../services/delivery_service.dart';
import '../theme/app_theme.dart';
import 'business_delivery_config_screen.dart';
import 'business_menu_screen.dart';
import 'business_coupons_screen.dart';

/// Tela principal de gestão de Delivery para empresas
class BusinessDeliveryScreen extends StatefulWidget {
  const BusinessDeliveryScreen({super.key});

  @override
  State<BusinessDeliveryScreen> createState() => _BusinessDeliveryScreenState();
}

class _BusinessDeliveryScreenState extends State<BusinessDeliveryScreen> {
  Establishment? _selectedEstablishment;
  DeliveryConfig? _deliveryConfig;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: Text('Usuário não autenticado'));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: StreamBuilder<List<Establishment>>(
          stream: FirebaseService.establishmentsByOwnerStream(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final establishments = snapshot.data ?? [];

            if (establishments.isEmpty) {
              return _buildNoEstablishments();
            }

            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),

                // Seletor de estabelecimento
                SliverToBoxAdapter(
                  child: _buildEstablishmentSelector(establishments),
                ),

                // Conteúdo baseado no estabelecimento selecionado
                if (_selectedEstablishment != null) ...[
                  // Status do Delivery
                  SliverToBoxAdapter(
                    child: _buildDeliveryStatus(),
                  ),

                  // Menu de opções
                  SliverToBoxAdapter(
                    child: _buildOptionsMenu(),
                  ),

                  // Estatísticas rápidas
                  SliverToBoxAdapter(
                    child: _buildQuickStats(),
                  ),
                ] else
                  SliverFillRemaining(
                    child: _buildSelectEstablishmentPrompt(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade600,
            Colors.deepOrange.shade500,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gerencie seu delivery',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstablishmentSelector(List<Establishment> establishments) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Establishment>(
          value: _selectedEstablishment,
          isExpanded: true,
          hint: const Row(
            children: [
              Icon(Icons.store, color: Colors.grey),
              SizedBox(width: 12),
              Text('Selecione um estabelecimento'),
            ],
          ),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: establishments.map((e) {
            return DropdownMenuItem<Establishment>(
              value: e,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: e.avatarUrl.isNotEmpty
                        ? NetworkImage(e.avatarUrl)
                        : null,
                    child: e.avatarUrl.isEmpty
                        ? const Icon(Icons.store, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          e.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (e.hasDelivery)
                          Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 12, color: Colors.green.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Delivery ativo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (establishment) {
            setState(() {
              _selectedEstablishment = establishment;
            });
            if (establishment != null) {
              _loadDeliveryConfig(establishment.id);
            }
          },
        ),
      ),
    );
  }

  Future<void> _loadDeliveryConfig(String establishmentId) async {
    setState(() => _isLoading = true);
    try {
      final config = await DeliveryService.getDeliveryConfig(establishmentId);
      setState(() {
        _deliveryConfig = config;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDeliveryStatus() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isActive = _deliveryConfig?.isActive ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isActive ? Icons.check_circle : Icons.warning_amber,
              color: isActive ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Delivery Ativo' : 'Delivery Inativo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                  ),
                ),
                Text(
                  isActive
                      ? 'Seu estabelecimento está recebendo pedidos'
                      : 'Configure o delivery para começar a receber pedidos',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            activeColor: Colors.green,
            onChanged: (value) async {
              if (_deliveryConfig == null && value) {
                // Precisa configurar primeiro
                _openDeliveryConfig();
              } else if (_deliveryConfig != null) {
                final updated = _deliveryConfig!.copyWith(isActive: value);
                await DeliveryService.saveDeliveryConfig(updated);
                _loadDeliveryConfig(_selectedEstablishment!.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsMenu() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gerenciar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOptionCard(
                  icon: Icons.settings,
                  title: 'Configurações',
                  subtitle: 'Taxa, tempo, raio',
                  color: Colors.blue,
                  onTap: _openDeliveryConfig,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOptionCard(
                  icon: Icons.restaurant_menu,
                  title: 'Cardápio',
                  subtitle: 'Itens e categorias',
                  color: Colors.green,
                  onTap: _openMenu,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOptionCard(
                  icon: Icons.local_offer,
                  title: 'Cupons',
                  subtitle: 'Promoções e descontos',
                  color: Colors.purple,
                  onTap: _openCoupons,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOptionCard(
                  icon: Icons.receipt_long,
                  title: 'Pedidos',
                  subtitle: 'Histórico e pendentes',
                  color: Colors.orange,
                  onTap: _openOrders,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _selectedEstablishment != null
          ? DeliveryService.getDeliveryStats(_selectedEstablishment!.id)
          : Future.value({}),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final totalOrders = stats['totalOrders'] ?? 0;
        final deliveredOrders = stats['deliveredOrders'] ?? 0;
        final totalRevenue = stats['totalRevenue'] ?? 0.0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Pedidos',
                      totalOrders.toString(),
                      Icons.shopping_bag,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Entregues',
                      deliveredOrders.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Faturamento',
                      'R\$ ${totalRevenue.toStringAsFixed(0)}',
                      Icons.attach_money,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNoEstablishments() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Nenhum estabelecimento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre um estabelecimento para configurar o delivery',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectEstablishmentPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Selecione um estabelecimento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha acima qual estabelecimento deseja gerenciar',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _openDeliveryConfig() {
    if (_selectedEstablishment == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessDeliveryConfigScreen(
          establishment: _selectedEstablishment!,
          existingConfig: _deliveryConfig,
        ),
      ),
    ).then((_) => _loadDeliveryConfig(_selectedEstablishment!.id));
  }

  void _openMenu() {
    if (_selectedEstablishment == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessMenuScreen(
          establishment: _selectedEstablishment!,
        ),
      ),
    );
  }

  void _openCoupons() {
    if (_selectedEstablishment == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessCouponsScreen(
          establishment: _selectedEstablishment!,
        ),
      ),
    );
  }

  void _openOrders() {
    if (_selectedEstablishment == null) return;
    // TODO: Implementar tela de pedidos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tela de pedidos em desenvolvimento')),
    );
  }
}
