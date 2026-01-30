import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/establishment.dart';
import '../services/boost_service.dart';
import '../theme/app_theme.dart';

/// Tela de insights de campanha de boost
class BoostInsightsScreen extends StatefulWidget {
  final String campaignId;
  final Establishment establishment;

  const BoostInsightsScreen({
    super.key,
    required this.campaignId,
    required this.establishment,
  });

  @override
  State<BoostInsightsScreen> createState() => _BoostInsightsScreenState();
}

class _BoostInsightsScreenState extends State<BoostInsightsScreen> {
  Map<String, dynamic>? _campaign;
  bool _isLoading = true;
  StreamSubscription? _campaignSubscription;

  @override
  void initState() {
    super.initState();
    _listenToCampaign();
  }

  @override
  void dispose() {
    _campaignSubscription?.cancel();
    super.dispose();
  }

  void _listenToCampaign() {
    _campaignSubscription = FirebaseFirestore.instance
        .collection('boostCampaigns')
        .doc(widget.campaignId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _campaign = {
            'id': snapshot.id,
            ...snapshot.data()!,
          };
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Insights do Impulsionamento'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _campaign == null
              ? _buildNoCampaign()
              : _buildInsights(),
    );
  }

  Widget _buildNoCampaign() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Campanha não encontrada',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    final campaign = _campaign!;
    final status = campaign['status'] as String? ?? 'unknown';
    final totalBudget = (campaign['totalBudget'] as num?)?.toDouble() ?? 0;
    final dailyBudget = (campaign['dailyBudget'] as num?)?.toDouble() ?? 0;
    final durationDays = campaign['durationDays'] as int? ?? 7;
    final impressions = campaign['impressions'] as int? ?? 0;
    final clicks = campaign['clicks'] as int? ?? 0;
    
    // Calcular datas
    DateTime? startDate;
    DateTime? endDate;
    try {
      if (campaign['startDate'] != null) {
        startDate = (campaign['startDate'] as Timestamp).toDate();
      }
      if (campaign['endDate'] != null) {
        endDate = (campaign['endDate'] as Timestamp).toDate();
      }
    } catch (_) {}

    // Calcular saldo restante - usar spentBudget real do backend quando disponível
    final now = DateTime.now();
    double spentBudget = (campaign['spentBudget'] as num?)?.toDouble() ?? 0;
    double remainingBudget = totalBudget;
    int daysRemaining = 0;
    double progressPercent = 0;

    if (startDate != null && endDate != null) {
      final totalDuration = endDate.difference(startDate).inDays;
      final elapsedDays = now.difference(startDate).inDays.clamp(0, totalDuration);
      daysRemaining = endDate.difference(now).inDays.clamp(0, totalDuration);
      
      // Se não tiver spentBudget real, usar estimativa
      if (spentBudget == 0 && elapsedDays > 0) {
        spentBudget = dailyBudget * elapsedDays;
      }
      
      remainingBudget = (totalBudget - spentBudget).clamp(0, totalBudget);
      progressPercent = totalBudget > 0 ? spentBudget / totalBudget : 0;
    }

    // CTR
    final ctr = impressions > 0 ? (clicks / impressions * 100) : 0.0;

    // Custo por clique
    final cpc = clicks > 0 ? spentBudget / clicks : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do estabelecimento
          _buildEstablishmentHeader(),
          const SizedBox(height: 20),

          // Status e saldo
          _buildStatusCard(status, remainingBudget, totalBudget, daysRemaining, progressPercent),
          const SizedBox(height: 20),

          // Métricas principais
          _buildMetricsGrid(impressions, clicks, ctr, cpc),
          const SizedBox(height: 20),

          // Detalhes da campanha
          _buildCampaignDetails(totalBudget, dailyBudget, durationDays, startDate, endDate),
          const SizedBox(height: 20),

          // Gráfico de performance (simplificado)
          _buildPerformanceChart(impressions, clicks),
          const SizedBox(height: 20),

          // Ações
          _buildActions(status),
        ],
      ),
    );
  }

  Widget _buildEstablishmentHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.establishment.avatarUrl.isNotEmpty
                  ? Image.network(
                      widget.establishment.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.storefront,
                        color: Colors.grey.shade400,
                      ),
                    )
                  : Icon(Icons.storefront, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.establishment.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rocket_launch, size: 12, color: Color(0xFF6366F1)),
                          SizedBox(width: 4),
                          Text(
                            'Impulsionado',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
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
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String status,
    double remainingBudget,
    double totalBudget,
    int daysRemaining,
    double progressPercent,
  ) {
    final isActive = status == 'active';
    final statusColor = isActive ? Colors.green : Colors.orange;
    final statusLabel = isActive ? 'Ativo' : (status == 'paused' ? 'Pausado' : 'Finalizado');

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo Restante',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'R\$ ${remainingBudget.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'de R\$ ${totalBudget.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercent.clamp(0, 1),
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progressPercent * 100).toInt()}% consumido',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                '$daysRemaining dias restantes',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(int impressions, int clicks, double ctr, double cpc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.visibility,
                iconColor: Colors.blue,
                label: 'Impressões',
                value: _formatNumber(impressions),
                subtitle: 'Vezes exibido',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.touch_app,
                iconColor: Colors.green,
                label: 'Cliques',
                value: _formatNumber(clicks),
                subtitle: 'Interações',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.percent,
                iconColor: Colors.orange,
                label: 'CTR',
                value: '${ctr.toStringAsFixed(2)}%',
                subtitle: 'Taxa de cliques',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.attach_money,
                iconColor: Colors.purple,
                label: 'CPC',
                value: 'R\$ ${cpc.toStringAsFixed(2)}',
                subtitle: 'Custo por clique',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignDetails(
    double totalBudget,
    double dailyBudget,
    int durationDays,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalhes da Campanha',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Investimento total', 'R\$ ${totalBudget.toStringAsFixed(2)}'),
          _buildDetailRow('Lance diário', 'R\$ ${dailyBudget.toStringAsFixed(2)}/dia'),
          _buildDetailRow('Duração', '$durationDays dias'),
          if (startDate != null)
            _buildDetailRow('Início', _formatDate(startDate)),
          if (endDate != null)
            _buildDetailRow('Término', _formatDate(endDate)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(int impressions, int clicks) {
    // Gráfico simplificado de barras
    final maxValue = impressions > 0 ? impressions : 1;
    final impressionPercent = 1.0;
    final clickPercent = impressions > 0 ? clicks / impressions : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparativo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildBarChart('Impressões', impressions, impressionPercent, Colors.blue),
          const SizedBox(height: 16),
          _buildBarChart('Cliques', clicks, clickPercent, Colors.green),
        ],
      ),
    );
  }

  Widget _buildBarChart(String label, int value, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600)),
            Text(_formatNumber(value), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent.clamp(0, 1),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(String status) {
    final isActive = status == 'active';
    final isPaused = status == 'paused';

    return Row(
      children: [
        if (isActive)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _updateStatus('paused'),
              icon: const Icon(Icons.pause),
              label: const Text('Pausar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (isPaused)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus('active'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Retomar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await BoostService.updateCampaignStatus(widget.campaignId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'active' 
                  ? 'Campanha retomada!' 
                  : 'Campanha pausada.',
            ),
            backgroundColor: newStatus == 'active' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
