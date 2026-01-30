import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/coupon.dart';
import '../services/gamification_service.dart';
import '../widgets/custom_notification.dart';
import '../utils/translations.dart';
import 'package:intl/intl.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> with SingleTickerProviderStateMixin {
  List<Coupon> _coupons = [];
  List<Map<String, dynamic>> _availableCoupons = [];
  bool _isLoading = true;
  String _filter = 'active'; // active, expired, all
  late TabController _tabController;
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCoupons();
    _loadAvailableCoupons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user != null) {
      try {
        final coupons = await GamificationService.getUserCoupons(user.id);
        setState(() {
          _coupons = coupons;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          CustomNotification.error(
            context,
            '${Translations.getText(context, 'loadCouponsError')} $e',
          );
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAvailableCoupons() async {
    try {
      final availableCoupons = await GamificationService.getAvailableCoupons();
      setState(() {
        _availableCoupons = availableCoupons;
      });
    } catch (e) {
      debugPrint('Erro ao carregar cupons disponíveis: $e');
    }
  }

  Future<void> _redeemCoupon(Map<String, dynamic> couponData) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      CustomNotification.warning(
        context,
        Translations.getText(context, 'pleaseLogin'),
      );
      return;
    }

    final pointsCost = couponData['pointsCost'] as int? ?? 0;
    if (user.points < pointsCost) {
      CustomNotification.warning(
        context,
        '${Translations.getText(context, 'insufficientPoints')} $pointsCost ${Translations.getText(context, 'pointsRequired')}',
      );
      return;
    }

    // Confirmar resgate
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.getText(context, 'redeemCoupon')),
        content: Text(
          '${Translations.getText(context, 'redeemCouponConfirm')} "${couponData['title']}" ${Translations.getText(context, 'redeemCouponConfirmPoints')} $pointsCost ${Translations.getText(context, 'redeemCouponConfirmPointsEnd')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Translations.getText(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(Translations.getText(context, 'redeemCoupon')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await GamificationService.redeemCoupon(
        userId: user.id,
        couponId: couponData['id'] as String,
        pointsCost: pointsCost,
      );

      // Recarregar dados do usuário e cupons
      await authProvider.reloadUser();
      authProvider.notifyListeners(); // Notificar para atualização em tempo real
      await _loadCoupons();
      await _loadAvailableCoupons();

      if (mounted) {
        CustomNotification.success(
          context,
          Translations.getText(context, 'couponRedeemedSuccess'),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomNotification.error(
          context,
          '${Translations.getText(context, 'couponRedeemError')} $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Coupon> get _filteredCoupons {
    switch (_filter) {
      case 'active':
        return _coupons.where((c) => c.canUse).toList();
      case 'expired':
        return _coupons.where((c) => c.isExpired || c.isUsed).toList();
      default:
        return _coupons;
    }
  }

  Widget _buildRedeemCouponForm(User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seus pontos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stars, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  '${Translations.getText(context, 'yourPoints')} ${user.points}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Formulário de resgate
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code, color: Colors.green.shade700, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        Translations.getText(context, 'redeemCoupon'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    Translations.getText(context, 'enterCouponCode'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: Translations.getText(context, 'couponCode'),
                      hintText: Translations.getText(context, 'couponCodeExample'),
                      prefixIcon: const Icon(Icons.confirmation_number),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _redeemCouponByCode(user, _codeController.text.trim()),
                      icon: const Icon(Icons.check_circle),
                      label: Text(
                        Translations.getText(context, 'redeemCoupon'),
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Informações
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      Translations.getText(context, 'couponCodeInfo'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _redeemCouponByCode(User user, String code) async {
    if (code.isEmpty) {
      CustomNotification.warning(
        context,
        Translations.getText(context, 'pleaseEnterCouponCode'),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Buscar cupom pelo código
      final querySnapshot = await FirebaseFirestore.instance
          .collection('availableCoupons')
          .where('code', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception(Translations.getText(context, 'invalidCouponCode'));
      }

      final couponData = querySnapshot.docs.first.data();
      final couponId = querySnapshot.docs.first.id;
      final pointsCost = couponData['pointsCost'] as int? ?? 0;

      if (user.points < pointsCost) {
        throw Exception('${Translations.getText(context, 'insufficientPoints')} $pointsCost ${Translations.getText(context, 'pointsRequired')}');
      }

      // Resgatar cupom
      await GamificationService.redeemCoupon(
        userId: user.id,
        couponId: couponId,
        pointsCost: pointsCost,
      );

      // Recarregar dados do usuário e cupons
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.reloadUser();
      await _loadCoupons();

      if (mounted) {
        CustomNotification.success(
          context,
          Translations.getText(context, 'couponRedeemedSuccess'),
        );
        // Limpar campo
        _codeController.clear();
      }
    } catch (e) {
      if (mounted) {
        CustomNotification.error(
          context,
          'Erro ao resgatar cupom: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.getText(context, 'coupons')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: Translations.getText(context, 'myCoupons')),
            Tab(text: Translations.getText(context, 'redeemCoupons')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Aba: Meus Cupons
          Column(
            children: [
              // Filtros
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(Translations.getText(context, 'active')),
                        selected: _filter == 'active',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _filter = 'active');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(Translations.getText(context, 'expired')),
                        selected: _filter == 'expired',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _filter = 'expired');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(Translations.getText(context, 'all')),
                        selected: _filter == 'all',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _filter = 'all');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de cupons
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredCoupons.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  _filter == 'active' 
                                      ? Translations.getText(context, 'noCouponsActive')
                                      : _filter == 'expired'
                                          ? Translations.getText(context, 'noCouponsExpired')
                                          : Translations.getText(context, 'noCoupons'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (_filter == 'active') ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    Translations.getText(context, 'redeemCouponsWithPoints'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCoupons,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredCoupons.length,
                              itemBuilder: (context, index) {
                                final coupon = _filteredCoupons[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: coupon.canUse
                                      ? Colors.green.shade50
                                      : Colors.grey.shade100,
                                  child: ListTile(
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: coupon.canUse
                                            ? Colors.green.shade700
                                            : Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.local_offer,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      coupon.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: coupon.isUsed
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(coupon.description),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${coupon.discount.toStringAsFixed(0)}% ${Translations.getText(context, 'discount')}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: coupon.canUse
                                                ? Colors.green.shade700
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                        if (coupon.establishmentName != null)
                                          Text(
                                            '${Translations.getText(context, 'at')} ${coupon.establishmentName}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        Text(
                                          coupon.isUsed
                                              ? '${Translations.getText(context, 'usedOn')} ${DateFormat('dd/MM/yyyy').format(coupon.usedAt!)}'
                                              : coupon.isExpired
                                                  ? '${Translations.getText(context, 'expiredOn')} ${DateFormat('dd/MM/yyyy').format(coupon.expiresAt)}'
                                                  : '${Translations.getText(context, 'validUntil')} ${DateFormat('dd/MM/yyyy').format(coupon.expiresAt)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: coupon.canUse
                                                ? Colors.green.shade700
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: coupon.canUse
                                        ? Icon(Icons.check_circle, color: Colors.green.shade700)
                                        : coupon.isUsed
                                            ? Icon(Icons.check_circle_outline, color: Colors.grey.shade400)
                                            : Icon(Icons.cancel, color: Colors.grey.shade400),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
          // Aba: Resgatar Cupons
          user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        Translations.getText(context, 'pleaseLogin'),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildRedeemCouponForm(user),
        ],
      ),
    );
  }
}

