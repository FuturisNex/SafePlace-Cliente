import 'package:flutter/foundation.dart';

class ScrollBus {
  // Valores possíveis: 'plans' (pedir scroll para a seção de planos) ou null
  static final ValueNotifier<String?> notifier = ValueNotifier<String?>(null);
}