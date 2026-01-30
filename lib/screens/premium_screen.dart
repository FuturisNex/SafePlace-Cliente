import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../utils/translations.dart';
import '../theme/app_theme.dart';
import '../services/iap_service.dart';
import '../services/iap_restore_service.dart';
import '../services/payment_service.dart';

enum PlanTier { free, quarterly, yearly }

class PremiumPlan {
  final String productId;
  final String title;
  final String description;
  final double price;
  final String period;
  final List<String> benefits;
  final PlanTier tier;

  PremiumPlan({
    required this.productId,
    required this.title,
    required this.description,
    required this.price,
    required this.period,
    required this.benefits,
    required this.tier,
  });
}

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _loading = false;
  bool _restoring = false;

  final List<PremiumPlan> plans = [
    PremiumPlan(
      productId: 'premium_quarterly',
      title: 'Plano Trimestral',
      description: 'Ideal para testar todos os recursos',
      price: 9.90,
      period: 'Cobrança Trimestral',
      tier: PlanTier.quarterly,
      benefits: [
        'Acesso total aos recursos',
        'Filtros avançados',
      ],
    ),
    PremiumPlan(
      productId: 'premium_yearly',
      title: 'Plano Anual',
      description: 'Economize mais no longo prazo',
      price: 99.90,
      period: 'Cobrança anual',
      tier: PlanTier.yearly,
      benefits: [
        'Tudo do plano Trimestral',
        'Melhor custo-benefício',
        'Prioridade em novidades',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(user),
              const SizedBox(height: 24),
              _buildBenefits(),
              const SizedBox(height: 32),
              ...plans.map(
                (plan) => _PremiumPlanCard(
                  plan: plan,
                  currentTier: user.isPremiumActive ? PlanTier.yearly : PlanTier.free,
                  recommended: plan.tier == PlanTier.yearly,
                  loading: _loading,
                  onSelect: () => _purchase(plan),
                ),
              ),
              const SizedBox(height: 24),

              // Botão de restaurar compras adicionado aqui (antes do footer)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                child: Center(
                  child: ElevatedButton.icon(
                    icon: _restoring
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.restore),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(_restoring ? 'Restaurando...' : 'Restaurar compras'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.premiumBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _restoring ? null : _restorePurchases,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              _buildFooterLinks(),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 HEADER
  Widget _buildHeader(User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.premiumBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.star, size: 36, color: AppTheme.premiumBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.isPremiumActive ? 'Premium ativo' : 'Conta gratuita',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.isPremiumActive
                      ? 'Sua assinatura está ativa'
                      : 'Desbloqueie todos os recursos premium',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 BENEFÍCIOS
  Widget _buildBenefits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'O que você desbloqueia',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...[
          'Acesso antecipado a locais certificados',
          Translations.getText(context, 'advancedFilters'),
          'Notificações exclusivas',
          'Cupons especiais',
          'Selo Premium no perfil',
        ].map(
          (text) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.premiumBlue, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(text)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🔹 FOOTER LINKS
  Widget _buildFooterLinks() {
    return Center(
      child: Wrap(
        spacing: 24,
        children: const [
          Text(
            'Política de Privacidade',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              decoration: TextDecoration.underline,
            ),
          ),
          Text(
            'Termos de Uso',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 COMPRA
  Future<void> _purchase(PremiumPlan plan) async {
    if (_loading) return;

    // Obter usuário
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    
    if (user == null || user.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não autenticado')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await _paymentService.buyProductByLogicalKey(
        plan.productId,
        userId: user.id,
      );
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produto não disponível. Tente novamente.'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compra iniciada — complete na loja.')),
          );
        }
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao iniciar compra: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 🔹 RESTAURAR COMPRAS (usa IAPRestoreService agora)
  Future<void> _restorePurchases() async {
    if (_restoring) return;

    setState(() => _restoring = true);
    try {
      final success = await IAPRestoreService.restorePurchases();
      if (mounted) {
        if (success == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restauração iniciada. Verifique compras em sua conta.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível iniciar a restauração.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao restaurar compras: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }
}

/* ============================================================
   CARD DE PLANO (REUTILIZÁVEL)
============================================================ */

class _PremiumPlanCard extends StatelessWidget {
  final PremiumPlan plan;
  final PlanTier currentTier;
  final VoidCallback onSelect;
  final bool recommended;
  final bool loading;

  const _PremiumPlanCard({
    required this.plan,
    required this.currentTier,
    required this.onSelect,
    required this.recommended,
    required this.loading,
  });

  bool get isCurrent => plan.tier == currentTier;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: recommended ? AppTheme.premiumBlue : Colors.grey.shade300,
          width: recommended ? 2 : 1,
        ),
        color: recommended ? AppTheme.premiumBlue.withOpacity(0.04) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.premiumBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Mais vantajoso',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            plan.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(plan.description, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          Text(
            'R\$ ${plan.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.premiumBlue,
            ),
          ),
          Text(plan.period, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ...plan.benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.check, size: 18, color: AppTheme.premiumBlue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(b)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent || loading ? null : onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? Colors.grey.shade400 : AppTheme.premiumBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isCurrent ? 'Plano atual' : 'Assinar agora',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
