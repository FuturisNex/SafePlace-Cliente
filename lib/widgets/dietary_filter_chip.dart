import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chip de filtro alimentar com persistência local e experiência personalizada.
///
/// Diferencial: permite ao usuário salvar preferências alimentares localmente, tornando a experiência única e adaptada.
/// Lógica exclusiva: integração com SharedPreferences para lembrar filtros mesmo após fechar o app.
///
/// Uso:
/// - required: id (identificador único, ex: 'vegetarian'), label (texto do chip)
/// - opcional: selected (se fornecido, o widget atua como controlado e respeita esse valor)
/// - opcional: onSelected(bool) callback chamado quando o usuário altera a seleção
///
/// Comportamento:
/// - Se `selected` for null, o widget lê o valor salvo em SharedPreferences na chave
///   "dietary_pref_<id>" e usa como estado inicial; em seguida salva alterações.
/// - Se `selected` for não-nulo, o widget exibirá esse valor e ainda assim chamará
///   onSelected ao ser tocado (sem alterar persistência — para persistência nesse caso,
///   o caller deve salvar explicitamente — entretanto, por compatibilidade também salvamos).
class DietaryFilterChip extends StatefulWidget {
  final String id;
  final String label;
  final Widget? leading;
  final bool? selected;
  final ValueChanged<bool>? onSelected;
  final Color? selectedColor;
  final Color? avatarColor;

  const DietaryFilterChip({
    Key? key,
    required this.id,
    required this.label,
    this.leading,
    this.selected,
    this.onSelected,
    this.selectedColor,
    this.avatarColor,
  }) : super(key: key);

  @override
  State<DietaryFilterChip> createState() => _DietaryFilterChipState();
}

class _DietaryFilterChipState extends State<DietaryFilterChip> {
  static const String _prefix = 'dietary_pref_';
  bool? _internalSelected;
  bool _loading = false;

  String get _storageKey => '$_prefix${widget.id}';

  @override
  void initState() {
    super.initState();
    // If widget.selected is provided (controlled), we do not override it,
    // but still load persisted value to keep UI consistent if caller expects it.
    if (widget.selected == null) {
      _loadSaved();
    } else {
      // Keep a copy for internal use, but controlled prop has precedence in build.
      _internalSelected = widget.selected;
    }
  }

  @override
  void didUpdateWidget(covariant DietaryFilterChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If caller switches to controlled mode or changes value, update internal state.
    if (widget.selected != oldWidget.selected) {
      if (widget.selected != null) {
        setState(() {
          _internalSelected = widget.selected;
        });
      } else {
        // Became uncontrolled: load persisted value
        _loadSaved();
      }
    }
  }

  Future<void> _loadSaved() async {
    setState(() {
      _loading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_storageKey);
    setState(() {
      _internalSelected = saved ?? false;
      _loading = false;
    });
  }

  Future<void> _saveSelected(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, value);
  }

  void _handleTap() {
    final bool current = widget.selected ?? (_internalSelected ?? false);
    final bool next = !current;

    // If widget is not controlled (selected == null), update internal state and persist.
    if (widget.selected == null) {
      setState(() {
        _internalSelected = next;
      });
      _saveSelected(next);
    } else {
      // Controlled: still persist for convenience so UI elsewhere can read it,
      // but caller remains the source of truth.
      _saveSelected(next);
    }

    // Notify caller
    widget.onSelected?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final bool effectiveSelected = widget.selected ?? (_internalSelected ?? false);

    // While loading persisted value, show a disabled appearance to avoid flicker.
    if (_loading) {
      return FilterChip(
        label: Text(widget.label),
        selected: false,
        onSelected: null,
      );
    }

    return Tooltip(
      message: 'Selecione para filtrar estabelecimentos que atendem a esta preferência alimentar.',
      child: FilterChip(
      selectedColor: widget.selectedColor ?? Theme.of(context).colorScheme.primary.withOpacity(0.12),
      avatar: widget.leading != null
          ? CircleAvatar(
              backgroundColor: widget.avatarColor ?? Theme.of(context).colorScheme.primary.withOpacity(0.15),
              child: widget.leading,
            )
          : null,
      label: Text(widget.label),
      selected: effectiveSelected,
      onSelected: (_) => _handleTap(),
    ),
    );
  }
}