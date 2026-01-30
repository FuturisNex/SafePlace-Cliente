import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/establishment.dart';
import '../models/delivery_models.dart';
import '../services/delivery_service.dart';
import '../theme/app_theme.dart';

/// Tela de gestão de cupons do estabelecimento
class BusinessCouponsScreen extends StatefulWidget {
  final Establishment establishment;

  const BusinessCouponsScreen({
    super.key,
    required this.establishment,
  });

  @override
  State<BusinessCouponsScreen> createState() => _BusinessCouponsScreenState();
}

class _BusinessCouponsScreenState extends State<BusinessCouponsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Cupons e Promoções'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<DeliveryCoupon>>(
        stream: DeliveryService.getCouponsStream(widget.establishment.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final coupons = snapshot.data ?? [];

          if (coupons.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              return _buildCouponCard(coupons[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCouponDialog,
        backgroundColor: Colors.purple.shade600,
        icon: const Icon(Icons.add),
        label: const Text('Novo Cupom'),
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
            Icon(Icons.local_offer, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Nenhum cupom',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie cupons de desconto para atrair mais clientes',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(DeliveryCoupon coupon) {
    final isExpired = coupon.validUntil != null &&
        coupon.validUntil!.isBefore(DateTime.now());
    final isExhausted =
        coupon.maxUses != null && coupon.usedCount >= coupon.maxUses!;

    Color statusColor;
    String statusText;
    if (!coupon.isActive) {
      statusColor = Colors.grey;
      statusText = 'Inativo';
    } else if (isExpired) {
      statusColor = Colors.red;
      statusText = 'Expirado';
    } else if (isExhausted) {
      statusColor = Colors.orange;
      statusText = 'Esgotado';
    } else {
      statusColor = Colors.green;
      statusText = 'Ativo';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header do cupom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // Ícone
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCouponIcon(coupon.type),
                    color: Colors.purple.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade700,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              coupon.code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coupon.formattedValue,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditCouponDialog(coupon);
                    } else if (value == 'toggle') {
                      DeliveryService.toggleCouponActive(
                          coupon.id, !coupon.isActive);
                    } else if (value == 'delete') {
                      _confirmDeleteCoupon(coupon);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(coupon.isActive ? 'Desativar' : 'Ativar'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child:
                          Text('Excluir', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Detalhes
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (coupon.description != null) ...[
                  Text(
                    coupon.description!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    if (coupon.minOrderValue != null)
                      _buildDetailChip(
                        Icons.shopping_cart,
                        'Mín: R\$ ${coupon.minOrderValue!.toStringAsFixed(0)}',
                      ),
                    if (coupon.maxUses != null) ...[
                      const SizedBox(width: 8),
                      _buildDetailChip(
                        Icons.people,
                        '${coupon.usedCount}/${coupon.maxUses} usos',
                      ),
                    ],
                  ],
                ),
                if (coupon.validFrom != null || coupon.validUntil != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateRange(coupon.validFrom, coupon.validUntil),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCouponIcon(CouponType type) {
    switch (type) {
      case CouponType.percentage:
        return Icons.percent;
      case CouponType.fixed:
        return Icons.attach_money;
      case CouponType.freeDelivery:
        return Icons.local_shipping;
    }
  }

  String _formatDateRange(DateTime? from, DateTime? until) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    if (from != null && until != null) {
      return '${dateFormat.format(from)} até ${dateFormat.format(until)}';
    } else if (from != null) {
      return 'A partir de ${dateFormat.format(from)}';
    } else if (until != null) {
      return 'Até ${dateFormat.format(until)}';
    }
    return '';
  }

  void _showAddCouponDialog() {
    _showCouponFormDialog(null);
  }

  void _showEditCouponDialog(DeliveryCoupon coupon) {
    _showCouponFormDialog(coupon);
  }

  void _showCouponFormDialog(DeliveryCoupon? existingCoupon) {
    final codeController =
        TextEditingController(text: existingCoupon?.code ?? '');
    final descController =
        TextEditingController(text: existingCoupon?.description ?? '');
    final valueController = TextEditingController(
      text: existingCoupon?.value.toStringAsFixed(0) ?? '',
    );
    final minOrderController = TextEditingController(
      text: existingCoupon?.minOrderValue?.toStringAsFixed(0) ?? '',
    );
    final maxDiscountController = TextEditingController(
      text: existingCoupon?.maxDiscount?.toStringAsFixed(0) ?? '',
    );
    final maxUsesController = TextEditingController(
      text: existingCoupon?.maxUses?.toString() ?? '',
    );

    CouponType selectedType = existingCoupon?.type ?? CouponType.percentage;
    DateTime? validFrom = existingCoupon?.validFrom;
    DateTime? validUntil = existingCoupon?.validUntil;

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existingCoupon == null ? 'Novo Cupom' : 'Editar Cupom',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Código
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Código do cupom',
                      hintText: 'Ex: PROMO10',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    enabled: existingCoupon == null,
                  ),
                  const SizedBox(height: 12),

                  // Tipo
                  DropdownButtonFormField<CouponType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de desconto',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: CouponType.percentage,
                        child: Text('Porcentagem (%)'),
                      ),
                      DropdownMenuItem(
                        value: CouponType.fixed,
                        child: Text('Valor fixo (R\$)'),
                      ),
                      DropdownMenuItem(
                        value: CouponType.freeDelivery,
                        child: Text('Frete grátis'),
                      ),
                    ],
                    onChanged: (value) {
                      setSheetState(() => selectedType = value!);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Valor
                  if (selectedType != CouponType.freeDelivery)
                    TextField(
                      controller: valueController,
                      decoration: InputDecoration(
                        labelText: selectedType == CouponType.percentage
                            ? 'Desconto (%)'
                            : 'Desconto (R\$)',
                        prefixText: selectedType == CouponType.percentage
                            ? null
                            : 'R\$ ',
                        suffixText:
                            selectedType == CouponType.percentage ? '%' : null,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  if (selectedType != CouponType.freeDelivery)
                    const SizedBox(height: 12),

                  // Descrição
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      hintText: 'Ex: Desconto de 10% em todo o cardápio',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Pedido mínimo e máximo de desconto
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minOrderController,
                          decoration: const InputDecoration(
                            labelText: 'Pedido mínimo',
                            prefixText: 'R\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (selectedType == CouponType.percentage)
                        Expanded(
                          child: TextField(
                            controller: maxDiscountController,
                            decoration: const InputDecoration(
                              labelText: 'Desc. máximo',
                              prefixText: 'R\$ ',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Limite de usos
                  TextField(
                    controller: maxUsesController,
                    decoration: const InputDecoration(
                      labelText: 'Limite de usos (opcional)',
                      hintText: 'Deixe vazio para ilimitado',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),

                  // Validade
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: validFrom ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setSheetState(() => validFrom = date);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Válido de',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              validFrom != null
                                  ? DateFormat('dd/MM/yyyy').format(validFrom!)
                                  : 'Selecionar',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: validUntil ??
                                  DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setSheetState(() => validUntil = date);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Válido até',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              validUntil != null
                                  ? DateFormat('dd/MM/yyyy').format(validUntil!)
                                  : 'Selecionar',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

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
                            if (codeController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Informe o código do cupom'),
                                ),
                              );
                              return;
                            }

                            if (selectedType != CouponType.freeDelivery &&
                                valueController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Informe o valor do desconto'),
                                ),
                              );
                              return;
                            }

                            try {
                              final coupon = DeliveryCoupon(
                                id: existingCoupon?.id ?? '',
                                establishmentId: widget.establishment.id,
                                code: codeController.text.trim().toUpperCase(),
                                description: descController.text.trim().isNotEmpty
                                    ? descController.text.trim()
                                    : null,
                                type: selectedType,
                                value: selectedType == CouponType.freeDelivery
                                    ? 0
                                    : double.parse(valueController.text),
                                minOrderValue: minOrderController.text.isNotEmpty
                                    ? double.parse(minOrderController.text)
                                    : null,
                                maxDiscount: maxDiscountController.text.isNotEmpty
                                    ? double.parse(maxDiscountController.text)
                                    : null,
                                maxUses: maxUsesController.text.isNotEmpty
                                    ? int.parse(maxUsesController.text)
                                    : null,
                                validFrom: validFrom,
                                validUntil: validUntil,
                                usedCount: existingCoupon?.usedCount ?? 0,
                              );

                              if (existingCoupon == null) {
                                await DeliveryService.createCoupon(coupon);
                              } else {
                                await DeliveryService.updateCoupon(coupon);
                              }

                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          child:
                              Text(existingCoupon == null ? 'Criar' : 'Salvar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteCoupon(DeliveryCoupon coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Cupom'),
        content: Text('Tem certeza que deseja excluir o cupom "${coupon.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DeliveryService.deleteCoupon(coupon.id);
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
