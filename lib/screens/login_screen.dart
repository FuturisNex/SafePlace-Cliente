import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' show AuthCredential;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/gestures.dart';

import '../widgets/app_logo.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/link_google_account_dialog.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../models/user.dart';
import '../utils/translations.dart';
import '../services/maintenance_service.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'change_password_screen.dart';
import 'phone_required_screen.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';
import '../config.dart';

/// Flag oculta: altere aqui para compilar o app como empresa ou cliente.
/// Ex.: UserType.business para compilar a variante "empresa".
final UserType kForcedUserType = (APP_ACCOUNT_TYPE.toLowerCase() == 'business')
    ? UserType.business
    : UserType.user;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _selectedLanguage; // Idioma selecionado no login

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Verifica se o usuário tem telefone cadastrado e redireciona apropriadamente
  void _navigateAfterAuth(AuthProvider authProvider) {
    final user = authProvider.user;
    final hasPhone = user?.phone != null && user!.phone!.trim().isNotEmpty;

    if (!hasPhone) {
      // Usuário não tem telefone, redirecionar para tela obrigatória
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PhoneRequiredScreen()),
      );
    } else {
      // Usuário tem telefone, ir para home (WelcomeDialog será mostrado lá)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _showSnack(String message, {bool error = false}) async {
    final snack = SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.redAccent : Colors.green[700],
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  // Verificação central: garante que o usuário logado tenha o tipo esperado pela variante do app.
  // Se incompatível, faz signOut (Firebase) e retorna true para indicar que houve incompatibilidade.
  Future<bool> _checkAndHandleTypeMismatch(AuthProvider authProvider) async {
    final userType = authProvider.user?.type;
    if (userType != null && userType != kForcedUserType) {
      // Desloga (Firebase) para limpar sessão local.
      try {
        await firebase_auth.FirebaseAuth.instance.signOut();
      } catch (_) {}
      _showSnack(
          'Esta conta é do tipo "${userType == UserType.business ? 'business' : 'user'}" e não é compatível com esta variante do app.',
          error: true);
      return true;
    }
    return false;
  }

  Future<void> _handleLogin() async {
    // Verificar manutenção antes de fazer login
    final maintenanceStatus = await MaintenanceService.checkMaintenanceStatus();
    if (maintenanceStatus['enabled'] == true) {
      _showMaintenanceDialog(maintenanceStatus['message'] as String);
      return;
    }

    // Validação melhorada
    if (_emailController.text.trim().isEmpty) {
      _showSnack(Translations.getText(context, 'loginEnterEmail'), error: true);
      return;
    }

    if (!_emailController.text.trim().contains('@')) {
      _showSnack(Translations.getText(context, 'loginEnterValidEmail'),
          error: true);
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showSnack(Translations.getText(context, 'loginEnterPassword'),
          error: true);
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? languageCode;
    try {
      final localeProvider =
          Provider.of<LocaleProvider>(context, listen: false);
      languageCode = _selectedLanguage ?? localeProvider.locale.languageCode;
    } catch (e) {
      languageCode = _selectedLanguage ?? 'pt';
    }

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
      kForcedUserType,
      preferredLanguage: languageCode,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      // Após login, garantir que o tipo do usuário corresponda à variante do app.
      final mismatch = await _checkAndHandleTypeMismatch(authProvider);
      if (mismatch) return;

      // Verificar se precisa trocar senha (usuário empresa criado pelo admin)
      final mustChangePassword = await authProvider.checkMustChangePassword();

      if (mustChangePassword && mounted) {
        // Redirecionar para tela de troca de senha obrigatória
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChangePasswordScreen(
              onPasswordChanged: () {
                // Após trocar senha, verificar telefone
                _navigateAfterAuth(authProvider);
              },
            ),
          ),
        );
        return;
      }

      // Mostrar mensagem de sucesso com tipo de usuário
      final userType = authProvider.user?.type == UserType.business
          ? Translations.getText(context, 'business')
          : Translations.getText(context, 'user');
      _showSnack('${Translations.getText(context, 'loginAs')} $userType! ✅');

      // Verificar se tem telefone cadastrado
      _navigateAfterAuth(authProvider);
    } else {
      final errorMessage = authProvider.errorMessage ??
          Translations.getText(context, 'loginError');
      _showSnack(errorMessage, error: true);
    }
  }

  Future<void> _handleFacebookLogin() async {
    // Verificar manutenção antes de fazer login
    final maintenanceStatus = await MaintenanceService.checkMaintenanceStatus();
    if (maintenanceStatus['enabled'] == true) {
      _showMaintenanceDialog(maintenanceStatus['message'] as String);
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? languageCode;
    try {
      final localeProvider =
          Provider.of<LocaleProvider>(context, listen: false);
      languageCode = _selectedLanguage ?? localeProvider.locale.languageCode;
    } catch (e) {
      languageCode = _selectedLanguage ?? 'pt';
    }

    final success = await authProvider.loginWithFacebook(
      kForcedUserType,
      preferredLanguage: languageCode,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      // Após login, garantir que o tipo do usuário corresponda à variante do app.
      final mismatch = await _checkAndHandleTypeMismatch(authProvider);
      if (mismatch) return;

      final userType = authProvider.user?.type == UserType.business
          ? Translations.getText(context, 'business')
          : Translations.getText(context, 'user');
      _showSnack('${Translations.getText(context, 'loginAs')} $userType! ✅');

      // Verificar se tem telefone cadastrado
      _navigateAfterAuth(authProvider);
    } else {
      final errorMessage = authProvider.errorMessage ??
          Translations.getText(context, 'loginError');
      _showSnack(errorMessage, error: true);
    }
  }

  Future<void> _handleAppleLogin() async {
    // Verificar manutenção antes de fazer login
    final maintenanceStatus = await MaintenanceService.checkMaintenanceStatus();
    if (maintenanceStatus['enabled'] == true) {
      _showMaintenanceDialog(maintenanceStatus['message'] as String);
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? languageCode;
    try {
      final localeProvider =
          Provider.of<LocaleProvider>(context, listen: false);
      languageCode = _selectedLanguage ?? localeProvider.locale.languageCode;
    } catch (e) {
      languageCode = _selectedLanguage ?? 'pt';
    }

    final success = await authProvider.loginWithApple(
      kForcedUserType,
      preferredLanguage: languageCode,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      // Após login, garantir que o tipo do usuário corresponda à variante do app.
      final mismatch = await _checkAndHandleTypeMismatch(authProvider);
      if (mismatch) return;

      final userType = authProvider.user?.type == UserType.business
          ? Translations.getText(context, 'business')
          : Translations.getText(context, 'user');
      _showSnack('${Translations.getText(context, 'loginAs')} $userType! ✅');

      // Verificar se tem telefone cadastrado
      _navigateAfterAuth(authProvider);
    } else {
      final errorMessage = authProvider.errorMessage ??
          Translations.getText(context, 'loginError');
      _showSnack(errorMessage, error: true);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showSnack(Translations.getText(context, 'loginEnterValidEmailForReset'),
          error: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.sendPasswordResetEmail(email);
      if (!mounted) return;
      _showSnack(Translations.getText(context, 'passwordResetEmailSent'));
    } catch (_) {
      if (!mounted) return;
      _showSnack(Translations.getText(context, 'passwordResetEmailError'),
          error: true);
    }
  }

  Future<void> _handleGoogleLogin() async {
    // Verificar manutenção antes de fazer login
    final maintenanceStatus = await MaintenanceService.checkMaintenanceStatus();
    if (maintenanceStatus['enabled'] == true) {
      _showMaintenanceDialog(maintenanceStatus['message'] as String);
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? languageCode;
    try {
      final localeProvider =
          Provider.of<LocaleProvider>(context, listen: false);
      languageCode = _selectedLanguage ?? localeProvider.locale.languageCode;
    } catch (e) {
      languageCode = _selectedLanguage ?? 'pt';
    }

    // Usar método avançado do provider (implementado no projeto original)
    final result = await authProvider.loginWithGoogleAdvanced(kForcedUserType,
        preferredLanguage: languageCode);

    setState(() => _isLoading = false);

    if (!mounted) return;

    // Verificar se precisa vincular conta existente
    if (result['needsLinking'] == true) {
      final email = result['email'] as String?;
      final credential = result['credential'] as AuthCredential?;

      if (email != null && credential != null) {
        // Mostrar diálogo para vincular conta
        await showLinkGoogleAccountDialog(
          context: context,
          email: email,
          googleCredential: credential,
          onSuccess: () async {
            // Após vincular, verificar se precisa trocar senha
            final mustChangePassword =
                await authProvider.checkMustChangePassword();

            if (mustChangePassword && mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ChangePasswordScreen(
                    onPasswordChanged: () {
                      // Verificar telefone após trocar senha
                      _navigateAfterAuth(authProvider);
                    },
                  ),
                ),
              );
            } else if (mounted) {
              // Recarregar dados do usuário e verificar telefone
              await authProvider.reloadUser();

              // IMPORTANTE: verificar tipo após reload (caso tenha sido vinculado a uma conta existente)
              final mismatch = await _checkAndHandleTypeMismatch(authProvider);
              if (mismatch) return;

              _navigateAfterAuth(authProvider);
            }
          },
          onCancel: () {
            // Usuário cancelou, não fazer nada
          },
        );
        return;
      }
    }

    if (result['success'] == true) {
      // Após login, garantir que o tipo do usuário corresponda à variante do app.
      final mismatch = await _checkAndHandleTypeMismatch(authProvider);
      if (mismatch) return;

      // Mostrar mensagem de sucesso com tipo de usuário
      final userType = authProvider.user?.type == UserType.business
          ? Translations.getText(context, 'business')
          : Translations.getText(context, 'user');
      _showSnack(
          '${Translations.getText(context, 'googleLoginAs')} $userType! ✅');

      // Verificar se tem telefone cadastrado
      _navigateAfterAuth(authProvider);
    } else if (result['error'] != null) {
      _showSnack(result['error'] as String, error: true);
    }
  }

  void _showMaintenanceDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.build, color: Colors.orange),
            SizedBox(width: 8),
            Text('Manutenção'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // tentar novamente (se apropriado)
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final currentLang =
            _selectedLanguage ?? localeProvider.locale.languageCode;
        return PopupMenuButton<String>(
          tooltip: 'Idioma',
          onSelected: (String code) {
            setState(() {
              _selectedLanguage = code;
            });
            localeProvider.selectLanguage(code);
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'pt', child: Text('Português')),
            PopupMenuItem(value: 'en', child: Text('English')),
            PopupMenuItem(value: 'es', child: Text('Español')),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_flagForCode(currentLang),
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(currentLang.toUpperCase(),
                  style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down,
                  size: 18, color: Colors.grey),
            ],
          ),
        );
      },
    );
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
              Text(
                kForcedUserType == UserType.business
                    ? 'Login Empresa'
                    : 'Login Cliente',
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                Translations.getText(context, 'loginChooseProfile'),
                style: TextStyle(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.email_outlined, color: Colors.grey),
                  labelText: Translations.getText(context, 'email'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.lock_outlined, color: Colors.grey),
                  labelText: Translations.getText(context, 'password'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _handleForgotPassword,
                  child: Text(Translations.getText(context, 'forgotPassword')),
                ),
              ),
              const SizedBox(height: 8),
              // Botão principal com leve animação (scale)
              AnimatedScale(
                scale: _isLoading ? 0.98 : 1.0,
                duration: const Duration(milliseconds: 160),
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.zero,
                      elevation: 6,
                    ),
                    child: Ink(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0FAF66), Color(0xFF00B874)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.login, size: 20),
                                  const SizedBox(width: 8),
                                  Text(Translations.getText(context, 'doLogin'),
                                      style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(Translations.getText(context, 'or'),
                        style: TextStyle(color: Colors.grey.shade600)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 14),
              GoogleSignInButton(
                onPressed: _isLoading ? null : _handleGoogleLogin,
                isLoading: _isLoading,
                text: Translations.getText(context, 'continueWithGoogle'),
              ),
              const SizedBox(height: 12),
              if (Platform.isIOS)
                SignInWithAppleButton(
                  onPressed: () {
                    if (_isLoading) return;
                    _handleAppleLogin();
                  },
                  text: Translations.getText(context, 'continueWithApple'),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(Translations.getText(context, 'dontHaveAccount'),
                      style: TextStyle(color: Colors.grey.shade600)),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const SignUpScreen()));
                    },
                    child: Text(Translations.getText(context, 'signUp'),
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildLanguageSelector(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const TermsScreen()));
                    },
                    child: Text(Translations.getText(context, 'termsOfUse'),
                        style: const TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen()));
                    },
                    child: Text(Translations.getText(context, 'privacyPolicy'),
                        style: const TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                Translations.getText(context, 'dataProtectionMessage'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
