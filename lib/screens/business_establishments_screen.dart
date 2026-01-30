import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/establishment.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../utils/translations.dart';
import '../theme/app_theme.dart';
import 'business_register_establishment_screen.dart';
import 'business_dashboard_screen.dart';

/// Tela "Meus Estabelecimentos" para usuários empresa.
/// Design SaaS moderno: sem header próprio (usa o do HomeScreen), cards limpos.
class BusinessEstablishmentsScreen extends StatelessWidget {
  const BusinessEstablishmentsScreen({super.key});

  // Cor de fundo consistente
  static const Color _bgColor = Color(0xFFF7F8FA);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const navApproxHeight = 96.0;

    if (user == null || user.type != UserType.business) {
      return Container(
        color: _bgColor,
        child: Center(
          child: Text(
            Translations.getText(context, 'restrictedAccess'),
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    // Sem Scaffold próprio - usa o do HomeScreen
    return Container(
      color: _bgColor,
      child: Column(
        children: [
          // Card de título compacto (sem duplicar header)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildTitleCard(context),
          ),
          // Lista de estabelecimentos
          Expanded(
            child: _BusinessEstablishmentsList(
              ownerId: user.id,
              bottomPadding: bottomPadding + navApproxHeight + 80, // Espaço para FAB e nav
            ),
          ),
        ],
      ),
    );
  }

  /// Card de título compacto (substitui o header duplicado)
  Widget _buildTitleCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkGreen,
            AppTheme.primaryGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
              Icons.storefront_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meus Estabelecimentos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gerencie seus locais cadastrados',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Botão de adicionar
          Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BusinessRegisterEstablishmentScreen(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessEstablishmentsList extends StatefulWidget {
  final String ownerId;
  final double bottomPadding;

  const _BusinessEstablishmentsList({
    required this.ownerId,
    this.bottomPadding = 180,
  });

  @override
  State<_BusinessEstablishmentsList> createState() => _BusinessEstablishmentsListState();
}

class _BusinessEstablishmentsListState extends State<_BusinessEstablishmentsList> {
  late Future<List<Establishment>> _futureEstablishments;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadEstablishments();
  }

  void _loadEstablishments() {
    setState(() {
      _futureEstablishments = FirebaseService.getEstablishmentsByOwner(widget.ownerId);
    });
  }

  Future<void> _confirmAndDelete(BuildContext context, String establishmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir estabelecimento'),
        content: const Text('Tem certeza que deseja excluir este estabelecimento? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('establishments').doc(establishmentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estabelecimento excluído')));
      _loadEstablishments();
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir estabelecimento: $err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Establishment>>(
      future: _futureEstablishments,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final establishments = snapshot.data ?? [];

        if (establishments.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(20, 16, 20, widget.bottomPadding),
          itemCount: establishments.length,
          itemBuilder: (context, index) {
            final establishment = establishments[index];
            return _EstablishmentCard(
              establishment: establishment,
              index: index,
              onDelete: () => _confirmAndDelete(context, establishment.id),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store_mall_directory_outlined,
                size: 56,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum estabelecimento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre seu primeiro local para\ncomeçar a receber clientes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstablishmentCard extends StatelessWidget {
  final Establishment establishment;
  final int index;
  final VoidCallback? onDelete;

  const _EstablishmentCard({
    required this.establishment,
    required this.index,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasAvatar = establishment.avatarUrl.isNotEmpty;
    final bool isBoosted = establishment.isBoosted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBoosted ? AppTheme.primaryGreen.withOpacity(0.3) : Colors.grey.shade200,
          width: isBoosted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BusinessManageEstablishmentScreen(
                  establishment: establishment,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar / Imagem
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: hasAvatar ? null : const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(14),
                    image: hasAvatar
                        ? DecorationImage(
                            image: NetworkImage(establishment.avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: hasAvatar
                      ? null
                      : Center(
                          child: Icon(
                            _getCategoryIcon(establishment.category),
                            color: const Color(0xFF64748B),
                            size: 26,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              establishment.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isBoosted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    size: 12,
                                    color: AppTheme.primaryGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ativo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            _getCategoryIcon(establishment.category),
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            CategoryTranslator.translate(context, establishment.category),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: establishment.isOpen
                                  ? const Color(0xFFDCFCE7)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              establishment.isOpen ? 'Aberto' : 'Fechado',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: establishment.isOpen
                                    ? const Color(0xFF166534)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Ações rápidas (editar / excluir)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        // Abrir a tela de gerenciamento (edita/mostra detalhes) em vez de passar editDocId
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BusinessManageEstablishmentScreen(
                              establishment: establishment,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Seta
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('restaurant') || cat.contains('restaurante')) {
      return Icons.restaurant_rounded;
    } else if (cat.contains('cafe') || cat.contains('café')) {
      return Icons.coffee_rounded;
    } else if (cat.contains('bakery') || cat.contains('padaria') || cat.contains('confeitaria')) {
      return Icons.bakery_dining_rounded;
    } else if (cat.contains('hotel') || cat.contains('pousada')) {
      return Icons.hotel_rounded;
    } else if (cat.contains('market') || cat.contains('mercado')) {
      return Icons.shopping_cart_rounded;
    }
    return Icons.store_rounded;
  }
}