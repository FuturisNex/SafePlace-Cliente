import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider para gerenciar feature flags (recursos em desenvolvimento)
/// Lê do Firestore: appConfig/featureFlags
class FeatureFlagsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  bool _deliveryEnabled = false;
  bool _isLoaded = false;

  bool get deliveryEnabled => _deliveryEnabled;
  bool get isLoaded => _isLoaded;

  FeatureFlagsProvider() {
    _loadFlags();
    _listenToFlags();
  }

  /// Carrega as flags do Firestore
  Future<void> _loadFlags() async {
    try {
      final doc = await _db.collection('appConfig').doc('featureFlags').get();
      if (doc.exists) {
        final data = doc.data();
        _deliveryEnabled = data?['deliveryEnabled'] == true;
      }
      _isLoaded = true;
      notifyListeners();
      debugPrint('✅ Feature flags carregadas: deliveryEnabled=$_deliveryEnabled');
    } catch (e) {
      debugPrint('❌ Erro ao carregar feature flags: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Escuta mudanças em tempo real
  void _listenToFlags() {
    _db.collection('appConfig').doc('featureFlags').snapshots().listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          final newValue = data?['deliveryEnabled'] == true;
          if (newValue != _deliveryEnabled) {
            _deliveryEnabled = newValue;
            notifyListeners();
            debugPrint('🔄 Feature flag atualizada: deliveryEnabled=$_deliveryEnabled');
          }
        }
      },
      onError: (e) {
        debugPrint('❌ Erro ao escutar feature flags: $e');
      },
    );
  }

  /// Recarrega as flags manualmente
  Future<void> refresh() async {
    await _loadFlags();
  }
}
