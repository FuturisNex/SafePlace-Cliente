import 'package:flutter/material.dart';

/// Tipos de plano de divulgação para empresas
enum BusinessPlanType {
  basic,
  intermediate,
  premium,
  corporate,
}

/// Status de uma assinatura/solicitação de plano de divulgação
enum BusinessPlanStatus {
  none,
  active,
  pendingApproval,
  pendingPayment,
  canceled,
}

class BusinessPlanSubscription {
  final String id;
  final String ownerId;
  /// Estabelecimento ao qual este plano está vinculado (modelo por estabelecimento).
  /// Pode ser null em registros antigos (planos por empresa).
  final String? establishmentId;
  final BusinessPlanType planType;
  final BusinessPlanStatus status;
  final String billingCycle; // 'quarterly', 'Annual', 'custom'
  final DateTime createdAt;
  final DateTime? validUntil;

  BusinessPlanSubscription({
    required this.id,
    required this.ownerId,
    this.establishmentId,
    required this.planType,
    required this.status,
    required this.billingCycle,
    required this.createdAt,
    this.validUntil,
  });

  factory BusinessPlanSubscription.fromJson(String id, Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value);
      }
      try {
        if (value.runtimeType.toString().contains('Timestamp')) {
          return (value as dynamic).toDate();
        }
      } catch (_) {}
      return null;
    }

    final typeString = (json['planType'] as String?) ?? 'basic';
    final statusString = (json['status'] as String?) ?? 'pendingApproval';

    return BusinessPlanSubscription(
      id: id,
      ownerId: json['ownerId'] as String,
      establishmentId: json['establishmentId'] as String?,
      planType: BusinessPlanType.values.firstWhere(
        (e) => e.toString().split('.').last == typeString,
        orElse: () => BusinessPlanType.basic,
      ),
      status: BusinessPlanStatus.values.firstWhere(
        (e) => e.toString().split('.').last == statusString,
        orElse: () => BusinessPlanStatus.pendingApproval,
      ),
      billingCycle: json['billingCycle'] as String? ?? 'quarterly',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      validUntil: _parseDate(json['validUntil']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      if (establishmentId != null) 'establishmentId': establishmentId,
      'planType': planType.toString().split('.').last,
      'status': status.toString().split('.').last,
      'billingCycle': billingCycle,
      'createdAt': createdAt.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
    };
  }
}

extension BusinessPlanTypeX on BusinessPlanType {
  String get id => toString().split('.').last;

  String get title {
    switch (this) {
      case BusinessPlanType.basic:
        return 'Plano Inicial';
      case BusinessPlanType.intermediate:
        return 'Plano Intermediário';
      case BusinessPlanType.premium:
        return 'Plano Premium';
      case BusinessPlanType.corporate:
        return 'Plano Corporate';
    }
  }

  String get quarterPriceLabel {
    switch (this) {
      case BusinessPlanType.basic:
        return 'R\$ 179,70/trimestral';
      case BusinessPlanType.intermediate:
        return 'R\$ 450,00/trimestral';
      case BusinessPlanType.premium:
        return 'R\$ 900,00/trimestral';
      case BusinessPlanType.corporate:
        return 'Sob proposta';
    }
  }

  String get annualPriceLabel {
    switch (this) {
      case BusinessPlanType.basic:
        return 'R\$ 600,00/anual';
      case BusinessPlanType.intermediate:
        return 'R\$ 1200,00/anual';
      case BusinessPlanType.premium:
        return 'R\$ 3.000,00/anual';
      case BusinessPlanType.corporate:
        return 'Sob proposta';
    }
  }

  List<String> get features {
    switch (this) {
      case BusinessPlanType.basic:
        return [
          '1 foto no anúncio do aplicativo',
          'Exibição padrão nos resultados de busca',
          'Acesso às avaliações de usuários',
          'Selo Popular (gratuito, atribuído pela comunidade)',
        ];
      case BusinessPlanType.intermediate:
        return [
          'Até 5 fotos no anúncio',
          'Exibição em posição destacada',
          'Possibilidade de aderir ao Selo Intermediário sem custo adicional',
          'Selo Popular (gratuito)',
          'Treinamento para funcionários disponível à parte',
        ];
      case BusinessPlanType.premium:
        return [
          'Até 10 fotos no anúncio',
          'Destaque nas buscas do aplicativo',
          'Direito ao Selo Intermediário incluído',
          'Possibilidade de contratação de Selo Técnico à parte',
          'Selo Popular (gratuito)',
          'Material de capacitação e treinamentos disponível para compra',
        ];
      case BusinessPlanType.corporate:
        return [
          'Inclui todos os benefícios do Plano Premium',
          'Divulgação oficial no Instagram da Prato Seguro',
          'Anúncio institucional no site oficial',
          'Exposição prioritaria no topo do app por tempo determinado',
          'Participação com estande em evento anual da Prato Seguro',
          'Consultoria personalizada e ações de marca',
        ];
    }
  }

  String get recommendedFor {
    switch (this) {
      case BusinessPlanType.basic:
        return 'Pequenos estabelecimentos iniciando sua presença no aplicativo.';
      case BusinessPlanType.intermediate:
        return 'Negócios que desejam maior presença e validação técnica inicial.';
      case BusinessPlanType.premium:
        return 'Empresas que desejam maior alcance e presença consolidada na plataforma.';
      case BusinessPlanType.corporate:
        return 'Marcas que buscam presença institucional ampla e relacionamento direto com o público-alvo.';
    }
  }

  IconData get icon {
    switch (this) {
      case BusinessPlanType.basic:
        return Icons.star_border;
      case BusinessPlanType.intermediate:
        return Icons.auto_awesome;
      case BusinessPlanType.premium:
        return Icons.workspace_premium;
      case BusinessPlanType.corporate:
        return Icons.corporate_fare;
    }
  }

  Color get color {
    switch (this) {
      case BusinessPlanType.basic:
        return Colors.green;
      case BusinessPlanType.intermediate:
        return Colors.blue;
      case BusinessPlanType.premium:
        return Colors.purple;
      case BusinessPlanType.corporate:
        return Colors.amber;
    }
  }

  int get maxEstablishmentPhotos {
    switch (this) {
      case BusinessPlanType.basic:
        return 1;
      case BusinessPlanType.intermediate:
        return 5;
      case BusinessPlanType.premium:
        return 10;
      case BusinessPlanType.corporate:
        // Inclui todos os benefícios do Premium; manter o mesmo limite de fotos
        return 10;
    }
  }
}
