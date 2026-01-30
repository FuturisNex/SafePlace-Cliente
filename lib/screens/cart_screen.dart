import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/delivery_models.dart';
import '../providers/cart_provider.dart';
import '../services/delivery_service.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';

/// Tela do carrinho de compras
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();
  bool _isApplyingCoupon = false;
  String? _couponError;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Carrinho'),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            body: _buildEmptyCart(),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text('Carrinho'),
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            actions: [
              TextButton(
                onPressed: () => _confirmClearCart(cart),
                child: const Text(
                  'Limpar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Estabelecimento
              _buildEstablishmentHeader(cart),

              // Lista de itens
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Itens
                    ...cart.items.map((item) => _buildCartItem(cart, item)),

                    const SizedBox(height: 16),

                    // Cupom
                    _buildCouponSection(cart),

                    const SizedBox(height: 16),

                    // Resumo
                    _buildSummary(cart),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(cart),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Seu carrinho está vazio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione itens do cardápio para fazer seu pedido',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ver Cardápio'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstablishmentHeader(CartProvider cart) {
    final establishment = cart.establishment;
    if (establishment == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: establishment.avatarUrl.isNotEmpty
                ? NetworkImage(establishment.avatarUrl)
                : null,
            child: establishment.avatarUrl.isEmpty
                ? const Icon(Icons.store)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  establishment.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${establishment.deliveryTimeFormatted} • ${establishment.deliveryFeeFormatted}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
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

  Widget _buildCartItem(CartProvider cart, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.menuItem.imageUrl != null
                ? Image.network(
                    item.menuItem.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuItem.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.notes!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'R\$ ${item.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),

          // Quantidade
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => cart.decrementItem(item.menuItem.id),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          item.quantity == 1 ? Icons.delete : Icons.remove,
                          size: 18,
                          color: item.quantity == 1
                              ? Colors.red
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => cart.incrementItem(item.menuItem.id),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.add, size: 18),
                      ),
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

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade200,
      child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 24),
    );
  }

  Widget _buildCouponSection(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cupom de desconto',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          if (cart.appliedCoupon != null)
            // Cupom aplicado
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cart.appliedCoupon!.code,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          cart.appliedCoupon!.formattedValue,
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      cart.removeCoupon();
                      _couponController.clear();
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
                ],
              ),
            )
          else
            // Campo para inserir cupom
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: 'Digite o código',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      errorText: _couponError,
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isApplyingCoupon
                      ? null
                      : () => _applyCoupon(cart),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  child: _isApplyingCoupon
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Aplicar'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _applyCoupon(CartProvider cart) async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isApplyingCoupon = true;
      _couponError = null;
    });

    try {
      // Buscar cupons do estabelecimento
      final couponsStream = DeliveryService.getCouponsStream(
        cart.establishment!.id,
      );
      final coupons = await couponsStream.first;

      // Encontrar cupom pelo código
      final coupon = coupons.where((c) => c.code == code).firstOrNull;

      if (coupon == null) {
        setState(() => _couponError = 'Cupom não encontrado');
        return;
      }

      if (!coupon.isValid) {
        setState(() => _couponError = 'Cupom inválido ou expirado');
        return;
      }

      if (coupon.minOrderValue != null && cart.subtotal < coupon.minOrderValue!) {
        setState(() => _couponError =
            'Pedido mínimo: R\$ ${coupon.minOrderValue!.toStringAsFixed(0)}');
        return;
      }

      cart.applyCoupon(coupon);
      _couponController.clear();
    } catch (e) {
      setState(() => _couponError = 'Erro ao aplicar cupom');
    } finally {
      setState(() => _isApplyingCoupon = false);
    }
  }

  Widget _buildSummary(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo do pedido',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          _buildSummaryRow('Subtotal', 'R\$ ${cart.subtotal.toStringAsFixed(2)}'),

          if (cart.discount > 0)
            _buildSummaryRow(
              'Desconto',
              '- R\$ ${cart.discount.toStringAsFixed(2)}',
              valueColor: Colors.green,
            ),

          _buildSummaryRow(
            'Taxa de entrega',
            cart.finalDeliveryFee > 0
                ? 'R\$ ${cart.finalDeliveryFee.toStringAsFixed(2)}'
                : 'Grátis',
            valueColor: cart.finalDeliveryFee == 0 ? Colors.green : null,
          ),

          const Divider(height: 24),

          _buildSummaryRow(
            'Total',
            'R\$ ${cart.total.toStringAsFixed(2)}',
            isBold: true,
            fontSize: 18,
          ),

          // Frete grátis
          if (cart.remainingForFreeDelivery > 0 && cart.deliveryFee > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Faltam R\$ ${cart.remainingForFreeDelivery.toStringAsFixed(2)} para frete grátis!',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: fontSize,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CartProvider cart) {
    final canCheckout = cart.meetsMinimumOrder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Aviso de pedido mínimo
            if (!canCheckout) ...[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pedido mínimo: R\$ ${cart.establishment?.minOrderValue?.toStringAsFixed(0) ?? '0'}. '
                        'Faltam R\$ ${cart.remainingForMinimum.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Botão finalizar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canCheckout
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckoutScreen(),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Finalizar Pedido • R\$ ${cart.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCart(CartProvider cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar carrinho'),
        content: const Text('Tem certeza que deseja remover todos os itens?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}
