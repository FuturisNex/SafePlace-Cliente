import 'package:firebase_auth/firebase_auth.dart';

/// Este stub existe apenas como fallback. O fluxo completo de login com Google
/// deve ser realizado via AuthProvider (loginWithGoogleAdvanced) já presente no projeto.
/// Se você preferir uma implementação direta aqui, eu posso implementar, mas
/// ela pode exigir ajustes de configuração (SHA-1 / OAuth) e API do pacote.
class GoogleAuthService {
  /// Indica que a operação não está implementada aqui.
  static Future<UserCredential?> signInWithGoogle() async {
    throw UnimplementedError(
        'O login com Google deve ser feito via AuthProvider.loginWithGoogleAdvanced');
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}