import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Banner flutuante sedutor para promover o Delivery
/// Aparece temporariamente em períodos aleatórios
class DeliveryFloatingBanner extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const DeliveryFloatingBanner({
    super.key,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<DeliveryFloatingBanner> createState() => _DeliveryFloatingBannerState();
}

class _DeliveryFloatingBannerState extends State<DeliveryFloatingBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _slideAnimation = Tween<double>(begin: 100, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryGreen,
              AppTheme.primaryGreen.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Ícone animado
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Faça seu pedido! 🍕',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Delivery com opções seguras para você',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botão fechar
                  IconButton(
                    onPressed: _dismiss,
                    icon: Icon(
                      Icons.close,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Controller para gerenciar a exibição do banner de delivery
/// Mostra o banner em intervalos aleatórios
class DeliveryBannerController {
  Timer? _timer;
  final Function(bool) onVisibilityChanged;
  bool _isVisible = false;
  
  // Configurações de tempo (em segundos)
  static const int minInterval = 60;  // Mínimo 1 minuto entre exibições
  static const int maxInterval = 180; // Máximo 3 minutos entre exibições
  static const int displayDuration = 8; // Tempo que fica visível

  DeliveryBannerController({required this.onVisibilityChanged});

  void start() {
    _scheduleNextShow();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dismiss() {
    _isVisible = false;
    onVisibilityChanged(false);
    _scheduleNextShow();
  }

  void _scheduleNextShow() {
    _timer?.cancel();
    
    final random = Random();
    final delay = minInterval + random.nextInt(maxInterval - minInterval);
    
    _timer = Timer(Duration(seconds: delay), () {
      _showBanner();
    });
  }

  void _showBanner() {
    _isVisible = true;
    onVisibilityChanged(true);
    
    // Auto-hide após displayDuration segundos
    _timer = Timer(Duration(seconds: displayDuration), () {
      if (_isVisible) {
        dismiss();
      }
    });
  }

  void dispose() {
    stop();
  }
}
