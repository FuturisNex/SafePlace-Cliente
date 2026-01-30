import 'package:flutter/material.dart';

class CustomNotification {
  static OverlayEntry? _overlayEntry;
  static OverlayState? _overlayState;

  static void show({
    required BuildContext context,
    required String message,
    Color backgroundColor = const Color(0xFF4CAF50),
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Remover notificação anterior se existir
    hide();

    _overlayState = Overlay.of(context);
    if (_overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _NotificationWidget(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        onDismiss: hide,
      ),
    );

    _overlayState!.insert(_overlayEntry!);

    // Auto-dismiss após duração
    Future.delayed(duration, () {
      hide();
    });
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  static void success(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      backgroundColor: const Color(0xFF4CAF50),
      icon: Icons.check_circle,
    );
  }

  static void error(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      backgroundColor: Colors.red.shade700,
      icon: Icons.error,
    );
  }

  static void warning(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      backgroundColor: Colors.orange.shade700,
      icon: Icons.warning,
    );
  }

  static void info(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      backgroundColor: Colors.blue.shade700,
      icon: Icons.info,
    );
  }
}

class _NotificationWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData? icon;
  final VoidCallback onDismiss;

  const _NotificationWidget({
    required this.message,
    required this.backgroundColor,
    this.icon,
    required this.onDismiss,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        _controller.reverse().then((_) {
                          widget.onDismiss();
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


