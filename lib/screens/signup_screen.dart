import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_logo.dart';
import '../widgets/google_sign_in_button.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../models/user.dart';
import '../utils/translations.dart';
import 'home_screen.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';
import '../config.dart'; // Certifique-se de que este arquivo existe e contém APP_ACCOUNT_TYPE

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _acceptedTerms = false;
  String? _selectedLanguage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _showSnack(String message, {bool error = false}) async {
    final snack = SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.redAccent : Colors.green[700],
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  Future<void> _submit() async {
    if (!_acceptedTerms) {
      _showSnack('Você precisa aceitar os Termos de Uso e a Política de Privacidade', error: true);
      return;
    }
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack('Preencha todos os campos.', error: true);
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('E-mail inválido', error: true);
      return;
    }
    if (password.length < 6) {
      _showSnack('Senha deve ter ao menos 6 caracteres', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user != null) {
        await user.updateDisplayName(name);
        // Salvar dados adicionais no Firestore (coleção 'users')
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
          'type': APP_ACCOUNT_TYPE, // Preservar o tipo de conta
        }, SetOptions(merge: true));
        _showSnack('Conta criada com sucesso');
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        _showSnack('Erro ao criar conta', error: true);
      }
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Erro no cadastro', error: true);
    } catch (e) {
      _showSnack('Erro inesperado', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    String? languageCode;
    try {
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      languageCode = _selectedLanguage ?? localeProvider.locale.languageCode;
    } catch (_) {
      languageCode = _selectedLanguage ?? 'pt';
    }

    final result = await authProvider.loginWithGoogleAdvanced(UserType.user, preferredLanguage: languageCode);
    setState(() => _loading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      _showSnack('Login com Google realizado');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (result['error'] != null) {
      _showSnack(result['error'] as String, error: true);
    } else {
      _showSnack('Falha no login com Google', error: true);
    }
  }

  Widget _buildLanguageSelector() {
    return Consumer<LocaleProvider>(builder: (context, localeProvider, _) {
      final currentLang = _selectedLanguage ?? localeProvider.locale.languageCode;
      return PopupMenuButton<String>(
        onSelected: (code) {
          setState(() {
            _selectedLanguage = code;
          });
          localeProvider.selectLanguage(code);
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'pt', child: Text('Português')),
          const PopupMenuItem(value: 'en', child: Text('English')),
          const PopupMenuItem(value: 'es', child: Text('Español')),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_flagForCode(currentLang), style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(currentLang.toUpperCase(), style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
          ],
        ),
      );
    });
  }

  String _flagForCode(String code) {
    switch (code) {
      case 'pt':
        return '🇧🇷';
      case 'es':
        return '🇪🇸';
      case 'en':
      default:
        return '🇺🇸';
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).size.width > 700 ? 80.0 : 20.0;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 26, padding, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: AppLogo(width: 96, height: 96)),
              const SizedBox(height: 12),
              Text('Criar conta', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Preencha seus dados para começar', style: TextStyle(color: Colors.grey.shade700), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                  labelText: 'Nome',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                  labelText: 'E-mail',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                  labelText: 'Telefone',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outlined, color: Colors.grey),
                  labelText: 'Senha',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(value: _acceptedTerms, onChanged: (v) => setState(() => _acceptedTerms = v ?? false)),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey.shade700),
                        children: [
                          const TextSpan(text: 'Ao criar conta você aceita os '),
                          TextSpan(
                            text: 'Termos de Uso',
                            style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()..onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsScreen())),
                          ),
                          const TextSpan(text: ' e a '),
                          TextSpan(
                            text: 'Política de Privacidade',
                            style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()..onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.zero,
                  ),
                  child: Ink(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF0FAF66), Color(0xFF00B874)]),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Criar conta', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('ou')),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              GoogleSignInButton(onPressed: _loading ? null : _signInWithGoogle, text: 'Continuar com Google', isLoading: _loading),
              const SizedBox(height: 12),
              _buildLanguageSelector(),
              const SizedBox(height: 18),
              Center(child: Text('Já tem conta?')),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
