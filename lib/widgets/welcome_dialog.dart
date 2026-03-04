import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Dialog de boas-vindas para novos usuários
/// Explica que o app está em fase inicial e convida a participar da comunidade
class WelcomeDialog extends StatefulWidget {
  final VoidCallback? onSuggestEstablishment;
  final VoidCallback? onClose;

  const WelcomeDialog({
    super.key,
    this.onSuggestEstablishment,
    this.onClose,
  });

  /// Verifica se deve mostrar o dialog nesta sessão
  /// Agora mostra sempre ao logar, mas apenas uma vez por sessão
  static const String _lastShownDateKey = 'welcome_dialog_last_shown_date_v1';
  static bool _shownThisSession = false;
  static bool _isDialogVisible = false;

  static String _todayDateKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  /// Verifica se deve mostrar o dialog (uma vez por sessão de login)
  static Future<bool> shouldShow() async {
    if (_shownThisSession) return false;
    final prefs = await SharedPreferences.getInstance();
    final lastShownDate = prefs.getString(_lastShownDateKey);
    return lastShownDate != _todayDateKey();
  }

  /// Marca o dialog como já exibido nesta sessão
  static Future<void> markAsShown() async {
    _shownThisSession = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastShownDateKey, _todayDateKey());
  }

  /// Reseta o estado para nova sessão (chamar ao fazer logout)
  static void resetSession() {
    _shownThisSession = false;
  }

  /// Mostra o dialog ao logar (uma vez por sessão)
  static Future<void> showIfNeeded(BuildContext context,
      {VoidCallback? onSuggestEstablishment}) async {
    await _showGuarded(
      context,
      onSuggestEstablishment: onSuggestEstablishment,
    );
  }

  /// Força a exibição do dialog (para uso após login)
  static Future<void> showOnLogin(BuildContext context,
      {VoidCallback? onSuggestEstablishment}) async {
    await _showGuarded(
      context,
      onSuggestEstablishment: onSuggestEstablishment,
    );
  }

  static Future<void> _showGuarded(
    BuildContext context, {
    VoidCallback? onSuggestEstablishment,
  }) async {
    if (_isDialogVisible) return;
    if (!await shouldShow()) return;
    if (!context.mounted) return;

    _isDialogVisible = true;
    _shownThisSession = true;
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            WelcomeDialog(onSuggestEstablishment: onSuggestEstablishment),
      );
    } finally {
      _isDialogVisible = false;
    }
  }

  @override
  State<WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<WelcomeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;
  final PageController _pageController = PageController();

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
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _close();
    }
  }

  void _close() async {
    await WelcomeDialog.markAsShown();
    if (mounted) {
      Navigator.of(context).pop();
      if (widget.onClose != null) {
        widget.onClose!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340, maxHeight: 600),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppTheme.primaryGreen.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header com ícone animado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Estamos começando juntos! 🎉',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Conteúdo com PageView
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildIntroPage(),
                      _buildPage1(),
                      _buildPage2(),
                      _buildPage3(),
                    ],
                  ),
                ),

                // Indicadores de página
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.primaryGreen
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),

                // Botões
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text(
                            'Voltar',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          _currentPage < 3 ? 'Próximo' : 'Começar!',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 48,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 16),
          const Text(
            'O que é o Prato Seguro?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'O Prato Seguro é um aplicativo colaborativo que ajuda pessoas com restrições alimentares a encontrar restaurantes, cafeterias e outros locais que oferecem opções seguras e confiáveis. Você pode buscar estabelecimentos, ver avaliações de outros usuários, indicar novos locais e compartilhar sua experiência para ajudar toda a comunidade a comer com mais tranquilidade.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 48,
            color: Colors.amber.shade600,
          ),
          const SizedBox(height: 16),
          const Text(
            'Esta é a primeira versão do Prato Seguro!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'As empresas estão sendo cadastradas gradualmente. Novos locais aparecem toda semana!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 48,
            color: Colors.orange.shade500,
          ),
          const SizedBox(height: 16),
          const Text(
            'Conhece um lugar seguro?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Indique restaurantes, cafeterias e outros locais que atendem bem pessoas com restrições alimentares.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              _close();
              widget.onSuggestEstablishment?.call();
            },
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Indicar um local'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: const BorderSide(color: AppTheme.primaryGreen),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_alt_rounded,
            size: 48,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 16),
          const Text(
            'Você faz parte da comunidade!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Suas avaliações e sugestões ajudam outras pessoas com restrições alimentares a encontrar locais seguros.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.red.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Obrigado por estar aqui!',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
