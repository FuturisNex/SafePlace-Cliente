import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/refer_establishment_screen.dart';

/// Widget exibido quando não há estabelecimentos no raio de visão do mapa
/// Mostra uma mensagem amigável e convida o usuário a sugerir locais
class EmptyMapState extends StatefulWidget {
  final VoidCallback? onSuggestEstablishment;
  final VoidCallback? onExpandSearch;
  final bool isDialog;
  
  const EmptyMapState({
    super.key,
    this.onSuggestEstablishment,
    this.onExpandSearch,
    this.isDialog = false,
  });

  /// Método estático para exibir este estado como um popup (dialog)
  static Future<void> show(BuildContext context, {VoidCallback? onExpandSearch}) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: EmptyMapState(
            isDialog: true,
            onExpandSearch: onExpandSearch,
            onSuggestEstablishment: () {
              Navigator.of(context).pop(); // Fecha o dialog
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ReferEstablishmentScreen(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  State<EmptyMapState> createState() => _EmptyMapStateState();
}

class _EmptyMapStateState extends State<EmptyMapState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: widget.isDialog ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isDialog)
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          // Ícone animado
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryGreen.withValues(alpha: 0.2),
                    AppTheme.primaryGreen.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore_rounded,
                size: 40,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Título
          const Text(
            'Estamos mapeando sua região! 🗺️',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Descrição
          Text(
            'Novos estabelecimentos seguros estão sendo cadastrados todos os dias.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Cards informativos
          _buildInfoCard(
            icon: Icons.schedule_rounded,
            iconColor: Colors.blue,
            text: 'Empresas chegando em breve',
          ),
          
          const SizedBox(height: 10),
          
          _buildInfoCard(
            icon: Icons.add_location_alt_rounded,
            iconColor: Colors.orange,
            text: 'Indique locais para acelerar',
          ),
          
          const SizedBox(height: 20),
          
          // Botão de sugerir
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onSuggestEstablishment ?? () {
                if (widget.isDialog) Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ReferEstablishmentScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 20),
              label: const Text('Indicar um estabelecimento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Botão secundário para expandir busca
          if (widget.onExpandSearch != null)
            TextButton.icon(
              onPressed: widget.onExpandSearch,
              icon: Icon(
                Icons.zoom_out_map_rounded,
                size: 18,
                color: Colors.grey.shade600,
              ),
              label: Text(
                'Expandir área de busca',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );

    return content;
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}

/// Overlay para o mapa quando não há estabelecimentos
/// Pode ser usado como uma camada sobre o mapa
class EmptyMapOverlay extends StatelessWidget {
  final VoidCallback? onSuggestEstablishment;
  final VoidCallback? onExpandSearch;
  final bool showOverlay;
  
  const EmptyMapOverlay({
    super.key,
    this.onSuggestEstablishment,
    this.onExpandSearch,
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showOverlay) return const SizedBox.shrink();
    
    return Container(
      color: Colors.white.withValues(alpha: 0.85),
      child: Center(
        child: EmptyMapState(
          onSuggestEstablishment: onSuggestEstablishment,
          onExpandSearch: onExpandSearch,
        ),
      ),
    );
  }
}
