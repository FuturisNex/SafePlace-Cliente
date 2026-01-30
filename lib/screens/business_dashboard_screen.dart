import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safeplate/utils/scroll_bus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_purchase/in_app_purchase.dart'; // Importação do in_app_purchase
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';
import '../models/user.dart';
import '../models/establishment.dart';
import '../models/business_plan.dart';
import '../models/menu_item.dart';
import '../services/firebase_service.dart';
import '../services/boost_service.dart';
import '../services/iap_service.dart'; // Importação do IAP
import '../utils/iap_products.dart'; // Importação do IAP Products
import '../widgets/review_card.dart';
import '../utils/translations.dart';
import '../theme/app_theme.dart';
import 'boost_insights_screen.dart';
import 'boost_overview_screen.dart';
import 'business_register_establishment_screen.dart';
import 'business_edit_menu_item_screen.dart';

const String kBusinessFairUrl = 'https://pratoseguro.com/feira';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  static const Color _bgColor = Color(0xFFF7F8FA);
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _plansKey = GlobalKey();
  final GlobalKey _establishmentsKey = GlobalKey();
  String? _selectedEstablishmentId;

  // Variáveis para IAP
  bool _loading = true;
  List<ProductDetails> _products = [];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initIap();

    ScrollBus.notifier.addListener(() {
      if (ScrollBus.notifier.value == 'plans') {
        // Se o dashboard receber o pedido 'plans', role até a seção de planos com delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _scrollToPlans();
            // Resetar o notifier para evitar múltiplas execuções
            ScrollBus.notifier.value = null;
          }
        });
      }
    });
  }

  Future<void> _initIap() async {
    final ids = IapProducts
        .allProductIds(); // Certifique-se de que este método está definido
    await IapService.instance.init(productIds: ids); // Inicializa o IAP
    setState(() {
      _products =
          IapService.instance.productDetails; // Preenche a lista de produtos
      _loading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPlans() {
    final context = _plansKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToEstablishments() {
    final context = _establishmentsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Color _getPlanColor(PlanType planType) {
    switch (planType) {
      case PlanType.premium:
        return Colors.purple;
      case PlanType.intermediate:
        return Colors.blue;
      case PlanType.basic:
        return Colors.green;
    }
  }

  Widget _buildEstablishmentSelector(BuildContext context, String ownerId) {
    return StreamBuilder<List<Establishment>>(
      stream: FirebaseService.establishmentsByOwnerStream(ownerId),
      builder: (context, snapshot) {
        final establishments = snapshot.data ?? [];

        if (establishments.isEmpty) {
          return const SizedBox.shrink();
        }

        Establishment? selectedEst;
        if (_selectedEstablishmentId != null) {
          selectedEst = establishments.firstWhere(
            (e) => e.id == _selectedEstablishmentId,
            orElse: () => establishments.first,
          );
        }

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEstablishmentId = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedEstablishmentId == null
                          ? AppTheme.primaryGreen
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.dashboard_rounded,
                          size: 18,
                          color: _selectedEstablishmentId == null
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Visão Geral',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedEstablishmentId == null
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _showEstablishmentPicker(context, establishments),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedEstablishmentId != null
                          ? AppTheme.primaryGreen
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          size: 18,
                          color: _selectedEstablishmentId != null
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            selectedEst?.name ?? 'Selecionar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _selectedEstablishmentId != null
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: _selectedEstablishmentId != null
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEstablishmentPicker(
      BuildContext context, List<Establishment> establishments) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.storefront,
                            color: AppTheme.primaryGreen, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seus Estabelecimentos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Selecione para ver insights específicos',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: establishments.length,
                    itemBuilder: (context, index) {
                      final est = establishments[index];
                      final isSelected = _selectedEstablishmentId == est.id;
                      final planColor = _getPlanColor(est.planType);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedEstablishmentId = est.id;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryGreen.withOpacity(0.08)
                                : null,
                            border: Border(
                              left: BorderSide(
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: planColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.storefront, color: planColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      est.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: planColor.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            est.planType.label,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: planColor,
                                            ),
                                          ),
                                        ),
                                        if (!est.planType.isPaid) ...[
                                          const SizedBox(width: 6),
                                          Icon(Icons.lock_outline,
                                              size: 12,
                                              color: Colors.grey.shade500),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Sem insights',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      size: 16, color: Colors.white),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.padding.bottom;
    const navApproxHeight = 96.0;
    final bottomPadding = 16.0 + bottomInset + navApproxHeight;

    if (user == null || user.type != UserType.business) {
      return Container(
        color: _bgColor,
        child: Center(
          child: Text(Translations.getText(context, 'restrictedAccess')),
        ),
      );
    }

    return Container(
      color: _bgColor,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingCard(context, user),
            const SizedBox(height: 16),
            _buildEstablishmentSelector(context, user.id),
            const SizedBox(height: 20),
            _buildMetricsSection(context, user.id),
            const SizedBox(height: 20),
            _buildBoostSection(context, user.id),
            const SizedBox(height: 20),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            Container(
              key: _plansKey,
              child: _buildBusinessPitchAndPlans(context, user),
            ),
            const SizedBox(height: 20),
            _buildBusinessEventsSection(context),
            const SizedBox(height: 20),
            _buildQuickStats(context, user.id),
            const SizedBox(height: 20),
            Container(
              key: _establishmentsKey,
              child: _buildEstablishmentsList(context, user.id),
            ),
          ],
        ),
      ),
    );
  }

  /// Card de saudação compacto (substitui o header duplicado)
  Widget _buildGreetingCard(BuildContext context, User user) {
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
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              image: user.photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(user.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user.photoUrl == null
                ? Center(
                    child: Text(
                      user.name?.substring(0, 1).toUpperCase() ?? 'E',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${user.name?.split(' ').first ?? 'Empresário'}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(BuildContext context, String ownerId) {
    return StreamBuilder<List<Establishment>>(
      stream: FirebaseService.establishmentsByOwnerStream(ownerId),
      builder: (context, estSnapshot) {
        final allEstablishments = estSnapshot.data ?? [];

        // Filtrar por estabelecimento selecionado
        final establishments = _selectedEstablishmentId != null
            ? allEstablishments
                .where((e) => e.id == _selectedEstablishmentId)
                .toList()
            : allEstablishments;

        // Verificar se algum estabelecimento tem plano pago
        final hasAnyPaidPlan = establishments.any((e) => e.planType.isPaid);
        final paidEstablishments =
            establishments.where((e) => e.planType.isPaid).toList();
        final freeEstablishments =
            establishments.where((e) => !e.planType.isPaid).toList();

        // Estabelecimento selecionado (se houver)
        final selectedEst =
            _selectedEstablishmentId != null && establishments.isNotEmpty
                ? establishments.first
                : null;

        return FutureBuilder<List<_EstablishmentActivity>>(
          future: _loadEstablishmentActivities(ownerId),
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final allActivities = snapshot.data ?? [];

            // Filtrar atividades pelo estabelecimento selecionado
            final activities = _selectedEstablishmentId != null
                ? allActivities
                    .where(
                        (a) => a.establishment.id == _selectedEstablishmentId)
                    .toList()
                : allActivities;

            // Calcular totais apenas de estabelecimentos com plano pago
            int totalClicks = 0;
            int totalCheckIns = 0;
            int totalEstablishments = establishments.length;

            for (final a in activities) {
              // Só contar insights de estabelecimentos com plano pago
              final est = establishments.firstWhere(
                (e) => e.id == a.establishment.id,
                orElse: () => a.establishment,
              );
              if (est.planType.isPaid) {
                totalClicks += a.clicks;
                totalCheckIns += a.checkIns;
              }
            }

            // Determinar badge de status
            Widget? statusBadge;
            if (establishments.isEmpty) {
              statusBadge = null;
            } else if (paidEstablishments.length == establishments.length) {
              // Todos com plano
              statusBadge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 12, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Todos com plano',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              );
            } else if (paidEstablishments.isNotEmpty) {
              // Alguns com plano
              statusBadge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        size: 12, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '${paidEstablishments.length}/${establishments.length} com plano',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Nenhum com plano
              statusBadge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 12, color: Colors.amber.shade800),
                    const SizedBox(width: 4),
                    Text(
                      'Sem Plano',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Título dinâmico baseado na seleção
            final sectionTitle = selectedEst != null
                ? 'Insights: ${selectedEst.name}'
                : 'Visão Geral';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        sectionTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (statusBadge != null) statusBadge,
                  ],
                ),
                // Mostrar plano do estabelecimento selecionado
                if (selectedEst != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getPlanColor(selectedEst.planType)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Plano ${selectedEst.planType.label}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getPlanColor(selectedEst.planType),
                          ),
                        ),
                      ),
                      if (!selectedEst.planType.isPaid) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _scrollToPlans,
                          child: Text(
                            'Fazer upgrade →',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSaasMetricCard(
                        icon: Icons.storefront_rounded,
                        iconColor: AppTheme.primaryGreen,
                        label: 'Estabelecimentos',
                        value: isLoading ? '-' : totalEstablishments.toString(),
                        onTap: _scrollToEstablishments,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: hasAnyPaidPlan
                          ? _buildSaasMetricCard(
                              icon: Icons.touch_app_rounded,
                              iconColor: const Color(0xFF0EA5E9),
                              label: 'Cliques',
                              value: isLoading ? '-' : totalClicks.toString(),
                            )
                          : _buildLockedMetricCard(
                              icon: Icons.touch_app_rounded,
                              iconColor: const Color(0xFF0EA5E9),
                              label: 'Cliques',
                              blurredValue:
                                  isLoading ? '-' : totalClicks.toString(),
                              onTap: () => _showInsightsUpgradeModal(context),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: hasAnyPaidPlan
                          ? _buildSaasMetricCard(
                              icon: Icons.verified_user_rounded,
                              iconColor: const Color(0xFF10B981),
                              label: 'Check-ins',
                              value: isLoading ? '-' : totalCheckIns.toString(),
                            )
                          : _buildLockedMetricCard(
                              icon: Icons.verified_user_rounded,
                              iconColor: const Color(0xFF10B981),
                              label: 'Check-ins',
                              blurredValue:
                                  isLoading ? '-' : totalCheckIns.toString(),
                              onTap: () => _showInsightsUpgradeModal(context),
                            ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Card de métrica bloqueado com efeito blur para seduzir upgrade
  Widget _buildLockedMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String blurredValue,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Conteúdo borrado
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(icon, size: 20, color: iconColor.withOpacity(0.4)),
                ),
                const SizedBox(height: 12),
                // Valor borrado
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.grey.shade400,
                      Colors.grey.shade300,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    blurredValue == '-' ? '???' : '***',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            // Overlay com ícone de cadeado
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.7),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 18,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ver dados',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modal para upgrade quando clica nos insights bloqueados
  void _showInsightsUpgradeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.insights_rounded,
                size: 40,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Desbloqueie seus Insights!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Veja quantas pessoas estão visualizando seu estabelecimento, fazendo check-ins e deixando avaliações. Dados essenciais para crescer seu negócio!',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildInsightFeatureRow(
                      Icons.touch_app_rounded, 'Cliques no seu perfil'),
                  const SizedBox(height: 12),
                  _buildInsightFeatureRow(
                      Icons.verified_user_rounded, 'Check-ins de clientes'),
                  const SizedBox(height: 12),
                  _buildInsightFeatureRow(
                      Icons.star_rounded, 'Avaliações recebidas'),
                  const SizedBox(height: 12),
                  _buildInsightFeatureRow(
                      Icons.trending_up_rounded, 'Tendências de visitas'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop('scrollToPlans');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Ver Planos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Agora não',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue.shade900,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSaasMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ações rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.add_business_rounded,
                label: 'Novo local',
                color: AppTheme.primaryGreen,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const BusinessRegisterEstablishmentScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.campaign_rounded,
                label: 'Ver planos',
                color: const Color(0xFF6366F1),
                onTap: _scrollToPlans, // Agora rola até a seção de planos
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.support_agent_rounded,
                label: 'Suporte',
                color: const Color(0xFF0EA5E9),
                onTap: () async {
                  await _launchWhatsApp(context,
                      'Olá! Preciso de ajuda com minha conta empresarial no Prato Seguro.');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Seção de impulsionamento (Boost)
  Widget _buildBoostSection(BuildContext context, String ownerId) {
    return StreamBuilder<List<Establishment>>(
      stream: FirebaseService.establishmentsByOwnerStream(ownerId),
      builder: (context, snapshot) {
        final establishments = snapshot.data ?? [];

        if (establishments.isEmpty) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: BoostService.getCampaigns(ownerId, status: 'active'),
          builder: (context, campaignSnapshot) {
            final activeCampaigns = campaignSnapshot.data ?? [];
            final hasActiveCampaign = activeCampaigns.isNotEmpty;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6366F1),
                    const Color(0xFF8B5CF6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Impulsionar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Apareça nos primeiros resultados',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasActiveCampaign)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Ativo',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Campanhas ativas ou CTA
                  if (hasActiveCampaign) ...[
                    // Mostrar campanhas ativas
                    ...activeCampaigns.take(2).map((campaign) {
                      final est = establishments.firstWhere(
                        (e) => e.id == campaign['establishmentId'],
                        orElse: () => establishments.first,
                      );
                      final daysLeft = campaign['endDate'] != null
                          ? DateTime.parse(campaign['endDate'].toString())
                              .difference(DateTime.now())
                              .inDays
                          : 0;
                      final remainingBudget =
                          _calculateRemainingBudget(campaign);

                      return GestureDetector(
                        onTap: () => _openBoostInsights(context, campaign, est),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.storefront,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          est.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '$daysLeft dias restantes',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'R\$ ${remainingBudget.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Text(
                                        'saldo',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.white54, size: 20),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Barra de progresso do saldo
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: _calculateBudgetProgress(campaign),
                                  backgroundColor: Colors.white24,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    // Dois botões: Acompanhar e Impulsionar outro
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Navegar para a tela de impulsionamento (índice 2 no menu empresa)
                              final homeState =
                                  context.findAncestorStateOfType<State>();
                              if (homeState != null && homeState.mounted) {
                                // Usar callback para mudar aba
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const BoostOverviewScreen(),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.insights, size: 18),
                            label: const Text('Acompanhar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showCreateBoostModal(context, establishments),
                            icon: const Icon(Icons.add,
                                color: Colors.white, size: 18),
                            label: const Text(
                              'Impulsionar outro',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white54),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // CTA para criar primeira campanha
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildBoostFeature(
                                  Icons.visibility, 'Mais visibilidade'),
                              const SizedBox(width: 16),
                              _buildBoostFeature(
                                  Icons.trending_up, 'Mais clientes'),
                              const SizedBox(width: 16),
                              _buildBoostFeature(Icons.star, 'Mais avaliações'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            Platform.isIOS
                                ? 'Aumente sua visibilidade por 7 dias'
                                : 'A partir de R\$ 50,00 por 7 dias',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showCreateBoostModal(context, establishments),
                        icon: const Icon(Icons.rocket_launch, size: 18),
                        label: const Text(
                          'Impulsionar agora',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBoostFeature(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Modal para criar campanha de boost
  void _showCreateBoostModal(
      BuildContext context, List<Establishment> establishments) {
    Establishment? selectedEstablishment;
    int selectedDuration = 7;
    double totalBudget = 50.0;
    Map<String, dynamic>? positionEstimate;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Função para atualizar estimativa
            Future<void> updateEstimate() async {
              if (selectedEstablishment == null) return;

              setModalState(() => isLoading = true);
              try {
                final dailyBudget = totalBudget / selectedDuration;
                final estimate = await BoostService.getPositionEstimate(
                  dailyBudget: dailyBudget,
                  city: selectedEstablishment!.city,
                  state: selectedEstablishment!.state,
                  planType: selectedEstablishment!.planType.name,
                );
                setModalState(() {
                  positionEstimate = estimate;
                  isLoading = false;
                });
              } catch (e) {
                setModalState(() => isLoading = false);
              }
            }

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.rocket_launch,
                            color: Color(0xFF6366F1),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Criar Impulsionamento',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Apareça nos primeiros resultados',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selecionar estabelecimento
                            const Text(
                              'Estabelecimento',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<Establishment>(
                                  value: selectedEstablishment,
                                  isExpanded: true,
                                  hint: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('Selecione um estabelecimento'),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  borderRadius: BorderRadius.circular(12),
                                  items: establishments.map((est) {
                                    return DropdownMenuItem(
                                      value: est,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.storefront,
                                            color: _getPlanColor(est.planType),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(est.name)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getPlanColor(est.planType)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              est.planType.label,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color:
                                                    _getPlanColor(est.planType),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (est) {
                                    setModalState(
                                        () => selectedEstablishment = est);
                                    updateEstimate();
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Duração
                            const Text(
                              'Duração',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [7, 14, 30].map((days) {
                                final isSelected = selectedDuration == days;
                                final discount = BoostService.getDiscount(days);
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(
                                          () => selectedDuration = days);
                                      updateEstimate();
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(
                                          right: days != 30 ? 8 : 0),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF6366F1)
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: isSelected
                                            ? null
                                            : Border.all(
                                                color: Colors.grey.shade300),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '$days dias',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          if (discount > 0)
                                            Text(
                                              '-${(discount * 100).toInt()}%',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isSelected
                                                    ? Colors.white70
                                                    : Colors.green,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            // Valor do lance
                            if (!Platform.isIOS) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Orçamento selecionado',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'R\$ ${totalBudget.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Slider(
                                value: totalBudget,
                                min: 50,
                                max: 1000,
                                divisions: 19,
                                activeColor: const Color(0xFF6366F1),
                                onChanged: (value) {
                                  setModalState(() => totalBudget = value);
                                },
                                onChangeEnd: (value) {
                                  updateEstimate();
                                },
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'R\$ 50',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600),
                                  ),
                                  Text(
                                    'Lance diário: R\$ ${(totalBudget / selectedDuration).toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600),
                                  ),
                                  Text(
                                    'R\$ 1.000',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 20),

                            // Estimativa de posição
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : Icon(
                                            Icons.emoji_events,
                                            color: Colors.amber.shade700,
                                            size: 20,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Posição estimada',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          positionEstimate != null
                                              ? BoostService.getPositionLabel(
                                                  positionEstimate![
                                                          'positionLabel'] ??
                                                      'destaque')
                                              : 'Selecione um estabelecimento',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (positionEstimate != null)
                                          Text(
                                            '${positionEstimate!['totalActive'] ?? 0} campanhas ativas na região',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Botão de confirmar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedEstablishment == null
                            ? null
                            : () => _processBoostPayment(
                                  context,
                                  selectedEstablishment!,
                                  totalBudget,
                                  selectedDuration,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: Text(
                          Platform.isIOS
                              ? 'Impulsionar (R\$ 50,00)'
                              : 'Pagar R\$ ${totalBudget.toStringAsFixed(0)} e impulsionar',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processBoostPayment(
    BuildContext modalContext,
    Establishment establishment,
    double totalBudget,
    int durationDays,
  ) async {
    final authProvider = Provider.of<AuthProvider>(modalContext, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    // Fechar modal primeiro
    Navigator.pop(modalContext);

    // Mostrar loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Verificar se está em iOS ou Android
      if (Platform.isIOS || Platform.isAndroid) {
        // Usar o serviço de IAP para processar o pagamento
        await IapService().purchaseProduct(
          IapService.productBoost50, // Substitua pelo produto correto
          establishmentId: establishment.id,
        );

        // O listener no IapService tratará a validação e atualização
        if (mounted) Navigator.pop(context);
        return;
      }

      // Se não for iOS nem Android, trate como uma falha
      throw Exception('Plataforma não suportada para pagamentos.');
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (mounted) {
        Navigator.of(context)
            .popUntil((route) => route.isFirst || route.settings.name != null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Calcular saldo restante da campanha
  double _calculateRemainingBudget(Map<String, dynamic> campaign) {
    final totalBudget = (campaign['totalBudget'] as num?)?.toDouble() ?? 0;
    final dailyBudget = (campaign['dailyBudget'] as num?)?.toDouble() ?? 0;

    try {
      final startDate = DateTime.parse(campaign['startDate'].toString());
      final endDate = DateTime.parse(campaign['endDate'].toString());
      final now = DateTime.now();

      if (now.isAfter(endDate)) return 0;

      final elapsedDays = now
          .difference(startDate)
          .inDays
          .clamp(0, endDate.difference(startDate).inDays);
      final spent = dailyBudget * elapsedDays;
      return (totalBudget - spent).clamp(0, totalBudget);
    } catch (_) {
      return totalBudget;
    }
  }

  /// Calcular progresso do orçamento (0.0 a 1.0)
  double _calculateBudgetProgress(Map<String, dynamic> campaign) {
    try {
      final startDate = DateTime.parse(campaign['startDate'].toString());
      final endDate = DateTime.parse(campaign['endDate'].toString());
      final now = DateTime.now();

      final totalDays = endDate.difference(startDate).inDays;
      if (totalDays <= 0) return 1.0;

      final elapsedDays = now.difference(startDate).inDays.clamp(0, totalDays);
      return elapsedDays / totalDays;
    } catch (_) {
      return 0;
    }
  }

  /// Abrir tela de insights do boost
  void _openBoostInsights(BuildContext context, Map<String, dynamic> campaign,
      Establishment establishment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BoostInsightsScreen(
          campaignId: campaign['id'] as String,
          establishment: establishment,
        ),
      ),
    );
  }

  Widget _buildActivitySection(BuildContext context, String ownerId) {
    return StreamBuilder<List<Establishment>>(
      stream: FirebaseService.establishmentsByOwnerStream(ownerId),
      builder: (context, estSnapshot) {
        final allEstablishments = estSnapshot.data ?? [];

        // Filtrar por estabelecimento selecionado
        final establishments = _selectedEstablishmentId != null
            ? allEstablishments
                .where((e) => e.id == _selectedEstablishmentId)
                .toList()
            : allEstablishments;

        // Verificar se o estabelecimento filtrado tem plano pago
        final hasAnyPaidPlan = establishments.any((e) => e.planType.isPaid);

        // Se não tem plano pago, mostrar versão bloqueada
        if (!hasAnyPaidPlan) {
          return _buildLockedActivitySection(context);
        }

        return FutureBuilder<List<_EstablishmentActivity>>(
          future: _loadEstablishmentActivities(ownerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Carregando atividade dos seus estabelecimentos...',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final allActivities =
                snapshot.data ?? const <_EstablishmentActivity>[];

            // Filtrar atividades pelo estabelecimento selecionado
            final activities = _selectedEstablishmentId != null
                ? allActivities
                    .where(
                        (a) => a.establishment.id == _selectedEstablishmentId)
                    .toList()
                : allActivities;
            if (activities.isEmpty) {
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.insights, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Atividade no app',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cadastre seu primeiro estabelecimento para começar a acompanhar cliques e check-ins.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            int totalClicks = 0;
            int totalCheckIns = 0;
            int sponsoredClicks = 0;
            int sponsoredCheckIns = 0;

            for (final activity in activities) {
              totalClicks += activity.clicks;
              totalCheckIns += activity.checkIns;
              sponsoredClicks += activity.sponsoredClicks;
              if (activity.establishment.isBoosted) {
                sponsoredCheckIns += activity.checkIns;
              }
            }

            final boostedCount =
                activities.where((a) => a.establishment.isBoosted).length;

            final sortedByClicks = List<_EstablishmentActivity>.from(activities)
              ..sort((a, b) => b.clicks.compareTo(a.clicks));
            final topByClicks = sortedByClicks.take(3).toList();
            final int maxClicks = activities.fold<int>(
                0, (max, a) => a.clicks > max ? a.clicks : max);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Atividade no app',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // Cards principais de atividade
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetricCard(
                      context,
                      icon: Icons.touch_app,
                      color: Colors.blue,
                      label: 'Cliques totais',
                      value: totalClicks.toString(),
                    ),
                    _buildMetricCard(
                      context,
                      icon: Icons.how_to_reg,
                      color: Colors.green,
                      label: 'Check-ins totais',
                      value: totalCheckIns.toString(),
                    ),
                    _buildMetricCard(
                      context,
                      icon: Icons.campaign,
                      color: AppTheme.premiumBlue,
                      label: 'Estabelecimentos patrocinados',
                      value: boostedCount.toString(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Desempenho dos anúncios patrocinados
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.premiumBlueLight.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.campaign,
                                color: AppTheme.premiumBlue,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Desempenho dos anúncios patrocinados',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (boostedCount == 0)
                          const Text(
                            'Ative um plano Intermediário ou Premium para destacar seus estabelecimentos nos resultados e acompanhar cliques patrocinados aqui.',
                            style: TextStyle(fontSize: 13),
                          )
                        else ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cliques em anúncios',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      sponsoredClicks.toString(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Check-ins em patrocinados',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      sponsoredCheckIns.toString(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Conversão aproximada',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      sponsoredClicks > 0
                                          ? '${((sponsoredCheckIns / sponsoredClicks) * 100).clamp(0, 100).toStringAsFixed(1)}%'
                                          : '-%',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Ranking de estabelecimentos por cliques (gráfico simples tipo barra)
                if (topByClicks.isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.bar_chart,
                                  size: 18, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Ranking de estabelecimentos por cliques',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...topByClicks.map((activity) {
                            return _buildRankingRow(
                                context, activity, maxClicks);
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Seção de atividades bloqueada para usuários sem plano
  Widget _buildLockedActivitySection(BuildContext context) {
    return GestureDetector(
      onTap: () => _showInsightsUpgradeModal(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Stack(
          children: [
            // Conteúdo borrado de fundo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.insights, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text(
                            'Atividade no app',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock,
                                size: 12, color: Colors.amber.shade800),
                            const SizedBox(width: 4),
                            Text(
                              'Sem Plano',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Cards borrados
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildBlurredMetricCard(
                        icon: Icons.touch_app,
                        color: Colors.blue,
                        label: 'Cliques totais',
                      ),
                      _buildBlurredMetricCard(
                        icon: Icons.how_to_reg,
                        color: Colors.green,
                        label: 'Check-ins totais',
                      ),
                      _buildBlurredMetricCard(
                        icon: Icons.star,
                        color: Colors.orange,
                        label: 'Avaliações',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Gráfico borrado
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final heights = [
                          40.0,
                          55.0,
                          35.0,
                          70.0,
                          45.0,
                          60.0,
                          50.0
                        ];
                        return Container(
                          width: 24,
                          height: heights[index],
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            // Overlay com CTA
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.9),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 28,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Desbloqueie seus Insights',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Veja cliques, check-ins e avaliações',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Ver Planos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurredMetricCard({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color.withOpacity(0.4)),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<_EstablishmentActivity>> _loadEstablishmentActivities(
      String ownerId) async {
    try {
      final establishments =
          await FirebaseService.getEstablishmentsByOwner(ownerId);
      if (establishments.isEmpty) {
        return const <_EstablishmentActivity>[];
      }

      final activities = await Future.wait(
        establishments.map((establishment) async {
          final stats = await FirebaseService.getEstablishmentActivityStats(
              establishment.id);
          final clicks = stats['clicks'] ?? 0;
          final checkIns = stats['checkIns'] ?? 0;
          final organicClicks = stats['organicClicks'] ?? 0;
          final sponsoredClicks = stats['sponsoredClicks'] ?? 0;
          return _EstablishmentActivity(
            establishment: establishment,
            clicks: clicks,
            organicClicks: organicClicks,
            sponsoredClicks: sponsoredClicks,
            checkIns: checkIns,
          );
        }),
      );

      return activities;
    } catch (e) {
      debugPrint(
          '❌ Erro ao carregar atividade dos estabelecimentos do dono $ownerId: $e');
      return const <_EstablishmentActivity>[];
    }
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 110, maxWidth: 220),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingRow(
    BuildContext context,
    _EstablishmentActivity activity,
    int maxClicks,
  ) {
    final int clicks = activity.clicks;
    final double ratio =
        maxClicks > 0 ? (clicks / maxClicks).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.establishment.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$clicks',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _billingCycleLabel(String billingCycle) {
    switch (billingCycle) {
      case 'quarterly':
        return 'Trimestral';
      case 'Annual':
        return 'Anual';
      default:
        return 'Personalizado';
    }
  }

  String _businessPlanStatusLabel(BusinessPlanStatus status) {
    switch (status) {
      case BusinessPlanStatus.active:
        return 'Ativo';
      case BusinessPlanStatus.pendingApproval:
        return 'Em análise';
      case BusinessPlanStatus.pendingPayment:
        return 'Aguardando pagamento';
      case BusinessPlanStatus.canceled:
        return 'Cancelado';
      case BusinessPlanStatus.none:
      default:
        return 'Inativo';
    }
  }

  Color _businessPlanStatusColor(BusinessPlanStatus status) {
    switch (status) {
      case BusinessPlanStatus.active:
        return Colors.green;
      case BusinessPlanStatus.pendingApproval:
        return Colors.orange;
      case BusinessPlanStatus.pendingPayment:
        return Colors.amber;
      case BusinessPlanStatus.canceled:
      case BusinessPlanStatus.none:
      default:
        return Colors.grey;
    }
  }

  Widget _buildBusinessEventsSection(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: FirebaseService.getGlobalAppConfig(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final appConfig = snapshot.data;
        if (appConfig != null && appConfig['homeFairEnabled'] == false) {
          return const SizedBox.shrink();
        }

        final rawTitle =
            appConfig != null ? appConfig['homeFairTitleText'] : null;
        final rawDescription =
            appConfig != null ? appConfig['homeFairDescriptionText'] : null;
        final rawPrimaryLabel =
            appConfig != null ? appConfig['homeFairPrimaryLabelText'] : null;
        final rawPrimaryUrl =
            appConfig != null ? appConfig['homeFairPrimaryUrl'] : null;
        final rawImageUrl =
            appConfig != null ? appConfig['homeFairImageUrl'] : null;

        String title = Translations.getText(context, 'homeFairTitle');
        if (rawTitle is String && rawTitle.trim().isNotEmpty) {
          title = rawTitle.trim();
        }

        String description =
            Translations.getText(context, 'homeFairDescription');
        if (rawDescription is String && rawDescription.trim().isNotEmpty) {
          description = rawDescription.trim();
        }

        String primaryLabel = Translations.getText(context, 'homeFairButton');
        if (rawPrimaryLabel is String && rawPrimaryLabel.trim().isNotEmpty) {
          primaryLabel = rawPrimaryLabel.trim();
        }

        String? primaryUrl;
        if (rawPrimaryUrl is String && rawPrimaryUrl.trim().isNotEmpty) {
          primaryUrl = rawPrimaryUrl.trim();
        }

        String? imageUrl;
        if (rawImageUrl is String && rawImageUrl.trim().isNotEmpty) {
          imageUrl = rawImageUrl.trim();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.event,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      final urlString = primaryUrl?.isNotEmpty == true
                          ? primaryUrl!
                          : kBusinessFairUrl;
                      final uri = Uri.parse(urlString);
                      try {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              Translations.getText(
                                  context, 'errorOpeningNavigation'),
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(primaryLabel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusinessPitchAndPlans(BuildContext context, User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translations.getText(context, 'businessInstitutionalPitchTitle'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.getText(
                  context, 'businessInstitutionalPitchDescription'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Establishment>>(
              stream: FirebaseService.establishmentsByOwnerStream(user.id),
              builder: (context, estSnapshot) {
                if (estSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final establishments =
                    estSnapshot.data ?? const <Establishment>[];

                // Calcular estatísticas baseadas no planType dos estabelecimentos
                final paidEstablishments =
                    establishments.where((e) => e.planType.isPaid).toList();
                final freeEstablishments =
                    establishments.where((e) => !e.planType.isPaid).toList();

                final int totalEstablishments = establishments.length;
                final int establishmentsWithPlanCount =
                    paidEstablishments.length;
                final int establishmentsWithoutPlanCount =
                    freeEstablishments.length;

                final bool hasAnyPlan = paidEstablishments.isNotEmpty;

                // Verificar se todos estão no plano máximo (Premium)
                final allAtMaxPlan = paidEstablishments.isNotEmpty &&
                    paidEstablishments
                        .every((e) => e.planType == PlanType.premium);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hasAnyPlan)
                      _buildCurrentPlanHeader(context, null)
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.campaign,
                                  color: Colors.green.shade700,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Seus planos de divulgação',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Listar estabelecimentos com plano pago
                            ...paidEstablishments.map((est) {
                              Color planColor;
                              IconData planIcon;
                              switch (est.planType) {
                                case PlanType.premium:
                                  planColor = Colors.purple;
                                  planIcon = Icons.workspace_premium;
                                  break;
                                case PlanType.intermediate:
                                  planColor = Colors.blue;
                                  planIcon = Icons.star;
                                  break;
                                case PlanType.basic:
                                default:
                                  planColor = Colors.green;
                                  planIcon = Icons.check_circle;
                                  break;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(planIcon,
                                          size: 18, color: planColor),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            est.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Plano ${est.planType.label}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: planColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'Ativo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            if (totalEstablishments > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                establishmentsWithoutPlanCount <= 0
                                    ? 'Todos os seus $totalEstablishments estabelecimentos estão com plano ativo. Ótima escolha para destacar sua presença no Prato Seguro.'
                                    : 'Você está anunciando em $establishmentsWithPlanCount de $totalEstablishments estabelecimentos. Ainda há $establishmentsWithoutPlanCount estabelecimento(s) sem plano.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (!hasAnyPlan)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPlanCard(
                              context, user, BusinessPlanType.basic, null),
                          const SizedBox(height: 12),
                          _buildPlanCard(context, user,
                              BusinessPlanType.intermediate, null),
                          const SizedBox(height: 12),
                          _buildPlanCard(
                              context, user, BusinessPlanType.premium, null),
                          const SizedBox(height: 12),
                          _buildPlanCard(
                              context, user, BusinessPlanType.corporate, null),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                _showBusinessPlansTerms(context);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                foregroundColor: Colors.grey.shade600,
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              child:
                                  const Text('Ver termos e política de selos'),
                            ),
                          ),
                        ],
                      )
                    else
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(top: 8),
                        title: Text(
                          establishmentsWithoutPlanCount > 0
                              ? 'Contratar plano para outros estabelecimentos'
                              : 'Ver tabela de planos e condições',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          establishmentsWithoutPlanCount > 0
                              ? 'Você já possui planos ativos e ainda há $establishmentsWithoutPlanCount estabelecimento(s) sem plano.'
                              : 'Confira detalhes dos planos ou ajuste seus anúncios quando quiser.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        children: [
                          _buildPlanCard(
                              context, user, BusinessPlanType.basic, null),
                          const SizedBox(height: 12),
                          _buildPlanCard(context, user,
                              BusinessPlanType.intermediate, null),
                          const SizedBox(height: 12),
                          _buildPlanCard(
                              context, user, BusinessPlanType.premium, null),
                          const SizedBox(height: 12),
                          _buildPlanCard(
                              context, user, BusinessPlanType.corporate, null),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                _showBusinessPlansTerms(context);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                foregroundColor: Colors.grey.shade600,
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              child:
                                  const Text('Ver termos e política de selos'),
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.trending_up,
                    color: Colors.purple.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  Translations.getText(context, 'investorPitchTitle'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              Translations.getText(context, 'investorPitchDescription'),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _launchWhatsApp(
                    context,
                    Translations.getText(
                        context, 'investorPitchWhatsAppMessage'),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  Translations.getText(context, 'investorPitchButton'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanHeader(
      BuildContext context, BusinessPlanSubscription? plan) {
    if (plan == null || plan.status == BusinessPlanStatus.canceled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Você está usando apenas o plano gratuito. Escolha um dos planos abaixo para destacar seus estabelecimentos.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      );
    }

    Color badgeColor;
    String statusLabel;
    switch (plan.status) {
      case BusinessPlanStatus.active:
        badgeColor = Colors.green;
        statusLabel = 'Ativo';
        break;
      case BusinessPlanStatus.pendingApproval:
        badgeColor = Colors.orange;
        statusLabel = 'Em análise';
        break;
      case BusinessPlanStatus.pendingPayment:
        badgeColor = Colors.amber;
        statusLabel = 'Aguardando pagamento';
        break;
      case BusinessPlanStatus.canceled:
      case BusinessPlanStatus.none:
        badgeColor = Colors.grey;
        statusLabel = 'Inativo';
        break;
    }

    final planType = plan.planType;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(planType.icon, color: Colors.green.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plano atual: ${planType.title}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (plan.validUntil != null)
                  Text(
                    'Válido até ${DateFormat('dd/MM/yyyy').format(plan.validUntil!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    User user,
    BusinessPlanType type,
    BusinessPlanSubscription? currentPlan,
  ) {
    final isCurrent = currentPlan != null &&
        currentPlan.planType == type &&
        currentPlan.status != BusinessPlanStatus.canceled;

    Color borderColor;
    Color headerColor;
    switch (type) {
      case BusinessPlanType.basic:
        borderColor = Colors.green.shade200;
        headerColor = Colors.green.shade600;
        break;
      case BusinessPlanType.intermediate:
        borderColor = Colors.blue.shade200;
        headerColor = Colors.blue.shade600;
        break;
      case BusinessPlanType.premium:
        borderColor = AppTheme.premiumGoldLight.withOpacity(0.8);
        headerColor = AppTheme.premiumGoldDark;
        break;
      case BusinessPlanType.corporate:
        borderColor = Colors.purple.shade200;
        headerColor = Colors.purple.shade700;
        break;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: headerColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(type.icon, color: headerColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: headerColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${type.annualPriceLabel} · ${type.quarterPriceLabel}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: headerColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Atual',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: headerColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              type.recommendedFor,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: type.features
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 12)),
                            Expanded(
                              child: Text(
                                f,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade800),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            if (type == BusinessPlanType.corporate)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _launchWhatsApp(
                          context,
                          'Olá! Gostaria de falar sobre o Plano Corporate do Prato Seguro.',
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Falar com o time'),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await _handlePlanRequest(
                            context, user, type, 'quarterly');
                      },
                      child: const Text('Trimestral'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _handlePlanRequest(context, user, type, 'Annual');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: headerColor,
                      ),
                      child: const Text('Anual'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePlanRequest(
    BuildContext context,
    User user,
    BusinessPlanType type,
    String billingCycle,
  ) async {
    try {
      final establishments =
          await FirebaseService.getEstablishmentsByOwner(user.id);
      if (establishments.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Você precisa ter pelo menos um estabelecimento cadastrado para contratar um plano.'),
            ),
          );
        }
        return;
      }

      Establishment? selected;
      if (establishments.length == 1) {
        selected = establishments.first;
      } else {
        selected = await showModalBottomSheet<Establishment>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: type.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(type.icon,
                                    color: type.color, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Contratar ${type.title}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Selecione o estabelecimento',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Lista de estabelecimentos
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: establishments.length,
                        itemBuilder: (context, index) {
                          final est = establishments[index];
                          final currentPlan = est.planType;

                          // Determinar status do upgrade/downgrade
                          String? badgeText;
                          Color? badgeColor;
                          IconData? badgeIcon;
                          bool isUpgrade = false;
                          bool isDowngrade = false;
                          bool isSamePlan = false;

                          // Mapear BusinessPlanType para PlanType para comparação
                          PlanType targetPlanType;
                          switch (type) {
                            case BusinessPlanType.basic:
                              targetPlanType = PlanType.basic;
                              break;
                            case BusinessPlanType.intermediate:
                              targetPlanType = PlanType.intermediate;
                              break;
                            case BusinessPlanType.premium:
                            case BusinessPlanType.corporate:
                              targetPlanType = PlanType.premium;
                              break;
                          }

                          if (currentPlan == targetPlanType) {
                            isSamePlan = true;
                            badgeText = 'Plano atual';
                            badgeColor = Colors.grey;
                            badgeIcon = Icons.check_circle_outline;
                          } else if (currentPlan == PlanType.basic) {
                            isUpgrade = true;
                            if (targetPlanType == PlanType.intermediate) {
                              badgeText = 'Upgrade recomendado';
                              badgeColor = Colors.blue;
                              badgeIcon = Icons.trending_up;
                            } else if (targetPlanType == PlanType.premium) {
                              badgeText = 'Upgrade Premium';
                              badgeColor = Colors.purple;
                              badgeIcon = Icons.workspace_premium;
                            }
                          } else if (currentPlan == PlanType.intermediate) {
                            if (targetPlanType == PlanType.premium) {
                              isUpgrade = true;
                              badgeText = 'Upgrade para Premium';
                              badgeColor = Colors.purple;
                              badgeIcon = Icons.workspace_premium;
                            } else if (targetPlanType == PlanType.basic) {
                              isDowngrade = true;
                              badgeText = 'Trocar plano';
                              badgeColor = Colors.orange;
                              badgeIcon = Icons.swap_horiz;
                            }
                          } else if (currentPlan == PlanType.premium) {
                            isDowngrade = true;
                            badgeText = 'Trocar plano';
                            badgeColor = Colors.orange;
                            badgeIcon = Icons.swap_horiz;
                          }

                          return InkWell(
                            onTap: isSamePlan
                                ? null
                                : () => Navigator.of(context).pop(est),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSamePlan ? Colors.grey.shade100 : null,
                                border: Border(
                                  bottom: BorderSide(
                                      color: Colors.grey.shade200, width: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Ícone do estabelecimento
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isUpgrade
                                          ? badgeColor?.withValues(alpha: 0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.storefront,
                                      color: isUpgrade
                                          ? badgeColor
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Info do estabelecimento
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          est.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                isSamePlan ? Colors.grey : null,
                                          ),
                                        ),
                                        if (est.address != null &&
                                            est.address!.isNotEmpty)
                                          Text(
                                            est.address!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        // Plano atual
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color:
                                                    _getPlanColor(currentPlan)
                                                        .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Atual: ${currentPlan.label}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: _getPlanColor(
                                                      currentPlan),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Badge de upgrade/downgrade
                                  if (badgeText != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isUpgrade
                                            ? badgeColor?.withValues(alpha: 0.1)
                                            : isSamePlan
                                                ? Colors.grey.shade200
                                                : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: isUpgrade
                                            ? Border.all(
                                                color: badgeColor!
                                                    .withValues(alpha: 0.3))
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(badgeIcon,
                                              size: 14, color: badgeColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            badgeText,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: badgeColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

      if (selected == null) {
        return;
      }

      // Verificação de IAP para iOS
      if (Platform.isIOS) {
        String iapProductId;
        switch (type) {
          case BusinessPlanType.basic:
            iapProductId = IapService.productBusinessBasic;
            break;
          case BusinessPlanType.intermediate:
            iapProductId = IapService.productBusinessIntermediate;
            break;
          case BusinessPlanType.premium:
          case BusinessPlanType.corporate:
            iapProductId = IapService.productBusinessPremium;
            break;
        }

        try {
          await IapService().purchaseProduct(
            iapProductId,
            establishmentId: selected.id,
          );
          // O listener no IapService tratará o sucesso
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao processar compra: $e')),
            );
          }
        }
        return;
      }

      Future<void> purchaseBusinessPlanViaIAP({
        required BuildContext context,
        required dynamic selected,
        required dynamic type,
        required String billingCycle,
      }) async {
        if (selected == null) return;

        String iapProductId;

        try {
          switch (type) {
            case BusinessPlanType.basic:
              iapProductId = IapService.productBusinessBasic;
              break;
            case BusinessPlanType.intermediate:
              iapProductId = IapService.productBusinessIntermediate;
              break;
            case BusinessPlanType.premium:
            case BusinessPlanType.corporate:
              iapProductId = IapService.productBusinessPremium;
              break;
            default:
              if (kDebugMode) {
                // ignore: avoid_print
                print('Tipo de plano inesperado (usando fallback).');
              }
              final fallbackId = (type is Map ? type['id'] : (type?.id ?? ''));
              if (fallbackId == '' || fallbackId == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Tipo de plano inválido para compra.')),
                );
                return;
              }
              iapProductId = fallbackId.toString();
          }
        } catch (e) {
          final fallbackId = (type is Map ? type['id'] : (type?.id ?? ''));
          iapProductId = fallbackId?.toString() ?? '';
        }

        if (iapProductId.isEmpty) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Produto não configurado para compra.')),
          );
          return;
        }

        try {
          // Chamada CORRIGIDA: envia apenas o productId (assinatura da função em seu IapService)
          final result = await IapService().purchaseProduct(iapProductId);

          final bool success = result == true;

          if (success) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Pagamento do ${type.title ?? type.toString()} (${billingCycle == 'quarterly' ? 'Trimestral' : 'Anual'}) para o estabelecimento "${selected.name}" aprovado! O plano será aplicado automaticamente em instantes.',
                ),
              ),
            );

            // Opcional: se você quiser associar a compra ao estabelecimento, faça aqui uma chamada
            // separada ao backend enviando establishmentId, planType e billingCycle.
            //
            // Exemplo (adaptar conforme seu auth provider e base URL):
            // final jwt = await authProvider.getJwtToken();
            // await http.post(Uri.parse('$apiBaseUrl/api/payments/register-plan'),
            //   headers: {'Authorization': 'Bearer $jwt', 'Content-Type': 'application/json'},
            //   body: jsonEncode({
            //     'productId': iapProductId,
            //     'establishmentId': selected.id,
            //     'planType': type is Map ? type['id'] : (type?.id ?? type.toString()),
            //     'billingCycle': billingCycle,
            //   }),
            // );
          } else {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'A solicitação de compra foi enviada; verifique seu histórico de compras. Se não foi concluída, tente novamente.',
                ),
              ),
            );
          }
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao processar compra: $e')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao solicitar plano: $e'),
          ),
        );
      }
    }
  }

  void _showBusinessPlansTerms(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.9,
          initialChildSize: 0.8,
          minChildSize: 0.6,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Política de Selos – Prato Seguro',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '🏅 Objetivo dos Selos Prato Seguro',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800, // Removido const
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Os Selos Prato Seguro têm como objetivo informar, orientar e aumentar a segurança de pessoas com restrições alimentares, classificando estabelecimentos de acordo com níveis distintos de verificação e confiabilidade.\n\n'
                    'Os selos não substituem fiscalização sanitária oficial, nem garantem risco zero, mas oferecem camadas progressivas de transparência e confiança.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Estrutura dos Selos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800, // Removido const
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A Prato Seguro adota três níveis de selo, cada um com critérios, responsabilidades e graus de validação distintos:\n'
                    '1. Selo Básico\n'
                    '2. Selo Intermediário\n'
                    '3. Selo Técnico\n\n'
                    'Cada selo é independente e representa um nível diferente de comprovação.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SELO BÁSICO – AVALIAÇÃO DA COMUNIDADE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800, // Removido const
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🔍 O que é\n'
                    'O Selo Básico é concedido com base exclusivamente na experiência real dos usuários da plataforma.\n\n'
                    'Ele reflete a percepção da comunidade sobre o cuidado, atendimento e transparência do estabelecimento em relação às restrições alimentares.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📌 Critérios de Concessão\n'
                    '• Avaliações feitas por usuários cadastrados;\n'
                    '• Notas e comentários relacionados à segurança alimentar;\n'
                    '• Histórico de avaliações positivas recorrentes;\n'
                    '• Ausência de denúncias graves não resolvidas.\n\n'
                    '📊 O selo pode ser dinâmico, variando conforme novas avaliações.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ Limitações Importantes\n'
                    '• O Selo Básico não envolve análise técnica ou documental;\n'
                    '• Baseia-se apenas na experiência subjetiva dos usuários;\n'
                    '• Não garante ausência de contaminação cruzada.\n\n'
                    '📌 Por isso, deve ser interpretado como indicador de confiança comunitária, e não certificação técnica.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SELO INTERMEDIÁRIO – DOCUMENTAÇÃO DO ESTABELECIMENTO',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800, // Removido const
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🔍 O que é\n'
                    'O Selo Intermediário é concedido quando o estabelecimento envia documentação própria, declarando e comprovando práticas relacionadas à segurança alimentar.\n\n'
                    'Esse selo representa um compromisso formal do estabelecimento com boas práticas.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📄 Documentação Avaliada\n'
                    'Podem ser solicitados, entre outros:\n'
                    '• Alvará de funcionamento;\n'
                    '• Licença sanitária vigente;\n'
                    '• Declarações internas sobre:\n'
                    '  - manipulação de alimentos;\n'
                    '  - controle de alergênicos;\n'
                    '  - separação de utensílios;\n'
                    '• Procedimentos internos documentados;\n'
                    '• Certificados ou treinamentos internos da equipe (quando houver).',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🛠️ Processo\n'
                    '1. Envio dos documentos pelo aplicativo ou painel do estabelecimento;\n'
                    '2. Análise documental pela equipe da Prato Seguro;\n'
                    '3. Validação formal do envio e da consistência das informações;\n'
                    '4. Concessão do selo, se aprovado.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ Limitações Importantes\n'
                    '• A análise é documental, não presencial;\n'
                    '• A Prato Seguro não audita fisicamente o local neste nível;\n'
                    '• As informações são de responsabilidade do próprio estabelecimento.\n\n'
                    '📌 O selo indica maior nível de comprometimento, mas ainda não equivale a uma certificação técnica independente.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SELO TÉCNICO – VALIDAÇÃO ESPECIALIZADA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800, // Removido const
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🔍 O que é\n'
                    'O Selo Técnico é o nível mais alto de verificação da Prato Seguro.\n\n'
                    'Ele é concedido apenas a estabelecimentos que apresentam embasamento técnico comprovado, podendo envolver testes laboratoriais, laudos técnicos e validações especializadas.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🧪 Critérios Técnicos\n'
                    'Podem ser exigidos:\n'
                    '• Laudos laboratoriais de ausência ou controle de alergênicos;\n'
                    '• Testes específicos (ex.: glúten, lactose, proteínas do leite);\n'
                    '• Relatórios técnicos assinados por profissionais habilitados;\n'
                    '• Certificações externas reconhecidas;\n'
                    '• Protocolos rígidos de prevenção de contaminação cruzada.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '👨‍🔬 Avaliação\n'
                    '• Análise técnica aprofundada da documentação;\n'
                    '• Possível validação por parceiros técnicos ou especialistas;\n'
                    '• Revisão periódica, conforme critérios definidos pela plataforma.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ Limitações Importantes\n'
                    '• Mesmo com o Selo Técnico, não existe risco zero;\n'
                    '• O selo reflete o estado do estabelecimento no momento da avaliação;\n'
                    '• Mudanças de processos podem impactar a validade do selo.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '3. Atualização, Suspensão e Perda de Selos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800, // Removido const
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A Prato Seguro se reserva o direito de:\n'
                    '• revisar selos periodicamente;\n'
                    '• suspender ou remover selos em caso de:\n'
                    '  - denúncias relevantes;\n'
                    '  - inconsistência de informações;\n'
                    '  - documentos vencidos;\n'
                    '  - descumprimento dos critérios.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '4. Transparência com o Usuário',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800, // Removido const
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Em todos os casos:\n'
                    '• O tipo de selo será claramente identificado no app e no site;\n'
                    '• O usuário poderá consultar:\n'
                    '  - o significado de cada selo;\n'
                    '  - seus critérios e limitações;\n\n'
                    'A plataforma incentiva decisões conscientes e informadas.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '5. Isenção de Responsabilidade',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800, // Removido const
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Os selos da Prato Seguro:\n'
                    '• não substituem fiscalização sanitária oficial;\n'
                    '• não garantem segurança absoluta;\n'
                    '• servem como ferramenta informativa e de apoio à decisão.\n\n'
                    'A responsabilidade final pela escolha do consumo permanece com o usuário.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickStats(BuildContext context, String userId) {
    return StreamBuilder<List<Establishment>>(
      stream: FirebaseService.establishmentsByOwnerStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final establishments = snapshot.data!;
        if (establishments.isEmpty) {
          return const SizedBox.shrink();
        }

        // Calcular estatísticas
        int totalEstablishments = establishments.length;
        int openEstablishments = establishments.where((e) => e.isOpen).length;
        double avgRating = 0.0;
        int totalReviews = 0;

        // TODO: Calcular média de avaliações quando tiver ReviewProvider integrado

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.restaurant,
                label: Translations.getText(context, 'totalEstablishments'),
                value: totalEstablishments.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.access_time,
                label: Translations.getText(context, 'openNow'),
                value: openEstablishments.toString(),
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.star,
                label: Translations.getText(context, 'averageRating'),
                value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '-',
                color: Colors.amber,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstablishmentsList(BuildContext context, String userId) {
    return StreamBuilder<List<Establishment>>(
      stream: FirebaseService.establishmentsByOwnerStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final establishments = snapshot.data!;

        if (establishments.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.restaurant, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    Translations.getText(context, 'noEstablishmentsRegistered'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const BusinessRegisterEstablishmentScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(
                        Translations.getText(context, 'registerEstablishment')),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    Translations.getText(context, 'registeredEstablishments'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const BusinessRegisterEstablishmentScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label:
                      Text(Translations.getText(context, 'add') ?? 'Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...establishments.map((establishment) {
              // Determinar label e cor do plano
              String planLabel;
              Color planColor;
              switch (establishment.planType) {
                case PlanType.premium:
                  planLabel = 'Premium';
                  planColor = Colors.purple;
                  break;
                case PlanType.intermediate:
                  planLabel = 'Intermediário';
                  planColor = Colors.blue;
                  break;
                case PlanType.basic:
                default:
                  planLabel = 'Gratuito';
                  planColor = Colors.grey;
                  break;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: establishment.avatarUrl.isNotEmpty
                        ? NetworkImage(establishment.avatarUrl)
                        : null,
                    child: establishment.avatarUrl.isEmpty
                        ? const Icon(Icons.restaurant)
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(establishment.name)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: planColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: planColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          planLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: planColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(CategoryTranslator.translate(
                      context, establishment.category)),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BusinessManageEstablishmentScreen(
                            establishment: establishment,
                          ),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BusinessManageEstablishmentScreen(
                          establishment: establishment,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _EstablishmentActivity {
  final Establishment establishment;
  final int clicks;
  final int organicClicks;
  final int sponsoredClicks;
  final int checkIns;

  const _EstablishmentActivity({
    required this.establishment,
    required this.clicks,
    required this.organicClicks,
    required this.sponsoredClicks,
    required this.checkIns,
  });
}

class BusinessManageEstablishmentScreen extends StatelessWidget {
  final Establishment establishment;

  const BusinessManageEstablishmentScreen({
    super.key,
    required this.establishment,
  });

  @override
  Widget build(BuildContext context) {
    // Usar StreamBuilder para atualização em tempo real do estabelecimento
    return StreamBuilder<Establishment?>(
      stream: FirebaseService.establishmentStream(establishment.id),
      initialData: establishment,
      builder: (context, snapshot) {
        final currentEstablishment = snapshot.data ?? establishment;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(currentEstablishment.name),
              bottom: TabBar(
                tabs: [
                  Tab(
                      icon: Icon(Icons.info),
                      text: Translations.getText(context, 'basicInformation')),
                  Tab(
                      icon: Icon(Icons.reviews),
                      text: Translations.getText(context, 'reviewsTab')),
                  Tab(
                      icon: Icon(Icons.restaurant_menu),
                      text:
                          Translations.getText(context, 'menu') ?? 'Cardápio'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // Tab de Informações
                _buildInfoTab(context, currentEstablishment),
                // Tab de Avaliações
                _buildReviewsTab(context, currentEstablishment),
                // Tab de Cardápio
                _buildMenuTab(context, currentEstablishment),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _requestTechnicalCertification(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                Translations.getText(context, 'certificationRequestError') ??
                    'Erro ao solicitar certificação'),
          ),
        );
        return;
      }

      await FirebaseService.createCertificationRequest(
        establishmentId: establishment.id,
        establishmentName: establishment.name,
        ownerId: user.id,
        ownerName: user.name ?? '',
      );

      await FirebaseService.updateEstablishment(establishment.id, {
        'certificationStatus': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              Translations.getText(context, 'certificationRequestSent') ??
                  'Solicitação de certificação enviada com sucesso'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              Translations.getText(context, 'certificationRequestError') ??
                  'Erro ao solicitar certificação'),
        ),
      );
    }
  }

  Widget _buildInfoTab(BuildContext context, Establishment establishment) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto do estabelecimento
          Center(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: establishment.avatarUrl.isNotEmpty
                      ? Image.network(
                          establishment.avatarUrl,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.restaurant, size: 80),
                          ),
                        )
                      : Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.restaurant, size: 80),
                        ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: FloatingActionButton.small(
                    onPressed: () async {
                      final result = await Navigator.of(context).push<String?>(
                        MaterialPageRoute(
                          builder: (_) =>
                              BusinessManageEstablishmentPhotosScreen(
                            establishment: establishment,
                          ),
                        ),
                      );

                      if (result == 'scrollToPlans') {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);

                        ScrollBus.notifier.value = 'plans';
                      }
                    },
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (user != null && user.type == UserType.business) ...[
            _buildPlanStatusCard(establishment),
          ],
          // Informações básicas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translations.getText(context, 'basicInformation'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildInfoRow(Translations.getText(context, 'name'),
                      establishment.name),
                  _buildInfoRow(
                      Translations.getText(context, 'category'),
                      CategoryTranslator.translate(
                          context, establishment.category)),
                  _buildInfoRow(Translations.getText(context, 'address'),
                      Translations.getText(context, 'toDefine')),
                  _buildInfoRow(
                      Translations.getText(context, 'status'),
                      establishment.isOpen
                          ? Translations.getText(context, 'open')
                          : Translations.getText(context, 'closed')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translations.getText(context, 'technicalCertification'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  Text(
                    Translations.getText(
                        context, 'technicalCertificationDescription'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Translations.getText(
                            context, 'certificationStatusLabel'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        establishment.certificationStatus.getLabel(context),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: establishment.certificationStatus ==
                                  TechnicalCertificationStatus.certified
                              ? Colors.green
                              : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _requestTechnicalCertification(context);
                      },
                      icon: const Icon(Icons.verified_outlined),
                      label: Text(Translations.getText(
                              context, 'requestTechnicalCertification') ??
                          'Solicitar certificação técnica'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final baseMessage = Translations.getText(
                            context, 'technicalCertificationWhatsAppMessage');
                        final fullMessage =
                            '$baseMessage\nEstabelecimento: ${establishment.name}';
                        await _launchWhatsApp(context, fullMessage);
                      },
                      icon: const Icon(Icons.chat),
                      label:
                          Text(Translations.getText(context, 'talkOnWhatsApp')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translations.getText(context, 'activity') ??
                        'Atividade no app',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  FutureBuilder<Map<String, int>>(
                    future: FirebaseService.getEstablishmentActivityStats(
                        establishment.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(),
                        );
                      }

                      final data =
                          snapshot.data ?? const {'checkIns': 0, 'clicks': 0};
                      final checkIns = data['checkIns'] ?? 0;
                      final clicks = data['clicks'] ?? 0;

                      final checkInsLabel = checkIns == 1
                          ? '1 check-in registrado neste estabelecimento'
                          : '$checkIns check-ins registrados neste estabelecimento';
                      final clicksLabel = clicks == 1
                          ? '1 clique para abrir os detalhes deste estabelecimento'
                          : '$clicks cliques para abrir os detalhes deste estabelecimento';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            checkInsLabel,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            clicksLabel,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botão de editar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BusinessRegisterEstablishmentScreen(
                      existingEstablishment: establishment,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: Text(Translations.getText(context, 'editInformation')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanStatusCard(Establishment establishment) {
    final hasPaidPlan = establishment.planType.isPaid;

    if (!hasPaidPlan) {
      // Plano gratuito
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Este estabelecimento está no plano gratuito. Contrate um plano para liberar fotos, insights e mais visibilidade.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      );
    }

    // Plano pago ativo
    Color planColor;
    IconData planIcon;
    switch (establishment.planType) {
      case PlanType.premium:
        planColor = Colors.purple;
        planIcon = Icons.workspace_premium;
        break;
      case PlanType.intermediate:
        planColor = Colors.blue;
        planIcon = Icons.star;
        break;
      case PlanType.basic:
      default:
        planColor = Colors.green;
        planIcon = Icons.check_circle;
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: planColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: planColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(planIcon, size: 18, color: planColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plano ${establishment.planType.label} ativo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: planColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Até ${establishment.planType.maxEstablishmentPhotos} fotos • Insights liberados',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Ativo',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(BuildContext context, Establishment establishment) {
    // Verificar se o estabelecimento tem plano pago
    final hasActivePlan = establishment.planType.isPaid;

    // Se não tem plano pago, mostrar versão bloqueada
    if (!hasActivePlan) {
      return _buildLockedReviewsTab(context, establishment);
    }

    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        // Carregar avaliações do Firestore se necessário
        WidgetsBinding.instance.addPostFrameCallback((_) {
          reviewProvider.loadReviewsForEstablishment(establishment.id);
        });

        final reviews =
            reviewProvider.getReviewsForEstablishment(establishment.id);
        final averageRating = reviewProvider.getAverageRating(establishment.id);
        final reviewCount = reviewProvider.getReviewCount(establishment.id);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumo de avaliações
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 32),
                              const SizedBox(width: 8),
                              Text(
                                averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$reviewCount ${reviewCount == 1 ? 'avaliação' : 'avaliações'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Lista de avaliações
              if (reviews.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.reviews,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          Translations.getText(context, 'noReviews'),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...reviews.map((review) => ReviewCard(review: review)),
            ],
          ),
        );
      },
    );
  }

  /// Tab de avaliações bloqueada para usuários sem plano pago
  Widget _buildLockedReviewsTab(
      BuildContext context, Establishment establishment) {
    // Determinar texto do botão baseado no plano atual
    String buttonText;
    String subtitle;
    if (establishment.planType == PlanType.basic) {
      buttonText = 'Fazer Upgrade para Intermediário';
      subtitle =
          'Seu estabelecimento está no plano Inicial. Faça upgrade para acessar avaliações e muito mais!';
    } else {
      buttonText = 'Contratar Plano';
      subtitle =
          'Contrate um plano para acessar todas as avaliações, responder aos clientes e melhorar sua reputação.';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card de resumo borrado
          Stack(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star,
                                  color: Colors.grey.shade300, size: 32),
                              const SizedBox(width: 8),
                              Container(
                                width: 50,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Avaliações falsas borradas
          ...List.generate(3, (index) => _buildBlurredReviewCard()),

          const SizedBox(height: 24),

          // CTA para upgrade
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    size: 40,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Veja o que seus clientes dizem!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildReviewFeature(Icons.visibility, 'Ver avaliações'),
                    const SizedBox(width: 24),
                    _buildReviewFeature(Icons.reply, 'Responder'),
                    const SizedBox(width: 24),
                    _buildReviewFeature(Icons.trending_up, 'Melhorar nota'),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Voltar para o dashboard (fecha a tela de gerenciamento)
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildBlurredReviewCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar borrado
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome borrado
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Estrelas borradas
                    Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.grey.shade300,
                              )),
                    ),
                  ],
                ),
              ),
              // Data borrada
              Container(
                width: 60,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Texto borrado
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 200,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewFeature(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.amber.shade700),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTab(BuildContext context, Establishment establishment) {
    return StreamBuilder<List<MenuItem>>(
      stream: FirebaseService.menuItemsStream(establishment.id),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final items = snapshot.data ?? const <MenuItem>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Translations.getText(context, 'menuDishes'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BusinessEditMenuItemScreen(
                                    establishmentId: establishment.id,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add, size: 20),
                            label: Text(
                                Translations.getText(context, 'addDish') ??
                                    'Adicionar Prato'),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (isLoading && items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (items.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Icon(Icons.restaurant_menu,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  Translations.getText(
                                      context, 'noDishesRegistered'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              leading: item.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.imageUrl,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 56,
                                          height: 56,
                                          color: Colors.grey.shade200,
                                          child:
                                              const Icon(Icons.restaurant_menu),
                                        ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: Colors.grey.shade200,
                                      child: const Icon(Icons.restaurant_menu,
                                          color: Colors.grey),
                                    ),
                              title: Text(item.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'R\$ ${item.price.toStringAsFixed(2).replaceAll('.', ',')}'),
                                  if (!item.isAvailable)
                                    Text(
                                      'Indisponível',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  if (item.dietaryOptions.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Wrap(
                                        spacing: 4,
                                        runSpacing: -8,
                                        children:
                                            item.dietaryOptions.map((filter) {
                                          return Chip(
                                            label: Text(
                                              filter.getLabel(context),
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BusinessEditMenuItemScreen(
                                            establishmentId: establishment.id,
                                            existingItem: item,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Remover prato'),
                                          content: Text(
                                              'Tem certeza que deseja remover o prato "${item.name}" do cardápio?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: const Text('Remover'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        try {
                                          await FirebaseService.deleteMenuItem(
                                            establishment.id,
                                            item.id,
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Prato "${item.name}" removido do cardápio.'),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Erro ao remover prato: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
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
            ],
          ),
        );
      },
    );
  }
}

class BusinessManageEstablishmentPhotosScreen extends StatefulWidget {
  final Establishment establishment;

  const BusinessManageEstablishmentPhotosScreen({
    super.key,
    required this.establishment,
  });

  @override
  State<BusinessManageEstablishmentPhotosScreen> createState() =>
      _BusinessManageEstablishmentPhotosScreenState();
}

class _BusinessManageEstablishmentPhotosScreenState
    extends State<BusinessManageEstablishmentPhotosScreen> {
  final ImagePicker _picker = ImagePicker();
  late List<String> _existingUrls;
  final List<File> _newPhotos = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _existingUrls = List<String>.from(widget.establishment.photoUrls);
  }

  int _getMaxPhotos() {
    // Usar o planType do estabelecimento diretamente
    return widget.establishment.planType.maxEstablishmentPhotos;
  }

  bool _hasActivePlan() {
    // Verificar se o estabelecimento tem plano pago
    return widget.establishment.planType.isPaid;
  }

  Future<void> _showUpgradeModal() async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_camera,
                size: 40,
                color: Colors.amber.shade700,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Destaque seu estabelecimento!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Adicione fotos do seu estabelecimento para atrair mais clientes. Fotos são exclusivas para assinantes dos planos pagos.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                children: [
                  _buildPlanFeature(Icons.photo, 'Plano Inicial', '1 foto'),
                  const SizedBox(height: 8),
                  _buildPlanFeature(Icons.photo_library, 'Plano Intermediário',
                      'até 5 fotos'),
                  const SizedBox(height: 8),
                  _buildPlanFeature(
                      Icons.collections, 'Plano Profissional', 'até 10 fotos'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // Fecha apenas o modal retornando um sinal para a tela de fotos
                  Navigator.of(context).pop('goPlans');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Ver Planos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Agora não',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );

    // Se o modal retornou 'goPlans', feche a tela de fotos e envie 'scrollToPlans' ao dashboard
    if (result == 'goPlans') {
      Navigator.of(context).pop('scrollToPlans');
    }
  }

  Widget _buildPlanFeature(IconData icon, String plan, String feature) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            plan,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          feature,
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _scrollToPlans() {
    // Voltar para o dashboard e rolar para planos
    Navigator.of(context).popUntil((route) => route.isFirst);
    // O scroll será feito pelo dashboard
  }

  int get _totalSelected => _existingUrls.length + _newPhotos.length;

  Future<void> _addFromGallery() async {
    if (_isSaving) return;

    // Verificar se tem plano ativo
    if (!_hasActivePlan()) {
      _showUpgradeModal();
      return;
    }

    final maxPhotos = _getMaxPhotos();
    if (_totalSelected >= maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Seu plano atual permite apenas ${maxPhotos == 1 ? "1 foto" : "$maxPhotos fotos"} por estabelecimento.',
          ),
        ),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _newPhotos.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addFromCamera() async {
    if (_isSaving) return;

    // Verificar se tem plano ativo
    if (!_hasActivePlan()) {
      _showUpgradeModal();
      return;
    }

    final maxPhotos = _getMaxPhotos();
    if (_totalSelected >= maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Seu plano atual permite apenas ${maxPhotos == 1 ? "1 foto" : "$maxPhotos fotos"} por estabelecimento.',
          ),
        ),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _newPhotos.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao capturar imagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      List<String> finalUrls = List<String>.from(_existingUrls);
      if (_newPhotos.isNotEmpty) {
        final newUrls = await FirebaseService.uploadEstablishmentPhotos(
          _newPhotos,
          widget.establishment.id,
        );
        finalUrls.addAll(newUrls);
      }

      // Revalidar limite do plano antes de salvar
      final maxPhotos = _getMaxPhotos();
      if (finalUrls.length > maxPhotos) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Seu plano atual permite até ${maxPhotos == 1 ? "1 foto" : "$maxPhotos fotos"} por estabelecimento. Remova algumas fotos antes de salvar.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await FirebaseService.updateEstablishmentPhotos(
        widget.establishment.id,
        finalUrls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotos atualizadas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar fotos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxPhotos = _getMaxPhotos();
    final totalSelected = _totalSelected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos do estabelecimento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fotos selecionadas: $totalSelected/$maxPhotos',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _addFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeria'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _addFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Câmera'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _existingUrls.isEmpty && _newPhotos.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma foto cadastrada ainda.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: _existingUrls.length + _newPhotos.length,
                      itemBuilder: (context, index) {
                        final bool isExisting = index < _existingUrls.length;
                        Widget imageWidget;
                        if (isExisting) {
                          final url = _existingUrls[index];
                          imageWidget = Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image),
                            ),
                          );
                        } else {
                          final fileIndex = index - _existingUrls.length;
                          final file = _newPhotos[fileIndex];
                          imageWidget = Image.file(
                            file,
                            fit: BoxFit.cover,
                          );
                        }

                        return Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageWidget,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: _isSaving
                                    ? null
                                    : () {
                                        setState(() {
                                          if (isExisting) {
                                            _existingUrls.removeAt(index);
                                          } else {
                                            final fileIndex =
                                                index - _existingUrls.length;
                                            _newPhotos.removeAt(fileIndex);
                                          }
                                        });
                                      },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _launchWhatsApp(BuildContext context, String message) async {
  const phone = '5541996243262';
  final encodedMessage = Uri.encodeComponent(message);
  final uri = Uri.parse('https://wa.me/$phone?text=$encodedMessage');

  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Não foi possível abrir o WhatsApp: $e'),
      ),
    );
  }
}
