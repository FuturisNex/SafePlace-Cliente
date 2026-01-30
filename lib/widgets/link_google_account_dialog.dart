import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Diálogo para vincular conta Google a uma conta existente
/// Usado quando o usuário tenta fazer login com Google mas já existe
/// uma conta com o mesmo email (criada pelo admin ou por email/senha)
class LinkGoogleAccountDialog extends StatefulWidget {
  final String email;
  final AuthCredential googleCredential;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const LinkGoogleAccountDialog({
    super.key,
    required this.email,
    required this.googleCredential,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<LinkGoogleAccountDialog> createState() => _LinkGoogleAccountDialogState();
}

class _LinkGoogleAccountDialogState extends State<LinkGoogleAccountDialog> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _linkAccount() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Digite sua senha');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fazer login com email/senha
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.email,
        password: _passwordController.text,
      );

      if (userCredential.user == null) {
        throw Exception('Falha ao autenticar');
      }

      // 2. Vincular credencial do Google
      await userCredential.user!.linkWithCredential(widget.googleCredential);

      debugPrint('✅ Conta Google vinculada com sucesso');
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao vincular conta';
      
      if (e.code == 'wrong-password') {
        message = 'Senha incorreta. Tente novamente.';
      } else if (e.code == 'user-not-found') {
        message = 'Usuário não encontrado.';
      } else if (e.code == 'too-many-requests') {
        message = 'Muitas tentativas. Aguarde alguns minutos.';
      } else if (e.code == 'credential-already-in-use') {
        message = 'Esta conta Google já está vinculada a outro usuário.';
      } else if (e.code == 'provider-already-linked') {
        // Já está vinculado, considerar sucesso
        if (mounted) {
          Navigator.of(context).pop();
          widget.onSuccess();
        }
        return;
      }
      
      setState(() => _errorMessage = message);
    } catch (e) {
      setState(() => _errorMessage = 'Erro: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.link,
                size: 32,
                color: Colors.blue.shade600,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Título
            const Text(
              'Conta já existe',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Descrição
            Text(
              'Já existe uma conta com o email ${widget.email}.\n\nDeseja vincular sua conta Google a esta conta existente?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Campo de senha
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Senha da conta existente',
                hintText: 'Digite sua senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _errorMessage,
              ),
              onSubmitted: (_) => _linkAccount(),
            ),
            
            const SizedBox(height: 24),
            
            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.of(context).pop();
                      widget.onCancel();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _linkAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Vincular'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Dica
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Após vincular, você poderá fazer login com Google ou email/senha.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Função helper para mostrar o diálogo de vinculação
Future<void> showLinkGoogleAccountDialog({
  required BuildContext context,
  required String email,
  required AuthCredential googleCredential,
  required VoidCallback onSuccess,
  required VoidCallback onCancel,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => LinkGoogleAccountDialog(
      email: email,
      googleCredential: googleCredential,
      onSuccess: onSuccess,
      onCancel: onCancel,
    ),
  );
}
