import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/establishment.dart';
import '../models/delivery_models.dart';
import '../services/delivery_service.dart';
import '../theme/app_theme.dart';

/// Tela de configuração de delivery do estabelecimento
class BusinessDeliveryConfigScreen extends StatefulWidget {
  final Establishment establishment;
  final DeliveryConfig? existingConfig;

  const BusinessDeliveryConfigScreen({
    super.key,
    required this.establishment,
    this.existingConfig,
  });

  @override
  State<BusinessDeliveryConfigScreen> createState() =>
      _BusinessDeliveryConfigScreenState();
}

class _BusinessDeliveryConfigScreenState
    extends State<BusinessDeliveryConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _deliveryFeeController;
  late TextEditingController _freeDeliveryMinController;
  late TextEditingController _timeMinController;
  late TextEditingController _timeMaxController;
  late TextEditingController _radiusController;
  late TextEditingController _minOrderController;
  late TextEditingController _notesController;

  // Estado
  bool _isActive = false;
  List<String> _paymentMethods = ['pix', 'cartao', 'dinheiro'];

  @override
  void initState() {
    super.initState();
    final config = widget.existingConfig;

    _deliveryFeeController = TextEditingController(
      text: config?.deliveryFee?.toStringAsFixed(2) ?? '',
    );
    _freeDeliveryMinController = TextEditingController(
      text: config?.freeDeliveryMinOrder?.toStringAsFixed(2) ?? '',
    );
    _timeMinController = TextEditingController(
      text: (config?.deliveryTimeMin ?? 30).toString(),
    );
    _timeMaxController = TextEditingController(
      text: (config?.deliveryTimeMax ?? 60).toString(),
    );
    _radiusController = TextEditingController(
      text: (config?.deliveryRadius ?? 5.0).toString(),
    );
    _minOrderController = TextEditingController(
      text: config?.minOrderValue?.toStringAsFixed(2) ?? '0',
    );
    _notesController = TextEditingController(
      text: config?.deliveryNotes ?? '',
    );

    _isActive = config?.isActive ?? false;
    _paymentMethods = config?.paymentMethods ?? ['pix', 'cartao', 'dinheiro'];
  }

  @override
  void dispose() {
    _deliveryFeeController.dispose();
    _freeDeliveryMinController.dispose();
    _timeMinController.dispose();
    _timeMaxController.dispose();
    _radiusController.dispose();
    _minOrderController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Configurar Delivery'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Salvar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status
            _buildSection(
              title: 'Status',
              child: SwitchListTile(
                title: const Text('Delivery Ativo'),
                subtitle: Text(
                  _isActive
                      ? 'Seu estabelecimento está recebendo pedidos'
                      : 'Ative para começar a receber pedidos',
                ),
                value: _isActive,
                activeColor: AppTheme.primaryGreen,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Taxa de entrega
            _buildSection(
              title: 'Taxa de Entrega',
              child: Column(
                children: [
                  TextFormField(
                    controller: _deliveryFeeController,
                    decoration: const InputDecoration(
                      labelText: 'Taxa de entrega (R\$)',
                      hintText: 'Deixe vazio para entrega grátis',
                      prefixText: 'R\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _freeDeliveryMinController,
                    decoration: const InputDecoration(
                      labelText: 'Frete grátis acima de (R\$)',
                      hintText: 'Pedido mínimo para frete grátis',
                      prefixText: 'R\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tempo de entrega
            _buildSection(
              title: 'Tempo de Entrega',
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _timeMinController,
                      decoration: const InputDecoration(
                        labelText: 'Mínimo (min)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obrigatório';
                        }
                        return null;
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('a', style: TextStyle(fontSize: 16)),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _timeMaxController,
                      decoration: const InputDecoration(
                        labelText: 'Máximo (min)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obrigatório';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Raio e pedido mínimo
            _buildSection(
              title: 'Área de Entrega',
              child: Column(
                children: [
                  TextFormField(
                    controller: _radiusController,
                    decoration: const InputDecoration(
                      labelText: 'Raio de entrega (km)',
                      suffixText: 'km',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,1}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _minOrderController,
                    decoration: const InputDecoration(
                      labelText: 'Pedido mínimo (R\$)',
                      prefixText: 'R\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Formas de pagamento
            _buildSection(
              title: 'Formas de Pagamento',
              child: Column(
                children: [
                  _buildPaymentOption('pix', 'PIX', Icons.pix),
                  _buildPaymentOption(
                      'cartao', 'Cartão (na entrega)', Icons.credit_card),
                  _buildPaymentOption(
                      'dinheiro', 'Dinheiro', Icons.attach_money),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Observações
            _buildSection(
              title: 'Observações',
              child: TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações sobre entrega',
                  hintText: 'Ex: Não entregamos em dias de chuva forte',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    final isSelected = _paymentMethods.contains(value);
    return CheckboxListTile(
      title: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
      value: isSelected,
      activeColor: AppTheme.primaryGreen,
      onChanged: (checked) {
        setState(() {
          if (checked == true) {
            _paymentMethods.add(value);
          } else {
            _paymentMethods.remove(value);
          }
        });
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos uma forma de pagamento'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final config = DeliveryConfig(
        id: widget.establishment.id,
        establishmentId: widget.establishment.id,
        isActive: _isActive,
        deliveryFee: _deliveryFeeController.text.isNotEmpty
            ? double.parse(_deliveryFeeController.text)
            : null,
        freeDeliveryMinOrder: _freeDeliveryMinController.text.isNotEmpty
            ? double.parse(_freeDeliveryMinController.text)
            : null,
        deliveryTimeMin: int.parse(_timeMinController.text),
        deliveryTimeMax: int.parse(_timeMaxController.text),
        deliveryRadius: double.parse(_radiusController.text),
        minOrderValue: _minOrderController.text.isNotEmpty
            ? double.parse(_minOrderController.text)
            : 0,
        deliveryNotes:
            _notesController.text.isNotEmpty ? _notesController.text : null,
        paymentMethods: _paymentMethods,
      );

      await DeliveryService.saveDeliveryConfig(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
