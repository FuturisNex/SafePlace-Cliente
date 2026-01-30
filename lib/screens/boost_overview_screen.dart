import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/establishment.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_provider.dart';
import '../services/boost_service.dart';
import '../theme/app_theme.dart';
import 'boost_insights_screen.dart';

class BoostOverviewScreen extends StatefulWidget {
  const BoostOverviewScreen({super.key});

  @override
  State<BoostOverviewScreen> createState() => _BoostOverviewScreenState();
}

class _BoostOverviewScreenState extends State<BoostOverviewScreen> {
  List<Map<String, dynamic>> _campaigns = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedEstablishmentId;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) {
      debugPrint('❌ BoostOverview: user is null');
      return;
    }

    debugPrint('🔄 BoostOverview: Carregando campanhas para user.id=${user.id}');

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final campaigns = await BoostService.getCampaigns(user.id);
      debugPrint('✅ BoostOverview: ${campaigns.length} campanhas carregadas');
      for (final c in campaigns) {
        debugPrint('   - Campanha: ${c['id']} | status=${c['status']} | budget=${c['totalBudget']}');
      }
      if (mounted) {
        setState(() {
          _campaigns = campaigns;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ BoostOverview: Erro ao carregar campanhas: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredCampaigns {
    if (_selectedEstablishmentId == null) return _campaigns;
    return _campaigns.where((c) => c['establishmentId'] == _selectedEstablishmentId).toList();
  }

  // Cor de fundo consistente com Meus Estabelecimentos
  static const Color _bgColor = Color(0xFFF7F8FA);

  @override
  Widget build(BuildContext context) {
    final establishmentProvider = Provider.of<EstablishmentProvider>(context);
    final establishments = establishmentProvider.establishments;

    return Container(
      color: _bgColor,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(establishments),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar campanhas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCampaigns,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Establishment> establishments) {
    final now = DateTime.now();
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const navApproxHeight = 96.0;

    final campaignEstablishmentIds = _campaigns
        .map((c) => c['establishmentId'] as String?)
        .whereType<String>()
        .toSet();
    final boostedEstablishments = establishments
        .where((e) => campaignEstablishmentIds.contains(e.id))
        .toList();

    final activeCampaigns = _filteredCampaigns.where((c) {
      final status = c['status'] as String? ?? 'inactive';
      final endTs = c['endDate'];
      DateTime? endDate;
      if (endTs is Timestamp) endDate = endTs.toDate();
      if (endTs is String) endDate = DateTime.tryParse(endTs);
      return status == 'active' && (endDate == null || endDate.isAfter(now));
    }).toList();

    final totalBudget = _filteredCampaigns.fold<double>(
        0, (sum, c) => sum + ((c['totalBudget'] as num?)?.toDouble() ?? 0));

    double remainingTotal = 0;
    for (final c in _filteredCampaigns) {
      remainingTotal += _calculateRemainingBudget(c);
    }

    return Column(
      children: [
        // Card de título fixo (não rola)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _buildTitleCard(remainingTotal, totalBudget, activeCampaigns.length),
        ),
        // Lista de campanhas (rola)
        Expanded(
          child: _filteredCampaigns.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _loadCampaigns,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + navApproxHeight + 80),
                    itemCount: _filteredCampaigns.length + (boostedEstablishments.length > 1 ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Filtro de estabelecimento como primeiro item
                      if (boostedEstablishments.length > 1 && index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: _selectedEstablishmentId,
                                isExpanded: true,
                                hint: const Text('Filtrar por estabelecimento'),
                                icon: const Icon(Icons.filter_list),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Todos os estabelecimentos'),
                                  ),
                                  ...boostedEstablishments.map((e) => DropdownMenuItem<String?>(
                                        value: e.id,
                                        child: Text(e.name, overflow: TextOverflow.ellipsis),
                                      )),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedEstablishmentId = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        );
                      }
                      
                      final campaignIndex = boostedEstablishments.length > 1 ? index - 1 : index;
                      final campaign = _filteredCampaigns[campaignIndex];
                      return _buildCampaignCard(context, campaign, boostedEstablishments);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // Card de título compacto (igual ao de Meus Estabelecimentos)
  Widget _buildTitleCard(double remainingTotal, double totalBudget, int activeCount) {
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
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
                      'Impulsionamento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Acompanhe suas campanhas',
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
          const SizedBox(height: 16),
          // Resumo em linha
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItemCompact(
                    'Saldo',
                    'R\$ ${remainingTotal.toStringAsFixed(2)}',
                    Icons.account_balance_wallet_outlined,
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.white24),
                Expanded(
                  child: _buildStatItemCompact(
                    'Investido',
                    'R\$ ${totalBudget.toStringAsFixed(2)}',
                    Icons.trending_up_rounded,
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.white24),
                Expanded(
                  child: _buildStatItemCompact(
                    'Ativas',
                    '$activeCount',
                    Icons.play_circle_outline_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatItemCompact(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCampaignCard(
    BuildContext context,
    Map<String, dynamic> campaign,
    List<Establishment> establishments,
  ) {
    final status = campaign['status'] as String? ?? 'inactive';
    final isActive = status == 'active';
    final totalBudget = (campaign['totalBudget'] as num?)?.toDouble() ?? 0;
    final dailyBudget = (campaign['dailyBudget'] as num?)?.toDouble() ?? 0;
    final remaining = _calculateRemainingBudget(campaign);

    final estId = campaign['establishmentId'] as String?;
    final establishment = establishments.where((e) => e.id == estId).firstOrNull;
    final estName = establishment?.name ?? 'Estabelecimento';
    final hasAvatar = establishment?.avatarUrl.isNotEmpty ?? false;

    DateTime? endDate;
    final endTs = campaign['endDate'];
    if (endTs is Timestamp) endDate = endTs.toDate();
    if (endTs is String) endDate = DateTime.tryParse(endTs);

    final daysLeft = endDate != null ? endDate.difference(DateTime.now()).inDays : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppTheme.primaryGreen.withOpacity(0.3) : Colors.grey.shade200,
          width: isActive ? 1.5 : 1,
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
          onTap: () async {
            if (establishment != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BoostInsightsScreen(
                    campaignId: campaign['id'] as String,
                    establishment: establishment,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar / Imagem do estabelecimento
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: hasAvatar ? null : const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(14),
                    image: hasAvatar
                        ? DecorationImage(
                            image: NetworkImage(establishment!.avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: hasAvatar
                      ? null
                      : Center(
                          child: Icon(
                            Icons.rocket_launch_rounded,
                            color: isActive ? AppTheme.primaryGreen : const Color(0xFF64748B),
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
                              estName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.primaryGreen.withOpacity(0.1)
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isActive ? Icons.bolt_rounded : Icons.pause_rounded,
                                  size: 12,
                                  color: isActive ? AppTheme.primaryGreen : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isActive ? 'Ativa' : 'Pausada',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? AppTheme.primaryGreen : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'R\$ ${remaining.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
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
                          Text(
                            'R\$ ${dailyBudget.toStringAsFixed(2)}/dia',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (daysLeft > 0) ...[
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
                                color: daysLeft <= 3 
                                    ? Colors.red.shade50 
                                    : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$daysLeft dias',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: daysLeft <= 3 
                                      ? Colors.red.shade700 
                                      : const Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch, size: 64, color: AppTheme.primaryGreen.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text(
              'Ainda não há campanhas de impulsionamento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crie uma campanha a partir do seu dashboard para ver aqui os resultados em tempo real.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double totalBudget, double remaining, int activeCount) {
    final spent = (totalBudget - remaining).clamp(0, totalBudget);
    final percent = totalBudget > 0 ? spent / totalBudget : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo de Investimento',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'R\$ ${remaining.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Saldo de campanhas',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${spent.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$activeCount campanhas ativas',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 1),
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignTile(BuildContext context, Map<String, dynamic> campaign) {
    final status = campaign['status'] as String? ?? 'inactive';
    final isActive = status == 'active';
    final totalBudget = (campaign['totalBudget'] as num?)?.toDouble() ?? 0;
    final dailyBudget = (campaign['dailyBudget'] as num?)?.toDouble() ?? 0;
    final remaining = _calculateRemainingBudget(campaign);

    DateTime? endDate;
    final endTs = campaign['endDate'];
    if (endTs is Timestamp) endDate = endTs.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () async {
          final estId = campaign['establishmentId'] as String?;
          Establishment? est;
          if (estId != null) {
            final snap = await FirebaseFirestore.instance.collection('establishments').doc(estId).get();
            if (snap.exists) {
              final data = snap.data()!;
              est = Establishment.fromJson({
                ...data,
                'id': snap.id,
              });
            }
          }

          if (!context.mounted || est == null) return;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BoostInsightsScreen(
                campaignId: campaign['id'] as String,
                establishment: est!,
              ),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: isActive ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.grey.shade200,
          child: Icon(
            Icons.rocket_launch,
            color: isActive ? AppTheme.primaryGreen : Colors.grey.shade500,
          ),
        ),
        title: Text(
          'R\$ ${totalBudget.toStringAsFixed(2)} • R\$ ${dailyBudget.toStringAsFixed(2)}/dia',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Saldo: R\$ ${remaining.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (endDate != null)
              Text(
                'Até ${_formatDate(endDate)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  double _calculateRemainingBudget(Map<String, dynamic> campaign) {
    final totalBudget = (campaign['totalBudget'] as num?)?.toDouble() ?? 0;
    final spentBudget = (campaign['spentBudget'] as num?)?.toDouble() ?? 0;
    
    // Se tiver spentBudget real (do backend), usar ele
    if (spentBudget > 0) {
      return (totalBudget - spentBudget).clamp(0, totalBudget);
    }
    
    // Fallback: estimativa baseada em tempo (para campanhas antigas)
    final dailyBudget = (campaign['dailyBudget'] as num?)?.toDouble() ?? 0;

    try {
      final startTs = campaign['startDate'];
      final endTs = campaign['endDate'];
      
      DateTime? startDate;
      DateTime? endDate;
      
      if (startTs is Timestamp) {
        startDate = startTs.toDate();
      } else if (startTs is String) {
        startDate = DateTime.tryParse(startTs);
      }
      
      if (endTs is Timestamp) {
        endDate = endTs.toDate();
      } else if (endTs is String) {
        endDate = DateTime.tryParse(endTs);
      }
      
      if (startDate == null || endDate == null) return totalBudget;

      final now = DateTime.now();

      if (now.isAfter(endDate)) return 0;

      final totalDays = endDate.difference(startDate).inDays;
      final elapsedDays = now.difference(startDate).inDays.clamp(0, totalDays);
      final spent = dailyBudget * elapsedDays;
      return (totalBudget - spent).clamp(0, totalBudget);
    } catch (_) {
      return totalBudget;
    }
  }
  
  double _getSpentBudget(Map<String, dynamic> campaign) {
    final totalBudget = (campaign['totalBudget'] as num?)?.toDouble() ?? 0;
    final spentBudget = (campaign['spentBudget'] as num?)?.toDouble() ?? 0;
    
    if (spentBudget > 0) {
      return spentBudget;
    }
    
    // Fallback: estimativa
    return totalBudget - _calculateRemainingBudget(campaign);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
